// lib/services/auth_service.dart

import 'dart:convert';
import 'package:blink_app/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final String merchantName;
  final String? category;
  final DateTime date;
  final double amount;
  final bool isOutflow;

  Transaction({
    required this.id,
    required this.merchantName,
    this.category,
    required this.date,
    required this.amount,
    required this.isOutflow,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'] is String
        ? double.parse(json['amount'].replaceAll('-', ''))
        : (json['amount'] as num).toDouble();
    final isOutflow = json['amount'] is String
        ? json['amount'].startsWith('-')
        : json['amount'] < 0;

    return Transaction(
      id: json['id'] as String,
      merchantName: json['merchant_name'] as String? ?? 'Unknown Merchant',
      category: json['category'] as String?,
      date: DateTime.parse(json['date'] as String),
      amount: amount.abs(),
      isOutflow: isOutflow,
    );
  }
}

enum UserStatus { newUser, noBankAccount, complete }

enum TransferSpeed {
  instant,
  normal,
}

class AuthService {
  final String _baseUrl =
      dotenv.env['BACKEND_URL'] ?? 'https://your-backend-url.com';
  final Logger _logger;
  final StorageService _storageService;

  AuthService({Logger? logger, required StorageService storageService})
      : _logger = logger ?? Logger(),
        _storageService = storageService;

  Future<Map<String, dynamic>> _makeRequest({
    required String endpoint,
    required dynamic body,
    required String method,
    bool requireAuth = false,
  }) async {
    final headers = {'Content-Type': 'application/json'};

    if (requireAuth) {
      final token = _storageService.getToken();
      if (token == null) {
        throw ApiException(message: 'User not authenticated', statusCode: 401);
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final url = Uri.parse('$_baseUrl$endpoint');
    try {
      _logger.i('Request to $endpoint: ${jsonEncode(body)}');

      late http.Response response;

      if (method.toUpperCase() == 'POST') {
        response =
            await http.post(url, headers: headers, body: jsonEncode(body));
      } else if (method.toUpperCase() == 'GET') {
        final Uri finalUrl = body is Map
            ? url.replace(
                queryParameters:
                    body.map((key, value) => MapEntry(key, value.toString())))
            : url;
        response = await http.get(finalUrl, headers: headers);
      } else if (method.toUpperCase() == 'PATCH') {
        response =
            await http.patch(url, headers: headers, body: jsonEncode(body));
      } else {
        throw UnsupportedMethodException('Unsupported HTTP method: $method');
      }

      _logger.i(
          'Response from $endpoint: ${response.statusCode} - ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw ApiException(
          message: error['error'] ?? 'Unknown error',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      _logger.e('Error in API call to $endpoint: $e');
      throw ApiException(
        message: 'Failed to connect to API: $e',
        statusCode: 500,
      );
    }
  }

  /// -------------------------
  /// User Registration & Authentication
  /// -------------------------

  Future<Map<String, dynamic>> registerInitial(String email) async {
    return _makeRequest(
      endpoint: '/api/users/register-initial',
      body: {'email': email},
      method: 'POST',
    );
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    return _makeRequest(
      endpoint: '/api/users/verify-otp',
      body: {'email': email, 'otp': otp},
      method: 'POST',
    );
  }

  Future<Map<String, dynamic>> sendOtp(String email) async {
    return _makeRequest(
      endpoint: '/api/users/resend-otp',
      body: {'email': email},
      method: 'POST',
      requireAuth: false,
    );
  }

  Future<Map<String, dynamic>> completeRegistration({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String state,
    required String zipcode,
  }) async {
    return _makeRequest(
      endpoint: '/api/users/register-complete',
      body: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'state': state,
        'zipcode': zipcode,
      },
      method: 'POST',
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _makeRequest(
      endpoint: '/api/users/login',
      body: {'email': email, 'password': password},
      method: 'POST',
    );

    if (response['success']) {
      await _storageService.setToken(response['token']);
      await _storageService.setUserId(response['userId']);
      if (response['bankAccountName'] != null) {
        await _storageService.setBankAccountName(response['bankAccountName']);
      }
      _logger.i('Login successful. Token and userId stored.');

      // Check if firstName and lastName are present in the login response
      final firstName = response['firstName'] as String?;
      final lastName = response['lastName'] as String?;
      if (firstName != null && lastName != null) {
        final fullName = '$firstName $lastName';
        await _storageService.setFullName(fullName);
        _logger.i('User full name stored: $fullName');
      } else {
        _logger.w('firstName or lastName missing in login response.');
      }

      await _fetchAndStoreUserProfile();

      // **Fetch and store bankAccountId after login**
      final bankAccounts = await getUserBankAccounts();
      if (bankAccounts.isNotEmpty) {
        // Store the first bank account's ID
        final primaryBankAccount = bankAccounts.first;
        await _storageService
            .setBankAccountId(primaryBankAccount['bankAccountId']);
        _logger.i(
            'Bank account ID stored: ${primaryBankAccount['bankAccountId']}');
      } else {
        _logger.w('No bank accounts found for the user.');
      }
    }

    return response;
  }

  Future<void> logout() async {
    await _storageService.clearAll();
    _logger.i('User logged out and all data cleared.');
  }

  /// -------------------------
  /// User Profile Management
  /// -------------------------

  Future<void> _fetchAndStoreUserProfile() async {
    try {
      _logger.i('Fetching user profile...');
      final response = await _makeRequest(
        endpoint: '/api/users/profile',
        body: {},
        method: 'GET',
        requireAuth: true,
      );

      if (response['success']) {
        final profile = response['data'];
        _logger.i('User profile fetched successfully');

        final firstName = profile['first_name'] as String? ?? '';
        final lastName = profile['last_name'] as String? ?? '';

        await _storageService.setFirstName(firstName);
        await _storageService.setLastName(lastName);

        if (profile['bank_account_name'] != null) {
          await _storageService
              .setBankAccountName(profile['bank_account_name']);
          _logger
              .i('Bank account name stored: ${profile['bank_account_name']}');
        } else {
          _logger.w('Bank account name not present in user profile');
        }
        _logger.i('First name and last name stored');

        // Update fullName based on fetched firstName and lastName
        final fullName = '$firstName $lastName';
        await _storageService.setFullName(fullName);
        _logger.i('User full name updated: $fullName');

        // Note: bank_account_id is not present in this response
        _logger.w('bank_account_id not found in user profile');
      } else {
        _logger.e('Failed to fetch user profile: ${response['error']}');
      }
    } catch (e) {
      _logger.e('Error fetching user profile: $e');
    }
  }

  /// -------------------------
  /// User Status & Bank Accounts
  /// -------------------------

  Future<UserStatus> getUserStatus() async {
    final userId = _storageService.getUserId();
    if (userId == null) {
      throw Exception('User ID not found. Please log in again.');
    }

    final response = await _makeRequest(
      endpoint: '/api/users/status/$userId',
      body: {},
      method: 'GET',
      requireAuth: true,
    );

    if (response['hasBankAccount'] == true) {
      return UserStatus.complete;
    } else if (response['isNewUser'] == true) {
      return UserStatus.newUser;
    } else {
      return UserStatus.noBankAccount;
    }
  }

  Future<List<Map<String, dynamic>>> getUserBankAccounts() async {
    try {
      _logger.i('Fetching user bank accounts...');
      final response = await _makeRequest(
        endpoint: '/api/users/bank-accounts/detailed',
        body: {},
        method: 'GET',
        requireAuth: true,
      );

      if (response['success']) {
        _logger.i('Bank accounts fetched successfully');
        _logger.i('Bank accounts data: ${response['bankAccounts']}');
        return List<Map<String, dynamic>>.from(response['bankAccounts']);
      } else {
        _logger.e('Failed to fetch bank accounts: ${response['error']}');
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching bank accounts: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDetailedBankAccounts() async {
    try {
      _logger.i('Fetching detailed user bank accounts...');
      final response = await _makeRequest(
        endpoint: '/api/users/bank-accounts/detailed',
        body: {},
        method: 'GET',
        requireAuth: true,
      );

      if (response['success']) {
        _logger.i('Detailed bank accounts fetched successfully');
        _logger.i('Detailed Bank Accounts: ${response['bankAccounts']}');
        return List<Map<String, dynamic>>.from(
            response['bankAccounts'].map((account) {
          return {
            ...account,
            'accountName': account['accountName'],
          };
        }));
      } else {
        _logger
            .e('Failed to fetch detailed bank accounts: ${response['error']}');
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching detailed bank accounts: $e');
      return [];
    }
  }

  Future<String?> getPrimaryAccountName(String userId) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/users/bank-accounts/detailed',
        body: {},
        method: 'GET',
        requireAuth: true,
      );

      if (response['success'] &&
          response['bankAccounts'] is List &&
          response['bankAccounts'].isNotEmpty) {
        // Assuming the first account is the primary account
        final primaryAccount = response['bankAccounts'].first;
        return primaryAccount['accountName'];
      } else {
        _logger.w('Primary account name not found');
        return null;
      }
    } catch (e) {
      _logger.e('Error fetching primary account name: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getAllTransactions() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/transactions/all',
        body: {},
        method: 'GET',
        requireAuth: true,
      );

      if (response['success'] == true && response['transactions'] is List) {
        final transactions = (response['transactions'] as List)
            .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
            .toList();

        return {
          'success': true,
          'transactions': transactions,
        };
      } else {
        throw Exception(
            'Failed to fetch transactions: Unexpected response format');
      }
    } catch (e) {
      _logger.e('Error fetching transactions: $e');
      return {
        'success': false,
        'error': 'Failed to fetch transactions. Please try again.',
      };
    }
  }

  /// -------------------------
  /// BlinkAdvance Endpoints
  /// -------------------------

  Future<Map<String, dynamic>> createBlinkAdvance({
    required String userId,
    required double requestedAmount,
    required TransferSpeed transferSpeed,
    required DateTime repayDate,
    required String bankAccountId,
  }) async {
    return _makeRequest(
      endpoint: '/api/blink-advances',
      body: {
        'userId': userId,
        'requestedAmount': requestedAmount,
        'transferSpeed':
            transferSpeed == TransferSpeed.instant ? 'Instant' : 'Normal',
        'repayDate': DateFormat('yyyy-MM-dd').format(repayDate),
        'bankAccountId': bankAccountId,
      },
      method: 'POST',
      requireAuth: true,
    );
  }

  Future<List<Map<String, dynamic>>> getBlinkAdvances(String userId) async {
    final response = await _makeRequest(
      endpoint: '/api/blink-advances',
      body: {'userId': userId},
      method: 'GET',
      requireAuth: true,
    );
    return List<Map<String, dynamic>>.from(response['blinkAdvances']);
  }

  Future<Map<String, dynamic>> getBlinkAdvanceById(String id) async {
    return _makeRequest(
      endpoint: '/api/blink-advances/$id',
      body: {},
      method: 'GET',
      requireAuth: true,
    );
  }

  Future<Map<String, dynamic>> updateBlinkAdvanceStatus(
      String id, String status) async {
    return _makeRequest(
      endpoint: '/api/blink-advances/$id/status',
      body: {'status': status},
      method: 'PATCH',
      requireAuth: true,
    );
  }

  /// -------------------------
  /// Plaid Integration
  /// -------------------------

  Future<String> createLinkToken(String userId) async {
    final response = await _makeRequest(
      endpoint: '/api/plaid/create_link_token',
      body: {'userId': userId},
      method: 'POST',
      requireAuth: true,
    );

    if (response.containsKey('link_token')) {
      return response['link_token'];
    } else {
      throw ApiException(message: 'Link token not found', statusCode: 500);
    }
  }

  Future<Map<String, dynamic>> exchangePublicToken(
      String publicToken, String userId) async {
    return _makeRequest(
      endpoint: '/api/plaid/exchange_public_token',
      body: {'publicToken': publicToken, 'userId': userId},
      method: 'POST',
      requireAuth: true,
    );
  }

  Future<Map<String, dynamic>> syncTransactions(String userId) async {
    return _makeRequest(
      endpoint: '/api/plaid/sync',
      body: {'userId': userId},
      method: 'POST',
      requireAuth: true,
    );
  }

  Future<Map<String, dynamic>> getTransactions({
    required String userId,
    String bankAccountId = 'all',
    required String startDate,
    required String endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final Map<String, dynamic> body = {
      'userId': userId,
      'startDate': startDate,
      'endDate': endDate,
      'page': page,
      'limit': limit,
    };

    if (bankAccountId != 'all') {
      body['bankAccountId'] = bankAccountId;
    }

    return _makeRequest(
      endpoint: '/api/plaid/get_transactions',
      body: body,
      method: 'POST',
      requireAuth: true,
    );
  }

  Future<Map<String, dynamic>> syncBalances(String userId) async {
    return _makeRequest(
      endpoint: '/api/plaid/sync_balances',
      body: {'userId': userId},
      method: 'POST',
      requireAuth: true,
    );
  }

  Future<List<Transaction>> getRecentTransactions(String userId) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/plaid/recent-transactions/$userId',
        body: {},
        method: 'GET',
        requireAuth: true,
      );

      if (response['success'] == true && response['transactions'] is List) {
        return (response['transactions'] as List)
            .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _logger.e('Unexpected response format: $response');
        throw Exception(
            'Failed to fetch recent transactions: Unexpected response format');
      }
    } catch (e) {
      _logger.e('Error fetching recent transactions', error: e);
      throw Exception('Failed to fetch recent transactions: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getCurrentBalances() async {
    return _makeRequest(
      endpoint: '/api/plaid/current-balances',
      body: {},
      method: 'GET',
      requireAuth: true,
    );
  }

  /// -------------------------
  /// Initialization
  /// -------------------------

  Future<void> init() async {
    _logger.i('AuthService initialized.');
  }
}

/// -------------------------
/// Exception Classes
/// -------------------------

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';
}

class UnsupportedMethodException implements Exception {
  final String message;
  UnsupportedMethodException(this.message);

  @override
  String toString() => 'UnsupportedMethodException: $message';
}

class UserAlreadyExistsException implements Exception {
  final String message;
  UserAlreadyExistsException(this.message);

  @override
  String toString() => 'UserAlreadyExistsException: $message';
}

class InvalidOtpException implements Exception {
  final String message;
  InvalidOtpException(this.message);

  @override
  String toString() => 'InvalidOtpException: $message';
}
