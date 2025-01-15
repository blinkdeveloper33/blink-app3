import 'dart:convert';
import 'package:blink_app/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Transaction {
  final String id;
  final String merchantName;
  String? category;
  final double amount;
  final DateTime date;
  final bool isOutflow;

  Transaction({
    required this.id,
    required this.merchantName,
    this.category,
    required this.amount,
    required this.date,
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
      date: DateTime.parse(json['date']),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      transactionCount: (json['transactionCount'] as num).toInt(),
    );
  }
}

enum UserStatus { newUser, noBankAccount, complete }

enum TransferSpeed {
  instant,
  standard,
}

class AuthService {
  final String _baseUrl =
      dotenv.env['BACKEND_URL'] ?? 'https://1f33-12-162-124-34.ngrok-free.app';
  final Logger _logger = Logger();
  final StorageService _storageService;
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _currentUser;
  final http.Client _client = http.Client();

  AuthService(this._storageService);

  User? get currentUser => _currentUser;

  Future<void> init() async {
    try {
      _currentUser = _supabase.auth.currentUser;
      _supabase.auth.onAuthStateChange.listen((data) {
        _currentUser = data.session?.user;
      });
    } catch (e) {
      _logger.e('Error initializing auth service', error: e);
    }
  }

  Future<Map<String, dynamic>> _makeRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    try {
      final baseUrl = dotenv.env['API_URL'] ??
          dotenv.env['BACKEND_URL'] ??
          'https://1f33-12-162-124-34.ngrok-free.app';

      // Handle query parameters for GET requests
      var uri = Uri.parse('$baseUrl$endpoint');
      if (method == 'GET' && body != null && body.isNotEmpty) {
        uri = uri.replace(
            queryParameters:
                body.map((key, value) => MapEntry(key, value.toString())));
      }

      final headers = {
        'Content-Type': 'application/json',
      };

      if (requireAuth) {
        final token = await _storageService.getToken();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      _logger.i('Making request to: $uri');
      _logger.i('Method: $method');
      _logger.i('Headers: $headers');
      if (body != null) _logger.i('Body: $body');

      http.Response response;
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers);
          break;
        default:
          throw UnsupportedMethodException('Method $method not supported');
      }

      _logger.i('Response status code: ${response.statusCode}');
      _logger.i('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw ApiException(
          message: response.body,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      _logger.e('Error in _makeRequest:', error: e);
      rethrow;
    }
  }

  // User Registration & Authentication methods

  Future<Map<String, dynamic>> registerInitial(String email) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/users/register-initial',
        body: {'email': email},
        method: 'POST',
        requireAuth: false,
      );

      _logger.i('Initial registration response: $response');
      return response;
    } catch (e) {
      _logger.e('Error in registerInitial:', error: e);
      if (e is ApiException && e.statusCode == 400) {
        return {
          'success': false,
          'error': 'User already exists with this email.'
        };
      }
      return {
        'success': false,
        'error': 'Failed to initiate registration: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/users/verify-otp',
        body: {'email': email, 'otp': otp},
        method: 'POST',
        requireAuth: false,
      );

      _logger.i('OTP verification response: $response');
      return response;
    } catch (e) {
      _logger.e('Error in verifyOtp:', error: e);
      if (e is ApiException && e.statusCode == 400) {
        return {'success': false, 'error': 'Invalid OTP or OTP has expired.'};
      }
      return {
        'success': false,
        'error': 'Failed to verify OTP: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await _makeRequest(
        endpoint: '/resend-otp',
        body: {'email': email},
        method: 'POST',
        requireAuth: false,
      );

      _logger.i('Resend OTP response: $response');
      return response;
    } catch (e) {
      _logger.e('Error in sendOtp:', error: e);
      return {'success': false, 'error': 'Failed to send OTP: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/users/login',
        body: {'email': email, 'password': password},
        method: 'POST',
      );

      _logger.i('Login response: $response');

      if (response['success'] == true && response['token'] != null) {
        await _storageService.setToken(response['token']);
        final userId = response['userId'];
        if (userId != null) {
          await _storageService.setUserId(userId);

          // Fetch and store user profile
          final userProfile = await fetchUserProfile();
          if (userProfile['success'] == true) {
            await _storeUserProfile(userProfile['data']);
          } else {
            _logger
                .w('Failed to fetch user profile: ${userProfile['message']}');
            throw Exception('Failed to fetch user profile');
          }
        } else {
          _logger.e('User ID is missing in the login response.');
          throw Exception('User ID missing in login response.');
        }

        return {'success': true, 'message': 'Login successful'};
      } else {
        _logger.w('Login failed: ${response['message']}');
        return {
          'success': false,
          'message': response['message'] ?? 'Login failed'
        };
      }
    } catch (e) {
      _logger.e('Error during login', error: e);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
    _logger.i('User logged out and all data cleared.');
  }

  // User Profile Management methods

  Future<void> _storeUserProfile(Map<String, dynamic> userProfile) async {
    await _storageService.setFirstName(userProfile['first_name'] ?? '');
    await _storageService.setLastName(userProfile['last_name'] ?? '');
    await _storageService.setEmail(userProfile['email'] ?? '');
    await _storageService.setState(userProfile['state'] ?? '');
    await _storageService.setZipcode(userProfile['zipcode'] ?? '');

    final fullName =
        '${userProfile['first_name'] ?? ''} ${userProfile['last_name'] ?? ''}'
            .trim();
    await _storageService.setFullName(fullName);

    if (userProfile['bank_account_name'] != null) {
      await _storageService
          .setBankAccountName(userProfile['bank_account_name']);
    }

    _logger.i('User profile stored successfully');
  }

  // User Status & Bank Accounts methods

  Future<UserStatus> getUserStatus() async {
    final userId = _storageService.getUserId();
    if (userId == null || userId.isEmpty) {
      _logger.w('User ID not found or empty. Returning newUser status.');
      return UserStatus.newUser;
    }

    try {
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
    } catch (e) {
      _logger.e('Error getting user status', error: e);
      return UserStatus.newUser;
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

  Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/users/profile',
        body: {},
        method: 'GET',
        requireAuth: true,
      );

      if (response['success'] == true) {
        return {'success': true, 'data': response['data']};
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to fetch user profile'
        };
      }
    } catch (e) {
      _logger.e('Error fetching user profile', error: e);
      return {'success': false, 'message': 'Error fetching user profile: $e'};
    }
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

  Future<Map<String, dynamic>> getDailyTransactionSummary() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/plaid/daily-transaction-summary',
        body: {},
        method: 'GET',
        requireAuth: true,
      );

      if (response['success'] == true) {
        return response;
      } else {
        _logger.e('Unexpected response format: $response');
        throw ApiException(
            message: 'Failed to fetch daily transaction summary',
            statusCode: 500);
      }
    } catch (e) {
      _logger.e('Error fetching daily transaction summary', error: e);
      throw ApiException(
          message: 'Failed to fetch daily transaction summary: ${e.toString()}',
          statusCode: 500);
    }
  }

  // New Method for Category Analysis
  Future<Map<String, dynamic>> getCategoryAnalysis(String timeFrame) async {
    return _makeRequest(
      endpoint: '/api/plaid/category-analysis',
      body: {'timeFrame': timeFrame},
      method: 'GET',
      requireAuth: true,
    );
  }

  // New Method for Cash Flow Analysis
  Future<Map<String, dynamic>> getCashFlowAnalysis(String timeFrame) async {
    return _makeRequest(
      endpoint: '/api/cash-flow/analysis',
      body: {'timeFrame': timeFrame},
      method: 'GET',
      requireAuth: true,
    );
  }

  Future<TransactionDetail> getTransactionDetails(String transactionId) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/transactions/$transactionId',
        body: {},
        method: 'GET',
        requireAuth: true,
      );
      if (response['success'] == true) {
        return TransactionDetail.fromJson(response['data']);
      } else {
        throw ApiException(
            message: response['error'] ?? 'Failed to fetch transaction details',
            statusCode: 400);
      }
    } catch (e) {
      _logger.e('Error fetching transaction details: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfilePicture(
      String userId, String pictureUrl) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/users/profile-picture',
        body: {
          'userId': userId,
          'profilePictureUrl': pictureUrl,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        method: 'PUT',
        requireAuth: true,
      );

      if (response['success'] == true) {
        _logger.i('Profile picture URL updated successfully');
        return {'success': true};
      } else {
        _logger
            .e('Failed to update profile picture URL: ${response['message']}');
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to update profile picture'
        };
      }
    } catch (e) {
      _logger.e('Error updating profile picture URL', error: e);
      return {
        'success': false,
        'message': 'Error updating profile picture: $e'
      };
    }
  }

  Future<Map<String, dynamic>> getSpendingAnalysis(String timeFrame) async {
    try {
      _logger.i('Making spending analysis request for timeFrame: $timeFrame');

      final response = await _makeRequest(
        endpoint: '/api/plaid/spending-analysis',
        body: {'timeFrame': timeFrame},
        method: 'GET',
        requireAuth: true,
      );

      _logger.d('Raw spending analysis response: $response');

      if (response['success'] == true) {
        if (response['data'] == null) {
          _logger.w('Spending analysis response missing data field');
          throw ApiException(
              message: 'Invalid response format: missing data field',
              statusCode: 500);
        }

        final data = response['data'] as Map<String, dynamic>;
        final responseTimeFrame = data['timeFrame'] as String;

        // Verify if the response timeFrame matches the requested timeFrame
        if (responseTimeFrame != timeFrame) {
          _logger.e(
              'Server returned mismatched timeFrame. Requested: $timeFrame, Received: $responseTimeFrame');
          throw ApiException(
            message: 'Server returned incorrect time frame data',
            statusCode: 500,
          );
        }

        _logger.i('Successfully fetched spending analysis data');
        _logger.d(
            'Categories count: ${(data['categories'] as List?)?.length ?? 0}');
        _logger.d('Total spending: ${data['totalSpending']}');

        return response;
      } else {
        final errorMsg =
            response['error'] ?? 'Failed to fetch spending analysis';
        _logger.e('Spending analysis request failed: $errorMsg');
        throw ApiException(message: errorMsg, statusCode: 500);
      }
    } catch (e) {
      _logger.e('Error fetching spending analysis', error: e);
      throw ApiException(
          message: 'Failed to fetch spending analysis: ${e.toString()}',
          statusCode: 500);
    }
  }

  Future<Map<String, dynamic>> getHistoricalSpending() async {
    try {
      _logger.i('Fetching historical spending data');

      final response = await _makeRequest(
        endpoint: '/api/plaid/historical-spending',
        body: {},
        method: 'GET',
        requireAuth: true,
      );

      _logger.d('Raw historical spending response: $response');

      if (response['success'] == true) {
        if (response['data'] == null || response['data']['periods'] == null) {
          _logger
              .w('Historical spending response missing data or periods field');
          throw ApiException(
              message: 'Invalid response format: missing required fields',
              statusCode: 500);
        }

        final data = response['data'] as Map<String, dynamic>;
        final periods = data['periods'] as Map<String, dynamic>;

        // Validate the periods data
        _validateHistoricalSpendingData(periods);

        _logger.i('Successfully fetched historical spending data');
        return response;
      } else {
        final errorMsg =
            response['error'] ?? 'Failed to fetch historical spending';
        _logger.e('Historical spending request failed: $errorMsg');
        throw ApiException(message: errorMsg, statusCode: 500);
      }
    } catch (e) {
      _logger.e('Error fetching historical spending: $e');
      throw ApiException(
          message: 'Failed to fetch historical spending: ${e.toString()}',
          statusCode: 500);
    }
  }

  void _validateHistoricalSpendingData(Map<String, dynamic> periods) {
    final requiredPeriods = [
      'lastWeek',
      'lastMonth',
      'lastQuarter',
      'lastYear'
    ];

    for (final period in requiredPeriods) {
      if (!periods.containsKey(period)) {
        _logger.w('Missing $period period in response');
        continue;
      }

      final periodData = periods[period] as Map<String, dynamic>?;
      if (periodData == null) {
        _logger.w('Invalid $period period data format');
        continue;
      }

      if (periodData['start'] == null || periodData['end'] == null) {
        _logger.w('Missing date range for $period period');
      }

      if (periodData['totalSpending'] == null) {
        _logger.w('Missing totalSpending for $period period');
      }
    }
  }

  Future<Map<String, dynamic>> registerCompleteWithLogin({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String state,
    required String zipcode,
  }) async {
    try {
      _logger.i('Starting registration completion...');
      final response = await _makeRequest(
        endpoint: '/api/users/register-complete-with-login',
        body: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'state': state,
          'zipcode': zipcode,
        },
        method: 'POST',
        requireAuth: false,
      );

      _logger.i('Registration completion response: $response');

      if (response['success'] == true && response['token'] != null) {
        await _storageService.setToken(response['token']);
        final userId = response['userId'];
        if (userId != null) {
          await _storageService.setUserId(userId);

          // Store user profile data
          await _storageService.setFirstName(firstName);
          await _storageService.setLastName(lastName);
          await _storageService.setState(state);
          await _storageService.setZipcode(zipcode);
          await _storageService.setEmail(email);

          // Set full name
          final fullName = '$firstName $lastName'.trim();
          await _storageService.setFullName(fullName);

          _logger.i('User registration and login successful');
          return {
            'success': true,
            'token': response['token'],
            'userId': userId,
            'message': 'Registration successful'
          };
        }
      }

      return {
        'success': false,
        'error': response['error'] ?? 'Registration failed'
      };
    } catch (e) {
      _logger.e('Error in registerCompleteWithLogin:', error: e);
      if (e is ApiException) {
        if (e.statusCode == 400) {
          return {
            'success': false,
            'error': 'Invalid registration data or email not verified.'
          };
        }
      }
      return {
        'success': false,
        'error': 'Failed to complete registration: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> getRecurringExpenses(String timeFrame) async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/api/plaid/recurring-expenses',
        body: {'timeFrame': timeFrame},
      );

      if (response['success'] == true) {
        return response['data'];
      } else {
        throw Exception(
            response['message'] ?? 'Failed to fetch recurring expenses');
      }
    } catch (e) {
      _logger.e('Error fetching recurring expenses: $e');
      rethrow;
    }
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

class TransactionDetail {
  final String id;
  final String? merchantName;
  final double amount;
  final DateTime date;
  final String? category;
  final Map<String, dynamic>? metadata;

  TransactionDetail({
    required this.id,
    this.merchantName,
    required this.amount,
    required this.date,
    this.category,
    this.metadata,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    return TransactionDetail(
      id: json['id'] as String,
      merchantName: json['merchantName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
