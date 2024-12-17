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

class DailyTransactionSummary {
  final DateTime date;
  final double totalAmount;
  final int transactionCount;

  DailyTransactionSummary({
    required this.date,
    required this.totalAmount,
    required this.transactionCount,
  });

  factory DailyTransactionSummary.fromJson(Map<String, dynamic> json) {
    return DailyTransactionSummary(
      date: DateTime.parse(json['date'] as String),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      transactionCount: json['transactionCount'] as int,
    );
  }
}

enum UserStatus { newUser, noBankAccount, complete }

enum TransferSpeed {
  instant,
  normal,
}

class AuthService {
  final String _baseUrl = dotenv.env['BACKEND_URL'] ??
      'https://5000-idx-blinkbackend2-1731939610309.cluster-fnjdffmttjhy2qqdugh3yehhs2.cloudworkstations.dev';
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
      } else if (method.toUpperCase() == 'DELETE') {
        response = await http.delete(url, headers: headers);
      } else {
        throw UnsupportedMethodException('Unsupported HTTP method: $method');
      }

      _logger.i(
          'Response from $endpoint: ${response.statusCode} - ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        } else {
          throw ApiException(
              message: 'Unexpected response format',
              statusCode: response.statusCode);
        }
      } else {
        final error = jsonDecode(response.body);
        if (error is Map<String, dynamic>) {
          throw ApiException(
            message: error['error'] ?? 'Unknown error',
            statusCode: response.statusCode,
          );
        } else {
          throw ApiException(
              message: 'Unexpected error format',
              statusCode: response.statusCode);
        }
      }
    } catch (e) {
      _logger.e('Error in API call to $endpoint: $e');
      throw ApiException(
        message: 'Failed to connect to API: $e',
        statusCode: 500,
      );
    }
  }

  // User Registration & Authentication methods

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

      final bankAccounts = await getLinkedAccounts();
      if (bankAccounts.isNotEmpty) {
        final primaryBankAccount = bankAccounts.first;
        await _storageService
            .setBankAccountId(primaryBankAccount['bankAccountId'] as String);
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

  // User Profile Management methods

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
        final profile = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : Map<String, dynamic>.from(response['data'] as Map);
        _logger.i('User profile fetched successfully');

        final firstName = profile['first_name'] as String? ?? '';
        final lastName = profile['last_name'] as String? ?? '';

        await _storageService.setFirstName(firstName);
        await _storageService.setLastName(lastName);

        if (profile['bank_account_name'] != null) {
          await _storageService
              .setBankAccountName(profile['bank_account_name'] as String);
          _logger
              .i('Bank account name stored: ${profile['bank_account_name']}');
        } else {
          _logger.w('Bank account name not present in user profile');
        }
        _logger.i('First name and last name stored');

        final fullName = '$firstName $lastName';
        await _storageService.setFullName(fullName);
        _logger.i('User full name updated: $fullName');

        _logger.w('bank_account_id not found in user profile');
      } else {
        _logger.e('Failed to fetch user profile: ${response['error']}');
      }
    } catch (e) {
      _logger.e('Error fetching user profile: $e');
    }
  }

  // User Status & Bank Accounts methods

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

  Future<List<Map<String, dynamic>>> getLinkedAccounts() async {
    try {
      _logger.i('Fetching user linked accounts...');
      final response = await _makeRequest(
        endpoint: '/api/users/bank-accounts/detailed',
        body: {},
        method: 'GET',
        requireAuth: true,
      );

      if (response['success']) {
        _logger.i('Linked accounts fetched successfully');
        _logger.i('Linked accounts data: ${response['bankAccounts']}');
        return List<Map<String, dynamic>>.from(
            (response['bankAccounts'] as List).map((account) {
          if (account is Map<String, dynamic>) {
            return account;
          } else if (account is Map) {
            return Map<String, dynamic>.from(account);
          } else {
            throw ApiException(
                message: 'Invalid bank account format', statusCode: 500);
          }
        }));
      } else {
        _logger.e('Failed to fetch linked accounts: ${response['error']}');
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching linked accounts: $e');
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
            (response['bankAccounts'] as List).map((account) {
          if (account is Map<String, dynamic>) {
            return account;
          } else if (account is Map) {
            return Map<String, dynamic>.from(account);
          } else {
            throw ApiException(
                message: 'Invalid detailed bank account format',
                statusCode: 500);
          }
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
          (response['bankAccounts'] as List).isNotEmpty) {
        final primaryAccount = response['bankAccounts'].first;
        if (primaryAccount is Map<String, dynamic>) {
          return primaryAccount['accountName'] as String?;
        } else if (primaryAccount is Map) {
          final accountMap = Map<String, dynamic>.from(primaryAccount);
          return accountMap['accountName'] as String?;
        } else {
          _logger.w('Primary account name not found due to invalid format');
          return null;
        }
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
            .map((json) => Transaction.fromJson(json is Map<String, dynamic>
                ? json
                : Map<String, dynamic>.from(json as Map)))
            .toList();

        return {
          'success': true,
          'transactions': transactions,
        };
      } else {
        throw ApiException(
            message: 'Failed to fetch transactions: Unexpected response format',
            statusCode: 500);
      }
    } catch (e) {
      _logger.e('Error fetching transactions: $e');
      return {
        'success': false,
        'error': 'Failed to fetch transactions. Please try again.',
      };
    }
  }

  // BlinkAdvance Endpoints

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
    if (response['blinkAdvances'] is List) {
      return List<Map<String, dynamic>>.from(
          (response['blinkAdvances'] as List).map((advance) {
        if (advance is Map<String, dynamic>) {
          return advance;
        } else if (advance is Map) {
          return Map<String, dynamic>.from(advance);
        } else {
          throw ApiException(
              message: 'Invalid BlinkAdvance format', statusCode: 500);
        }
      }));
    } else {
      throw ApiException(
          message: 'Invalid BlinkAdvances data format', statusCode: 500);
    }
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

  Future<Map<String, dynamic>> getBlinkAdvanceApprovalStatus() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/blink-advances/approval-status',
        body: {},
        method: 'GET',
        requireAuth: true,
      );

      if (response['success'] == true && response['data'] != null) {
        return {
          'isApproved': response['data']['isApproved'] as bool,
          'approvedAt': response['data']['approvedAt'] != null
              ? DateTime.parse(response['data']['approvedAt'] as String)
              : null,
          'status': response['data']['status'] as String,
        };
      } else {
        throw ApiException(
          message: 'Failed to get Blink Advance approval status',
          statusCode: 500,
        );
      }
    } catch (e) {
      _logger.e('Error getting Blink Advance approval status: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getActiveBlinkAdvance() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/blink-advances/active',
        body: {},
        method: 'GET',
        requireAuth: true,
      );

      if (response['success'] == true) {
        return {
          'hasActiveAdvance': response['data']['hasActiveAdvance'] as bool,
          'activeAdvance': response['data']['activeAdvance'] != null
              ? Map<String, dynamic>.from(response['data']['activeAdvance'])
              : null,
        };
      } else {
        throw ApiException(
          message: 'Failed to get active Blink Advance status',
          statusCode: 500,
        );
      }
    } catch (e) {
      _logger.e('Error getting active Blink Advance status: $e');
      rethrow;
    }
  }

  // Plaid Integration

  Future<String> createLinkToken(String userId) async {
    final response = await _makeRequest(
      endpoint: '/api/plaid/create_link_token',
      body: {'userId': userId},
      method: 'POST',
      requireAuth: true,
    );

    if (response.containsKey('link_token')) {
      return response['link_token'] as String;
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
            .map((json) => Transaction.fromJson(json is Map<String, dynamic>
                ? json
                : Map<String, dynamic>.from(json as Map)))
            .toList();
      } else {
        _logger.e('Unexpected response format: $response');
        throw ApiException(
            message:
                'Failed to fetch recent transactions: Unexpected response format',
            statusCode: 500);
      }
    } catch (e) {
      _logger.e('Error fetching recent transactions', error: e);
      throw ApiException(
          message: 'Failed to fetch recent transactions: ${e.toString()}',
          statusCode: 500);
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

  // User Profile Management

  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> updatedInfo) async {
    return _makeRequest(
      endpoint: '/api/users/update-profile',
      body: updatedInfo,
      method: 'PATCH',
      requireAuth: true,
    );
  }

  // Linked Account Management

  Future<Map<String, dynamic>> addLinkedAccount(String accountInfo) async {
    return _makeRequest(
      endpoint: '/api/users/add-account',
      body: {'accountInfo': accountInfo},
      method: 'POST',
      requireAuth: true,
    );
  }

  Future<Map<String, dynamic>> removeLinkedAccount(String accountId) async {
    return _makeRequest(
      endpoint: '/api/users/remove-account/$accountId',
      body: {},
      method: 'DELETE',
      requireAuth: true,
    );
  }

  // Account Statistics

  Future<Map<String, dynamic>> getDetailedAccountStatistics() async {
    return _makeRequest(
      endpoint: '/api/users/account-statistics',
      body: {},
      method: 'GET',
      requireAuth: true,
    );
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    return _makeRequest(
      endpoint: '/api/users/profile',
      body: {},
      method: 'GET',
      requireAuth: true,
    );
  }

  Future<Map<String, dynamic>> getAllTransactionsPaginated(
      {int page = 1, int pageSize = 100}) async {
    return _makeRequest(
      endpoint: '/api/plaid/all-transactions',
      body: {'page': page, 'pageSize': pageSize},
      method: 'GET',
      requireAuth: true,
    );
  }

  Future<Map<String, dynamic>> handlePlaidWebhook(
      Map<String, dynamic> webhookData) async {
    return _makeRequest(
      endpoint: '/api/plaid/webhook',
      body: webhookData,
      method: 'POST',
      requireAuth: false,
    );
  }

  Future<Map<String, dynamic>> getAccountData() async {
    return _makeRequest(
      endpoint: '/api/users/account-data',
      body: {},
      method: 'GET',
      requireAuth: true,
    );
  }

  // Daily Transaction Summary

  Future<List<DailyTransactionSummary>> getDailyTransactionSummary() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/plaid/daily-transaction-summary',
        body: {},
        method: 'GET',
        requireAuth: true,
      );

      if (response['success'] == true && response['data'] is List) {
        return (response['data'] as List)
            .map((json) => DailyTransactionSummary.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : Map<String, dynamic>.from(json as Map)))
            .toList();
      } else {
        _logger.e('Unexpected response format: $response');
        throw ApiException(
            message:
                'Failed to fetch daily transaction summary: Unexpected response format',
            statusCode: 500);
      }
    } catch (e) {
      _logger.e('Error fetching daily transaction summary', error: e);
      throw ApiException(
          message: 'Failed to fetch daily transaction summary: ${e.toString()}',
          statusCode: 500);
    }
  }

  // Initialization

  Future<void> init() async {
    _logger.i('AuthService initialized.');
  }
}

// Exception Classes

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
