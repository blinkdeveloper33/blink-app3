import 'dart:convert';
import 'package:blink_app/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blink_app/config/api_config.dart';

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String state;
  final String zipCode;
  final bool isEmailVerified;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.state,
    required this.zipCode,
    required this.isEmailVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      isEmailVerified: json['isEmailVerified'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'state': state,
      'zipCode': zipCode,
      'isEmailVerified': isEmailVerified,
    };
  }
}

class Transaction {
  final String id;
  final String merchantName;
  String? category;
  final double amount;
  final DateTime date;
  final bool isOutflow;
  final String transactionId;

  Transaction({
    required this.id,
    required this.merchantName,
    this.category,
    required this.amount,
    required this.date,
    required this.isOutflow,
    required this.transactionId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'] is String
        ? double.parse(json['amount'].replaceAll('-', ''))
        : (json['amount'] as num).toDouble();
    final isOutflow = json['amount'] is String
        ? json['amount'].startsWith('-')
        : json['amount'] < 0;

    // Handle category which can be a String or a List<dynamic>
    String? category;
    if (json['category'] is String) {
      category = json['category'] as String?;
    } else if (json['category'] is List &&
        (json['category'] as List).isNotEmpty) {
      // Join all categories or just use the first one
      category = (json['category'] as List).join(', ');
    }

    return Transaction(
      id: json['id'] as String,
      merchantName: json['merchant_name'] as String? ?? 'Unknown Merchant',
      category: category,
      date: DateTime.parse(json['date'] as String),
      amount: amount.abs(),
      isOutflow: isOutflow,
      transactionId: json['transaction_id'] as String,
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
  final Logger _logger = Logger();
  final StorageService _storageService;
  final http.Client _client = http.Client();

  AuthService(this._storageService);

  Future<dynamic> _makeRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      // Handle query parameters for GET requests
      if (method == 'GET' && body != null && body.isNotEmpty) {
        uri = uri.replace(
          queryParameters:
              body.map((key, value) => MapEntry(key, value.toString())),
        );
        body = null; // Clear body for GET requests
      }

      final headers = {
        'Content-Type': 'application/json',
      };

      if (requireAuth) {
        // First check if token is available
        final hasToken = await verifyTokenAvailable();
        if (!hasToken) {
          throw Exception('Authentication token required but not found');
        }

        // At this point we know _currentToken is available
        headers['Authorization'] = 'Bearer $_currentToken';
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
          throw Exception('Method $method not supported');
      }

      _logger.i('Response status code: ${response.statusCode}');
      _logger.i('Response headers: ${response.headers}');
      _logger.i('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedResponse = json.decode(response.body);
        _logger.i('Decoded response: $decodedResponse');
        return decodedResponse;
      } else {
        _logger.e(
            'API Error - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
          'API Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _logger.e('Error in _makeRequest:', error: e);
      rethrow;
    }
  }

  // Email Verification Endpoints

  Future<Map<String, dynamic>> initiateEmailVerification(String email) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/auth/email/verify/initiate',
        method: 'POST',
        body: {'email': email},
        requireAuth: false,
      );

      _logger.i('Email verification initiated for: $email');
      return response;
    } catch (e) {
      _logger.e('Error initiating email verification:', error: e);
      rethrow;
    }
  }

  // Initial registration step - verify email
  Future<Map<String, dynamic>> registerInitial(String email) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/auth/email/verify/initiate',
        method: 'POST',
        body: {'email': email},
        requireAuth: false,
      );

      _logger.i('Initial registration step completed for: $email');
      return response;
    } catch (e) {
      if (e.toString().contains('already exists')) {
        throw UserAlreadyExistsException(
            'An account with this email already exists.');
      }
      _logger.e('Error during initial registration:', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/auth/email/verify',
        method: 'POST',
        body: {
          'email': email,
          'otp': otp,
        },
        requireAuth: false,
      );

      _logger.i('OTP verification response received for email: $email');
      return response;
    } catch (e) {
      _logger.e('Error verifying OTP:', error: e);
      rethrow;
    }
  }

  // Resend OTP endpoint
  Future<Map<String, dynamic>> sendOtp(String email) async {
    return initiateEmailVerification(
        email); // Reuse the same endpoint for resending
  }

  // Complete registration with login
  Future<Map<String, dynamic>> registerCompleteWithLogin({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String state,
    required String zipCode,
    required bool agreedToTerms,
  }) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/auth/register',
        method: 'POST',
        body: {
          'email': email,
          'password': password,
          'confirmPassword': password,
          'firstName': firstName,
          'lastName': lastName,
          'state': state,
          'zipCode': zipCode,
          'agreedToTerms': agreedToTerms,
        },
        requireAuth: false,
      );

      if (response['success'] == true && response['token'] != null) {
        await _storageService.setToken(response['token']);
      }

      _logger.i('Registration completed for user: $email');
      return response;
    } catch (e) {
      _logger.e('Error during registration:', error: e);
      rethrow;
    }
  }

  // Login endpoint
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/auth/login',
        method: 'POST',
        body: {
          'email': email,
          'password': password,
        },
        requireAuth: false,
      );

      // Validate response structure
      if (response['token'] == null) {
        throw Exception('Login response missing token');
      }

      // 1. Store the token first
      await _storageService.setToken(response['token']);

      // 2. Verify token was saved correctly
      final savedToken = await _storageService.getToken();
      if (savedToken == null || savedToken.isEmpty) {
        throw Exception('Failed to save authentication token');
      }

      // 3. Set the token in memory for immediate use
      _currentToken = savedToken;

      // 4. Log success
      _logger.i('Token stored successfully: ${savedToken.substring(0, 10)}...');

      // 5. Parse and store user data if present
      if (response['user'] != null) {
        try {
          currentUser = User.fromJson(response['user'] as Map<String, dynamic>);
          _logger.i('User data stored for: ${currentUser?.email}');

          // 6. IMPORTANT: Store the user ID in local storage
          if (currentUser != null) {
            await _storageService.setUserId(currentUser!.id);
            _logger.i('User ID stored: ${currentUser!.id}');
          } else if (response['user']['id'] != null) {
            // Fallback in case User object creation failed
            await _storageService.setUserId(response['user']['id']);
            _logger.i(
                'User ID stored from raw response: ${response['user']['id']}');
          }
        } catch (e) {
          _logger.e('Error parsing user data:', error: e);
          // Still try to save the user ID directly from the response
          if (response['user']['id'] != null) {
            await _storageService.setUserId(response['user']['id']);
            _logger.i(
                'User ID stored from raw response after error: ${response['user']['id']}');
          }
        }
      }

      _logger.i('Login successful for user: $email');
      return response;
    } catch (e) {
      _logger.e('Error during login:', error: e);
      // Clear any partially stored data on error
      await _storageService.clearToken();
      _currentToken = null;
      currentUser = null;
      rethrow;
    }
  }

  // Add a method to verify token is available
  Future<bool> verifyTokenAvailable() async {
    try {
      // First check in-memory token
      if (_currentToken != null && _currentToken!.isNotEmpty) {
        return true;
      }

      // Then check storage
      final storedToken = await _storageService.getToken();
      if (storedToken != null && storedToken.isNotEmpty) {
        _currentToken = storedToken; // Update in-memory cache
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Error verifying token availability:', error: e);
      return false;
    }
  }

  // Add a field to store the current token in memory
  String? _currentToken;

  // Plaid Integration Endpoints

  Future<String> createLinkToken(String userId,
      {String? redirectUri, String? androidPackageName}) async {
    try {
      _logger.i('Creating Plaid link token for user: $userId');

      // Build request body with OAuth parameters if provided
      final Map<String, dynamic> requestBody = {
        'userId': userId,
      };

      // Add redirect URI for iOS and Web
      if (redirectUri != null && redirectUri.isNotEmpty) {
        requestBody['redirect_uri'] = redirectUri;
      }

      // Temporarily removed Android support
      // Android package name parameter is ignored

      final response = await _makeRequest(
        endpoint: '/api/plaid/create-link-token',
        method: 'POST',
        body: requestBody,
        requireAuth: true,
      );

      // Extract link_token from response
      final linkToken = response['link_token'] as String?;
      if (linkToken == null || linkToken.isEmpty) {
        throw Exception('Link token not found in response');
      }

      _logger.i(
          'Link token created successfully: ${linkToken.substring(0, 10)}...');
      return linkToken;
    } catch (e) {
      _logger.e('Error creating Plaid link token:', error: e);
      throw Exception('Failed to create Plaid link token: $e');
    }
  }

  Future<Map<String, dynamic>> exchangePublicToken(
      String publicToken, String userId) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/plaid/exchange-public-token',
        method: 'POST',
        body: {
          'public_token': publicToken,
          'metadata': {}, // Optional metadata from Plaid Link
        },
        requireAuth: true,
      );

      if (response['success'] != true || response['access_token'] == null) {
        throw Exception('Failed to exchange public token');
      }

      _logger.i('Public token exchanged successfully');
      return {
        'success': true,
        'access_token': response['access_token'],
        'item_id': response['item_id'],
      };
    } catch (e) {
      _logger.e('Error exchanging public token:', error: e);
      rethrow;
    }
  }

  Future<void> syncTransactions(String userId) async {
    try {
      await _makeRequest(
        endpoint: '/api/plaid/sync-transactions',
        method: 'POST',
        body: {'userId': userId},
        requireAuth: true,
      );
      _logger.i('Transactions synced successfully');
    } catch (e) {
      _logger.e('Error syncing transactions:', error: e);
      rethrow;
    }
  }

  Future<List<Transaction>> getTransactions({
    required String userId,
    required String bankAccountId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/plaid/transactions',
        method: 'GET',
        body: {
          'userId': userId,
          'bankAccountId': bankAccountId,
          'startDate': startDate,
          'endDate': endDate,
        },
        requireAuth: true,
      );

      if (response['transactions'] != null) {
        return (response['transactions'] as List)
            .map((json) => Transaction.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('Error getting transactions:', error: e);
      rethrow;
    }
  }

  Future<void> syncBalances(String userId) async {
    try {
      await _makeRequest(
        endpoint: '/api/plaid/sync-balances',
        method: 'POST',
        body: {'userId': userId},
        requireAuth: true,
      );
      _logger.i('Balances synced successfully');
    } catch (e) {
      _logger.e('Error syncing balances:', error: e);
      rethrow;
    }
  }

  // User Management
  User? currentUser;

  Future<void> init() async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        final response = await _makeRequest(
          endpoint: '/api/users/profile',
          method: 'GET',
          requireAuth: true,
        );
        currentUser = User.fromJson(response['user']);
      }
    } catch (e) {
      _logger.e('Error initializing auth service:', error: e);
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/users/profile',
        method: 'GET',
        requireAuth: true,
      );

      if (response != null && response['user'] != null) {
        _logger.i('User profile retrieved successfully');
        return response['user'] as Map<String, dynamic>;
      }

      _logger.w('User profile response missing user data');
      return null;
    } catch (e) {
      _logger.e('Error getting user profile:', error: e);
      return null;
    }
  }

  Future<String?> getToken() async {
    return await _storageService.getToken();
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      // Get the refresh token from the login response
      final refreshToken = await _storageService.getToken();
      if (refreshToken == null) {
        // If no refresh token, just clear storage and return success
        await _storageService.clearAll();
        return {'message': 'Logged out successfully'};
      }

      final response = await _makeRequest(
        endpoint: '/api/auth/logout',
        method: 'POST',
        body: {'refreshToken': refreshToken},
        requireAuth: true,
      );

      // Clear storage regardless of response
      await _storageService.clearAll();
      _currentToken = null;
      currentUser = null;
      return response;
    } catch (e) {
      _logger.e('Error during logout:', error: e);
      // Still clear storage on error
      await _storageService.clearAll();
      _currentToken = null;
      currentUser = null;
      rethrow;
    }
  }

  // Profile Management
  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> data) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/users/profile',
        method: 'PUT',
        body: data,
        requireAuth: true,
      );
      return response;
    } catch (e) {
      _logger.e('Error updating user profile:', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAccountData() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/users/account',
        method: 'GET',
        requireAuth: true,
      );
      return response;
    } catch (e) {
      _logger.e('Error getting account data:', error: e);
      rethrow;
    }
  }

  // Password Reset
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/auth/password/reset/request',
        method: 'POST',
        body: {'email': email},
        requireAuth: false,
      );
      return response;
    } catch (e) {
      _logger.e('Error requesting password reset:', error: e);
      rethrow;
    }
  }

  // Bank Account Management
  Future<List<Map<String, dynamic>>> getDetailedBankAccounts() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/users/bank-accounts/detailed',
        method: 'GET',
        requireAuth: true,
      );
      return List<Map<String, dynamic>>.from(response['accounts']);
    } catch (e) {
      _logger.e('Error getting detailed bank accounts:', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentBalances() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/plaid/balances',
        method: 'GET',
        requireAuth: true,
      );
      return response;
    } catch (e) {
      _logger.e('Error getting current balances:', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBankAccountBalance() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/bank-accounts/balance',
        method: 'GET',
        requireAuth: true,
      );
      _logger.i('Bank account balance fetched: ${response.toString()}');
      return response;
    } catch (e) {
      _logger.e('Error getting bank account balance:', error: e);
      rethrow;
    }
  }

  // Transaction Management
  Future<List<Transaction>> getRecentTransactions({String? userId}) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/transactions/recent',
        method: 'GET',
        body: userId != null ? {'userId': userId} : null,
        requireAuth: true,
      );
      return (response['transactions'] as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Error getting recent transactions:', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAllTransactionsPaginated({
    required int page,
    required int limit,
    String? searchQuery,
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/transactions',
        method: 'GET',
        body: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (searchQuery != null) 'search': searchQuery,
          if (category != null) 'category': category,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
        requireAuth: true,
      );
      return response;
    } catch (e) {
      _logger.e('Error getting paginated transactions:', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTransactionDetails(
      String transactionId) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/transactions/$transactionId',
        method: 'GET',
        requireAuth: true,
      );
      return response;
    } catch (e) {
      _logger.e('Error getting transaction details:', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateTransactionCategory({
    required String transactionId,
    required String category,
  }) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/transactions/$transactionId/category',
        method: 'PUT',
        body: {'category': category},
        requireAuth: true,
      );
      return response;
    } catch (e) {
      _logger.e('Error updating transaction category:', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTransactionAnalysis({String? userId}) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/transactions/analysis',
        method: 'GET',
        body: userId != null ? {'userId': userId} : null,
        requireAuth: true,
      );
      return response;
    } catch (e) {
      _logger.e('Error getting transaction analysis:', error: e);
      rethrow;
    }
  }

  Future<List<DailyTransactionSummary>> getDailyTransactionSummary(
      {int? days}) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/transactions/daily-summary',
        method: 'GET',
        body: days != null ? {'days': days.toString()} : null,
        requireAuth: true,
      );
      return (response['summaries'] as List)
          .map((json) => DailyTransactionSummary.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Error getting daily transaction summary:', error: e);
      rethrow;
    }
  }

  // Financial Analysis
  Future<Map<String, dynamic>> getCashFlowAnalysis({String? timeFrame}) async {
    try {
      // Convert the timeframe to the format expected by the API
      String apiTimeFrame;
      switch (timeFrame) {
        case 'LAST_WEEK':
          apiTimeFrame = 'week';
          break;
        case 'LAST_MONTH':
          apiTimeFrame = 'month';
          break;
        case 'LAST_QUARTER':
          apiTimeFrame = 'quarter';
          break;
        case 'LAST_YEAR':
          apiTimeFrame = 'year';
          break;
        case 'ALL':
          // API doesn't accept 'all', so default to year for broadest view
          apiTimeFrame = 'year';
          break;
        default:
          apiTimeFrame = 'month';
      }

      _logger.d('Getting cash flow analysis for timeFrame: $apiTimeFrame');

      final response = await _makeRequest(
        endpoint: '/api/asset_report/cash_flow/$apiTimeFrame',
        method: 'GET',
        requireAuth: true,
      );

      _logger.d('Cash flow API raw response: $response');

      if (response != null) {
        try {
          final formattedData = _formatNewCashFlowResponse(response);
          return {
            'success': true,
            'data': formattedData,
          };
        } catch (e) {
          _logger.e('Error getting cash flow analysis: $e');
          return {
            'success': false,
            'message': 'Failed to load cash flow data',
            'error': e,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to load cash flow data',
        };
      }
    } catch (e) {
      _logger.e('Error getting cash flow analysis: $e');
      return {
        'success': false,
        'message': 'Failed to load cash flow data',
        'error': e,
      };
    }
  }

  Map<String, dynamic> _formatNewCashFlowResponse(
      Map<String, dynamic> response) {
    _logger.d('Formatting new cash flow response: $response');

    // Check if we have the expected fields
    if (!response.containsKey('date_range')) {
      throw Exception('Missing date_range in response');
    }

    if (!response.containsKey('summary')) {
      throw Exception('Missing summary in response');
    }

    final dateRange = response['date_range'] as Map<String, dynamic>;
    final summary = response['summary'] as Map<String, dynamic>;

    // Process detailed_analysis data if available
    Map<String, dynamic>? detailedAnalysis;
    List<Map<String, dynamic>> segments = [];

    if (response.containsKey('detailed_analysis') &&
        response['detailed_analysis'] != null) {
      detailedAnalysis = response['detailed_analysis'] as Map<String, dynamic>;
      _logger.d(
          'Found detailed analysis data in response with keys: ${detailedAnalysis.keys.join(', ')}');

      // Use the segments from detailed_analysis if available
      if (detailedAnalysis.containsKey('segments') &&
          detailedAnalysis['segments'] is List &&
          (detailedAnalysis['segments'] as List).isNotEmpty) {
        // Use detailed segments if available
        final detailedSegments = detailedAnalysis['segments'] as List;
        segments = detailedSegments
            .map((segment) => segment as Map<String, dynamic>)
            .toList();

        _logger.d(
            'Using ${segments.length} detailed segments from detailed_analysis');

        // Log the first segment to understand its structure
        if (segments.isNotEmpty) {
          _logger.d('First detailed segment: ${segments.first}');
        }
      }
      // If no segments in detailed_analysis directly, check for more specific breakdowns
      else {
        // Check for specific breakdowns based on timeFrame
        String breakdownKey = '';
        switch (response['timeFrame']?.toString()?.toLowerCase()) {
          case 'week':
            breakdownKey = 'daily_breakdown';
            break;
          case 'month':
            breakdownKey = 'weekly_breakdown';
            break;
          case 'quarter':
          case 'year':
            breakdownKey = 'monthly_breakdown';
            break;
        }

        if (breakdownKey.isNotEmpty &&
            detailedAnalysis.containsKey(breakdownKey) &&
            detailedAnalysis[breakdownKey] is List) {
          final breakdown = detailedAnalysis[breakdownKey] as List;
          segments =
              breakdown.map((item) => item as Map<String, dynamic>).toList();
          _logger.d('Using ${segments.length} segments from $breakdownKey');
        }
      }

      // Log for other types of breakdowns available
      for (final key in [
        'daily_breakdown',
        'weekly_breakdown',
        'monthly_breakdown'
      ]) {
        if (detailedAnalysis.containsKey(key)) {
          final breakdown = detailedAnalysis[key];
          if (breakdown is List) {
            _logger.d('$key contains ${breakdown.length} items');
            if (breakdown.isNotEmpty) {
              _logger.d('First item in $key: ${breakdown.first}');
            }
          }
        }
      }

      // Log highlights if available
      if (detailedAnalysis.containsKey('highlights')) {
        _logger.d('Highlights available: ${detailedAnalysis['highlights']}');
      }

      // Log totals if available
      if (detailedAnalysis.containsKey('totals')) {
        _logger.d('Totals available: ${detailedAnalysis['totals']}');
      }
    }

    // If we still don't have segments from detailed_analysis, create a single segment from summary data
    if (segments.isEmpty) {
      _logger.d(
          'No detailed segments found, creating single segment from summary data');

      // If there's no detailed segments, create a single segment from summary data
      // Use the start date from the date_range as the period
      String periodLabel =
          dateRange['start_date'] ?? DateTime.now().toString().substring(0, 10);

      segments = [
        {
          'period': periodLabel,
          'inflow': (summary['total_inflow'] as num?)?.toDouble() ?? 0.0,
          'outflow': (summary['total_outflow'] as num?)?.toDouble() ?? 0.0,
        }
      ];
    }

    // Calculate the growth rate - use from summary if available, otherwise use from comparison
    double growthRate = 0.0;
    if (summary.containsKey('growth_rate')) {
      growthRate = (summary['growth_rate'] as num?)?.toDouble() ?? 0.0;
      // Convert from percentage to decimal if needed
      if (growthRate > 1 || growthRate < -1) {
        growthRate = growthRate / 100;
      }
    } else if (response.containsKey('comparison')) {
      final comparison = response['comparison'] as Map<String, dynamic>?;
      if (comparison != null &&
          comparison.containsKey('net_cash_flow_change_percent')) {
        growthRate =
            (comparison['net_cash_flow_change_percent'] as num?)?.toDouble() ??
                0.0;
        // Convert from percentage to decimal if needed
        if (growthRate > 1 || growthRate < -1) {
          growthRate = growthRate / 100;
        }
      }
    }

    _logger.d('Formatted cash flow data with ${segments.length} segments');

    return {
      'timeframe':
          response['timeFrame']?.toString()?.toUpperCase() ?? 'LAST_MONTH',
      'totalInflow': (summary['total_inflow'] as num?)?.toDouble() ?? 0.0,
      'totalOutflow': (summary['total_outflow'] as num?)?.toDouble() ?? 0.0,
      'netCashFlow': ((summary['total_inflow'] as num?)?.toDouble() ?? 0.0) -
          ((summary['total_outflow'] as num?)?.toDouble() ?? 0.0),
      'growthRate': growthRate,
      'segments': segments,
      // Include detailed analysis if available
      if (detailedAnalysis != null) 'detailedAnalysis': detailedAnalysis,
    };
  }

  Future<Map<String, dynamic>> getSpendingAnalysis({String? timeFrame}) async {
    try {
      // Convert timeFrame to the format expected by the new endpoint
      String apiTimeFrame;
      switch (timeFrame) {
        case 'LAST_WEEK':
          apiTimeFrame = 'week';
          break;
        case 'LAST_MONTH':
          apiTimeFrame = 'month';
          break;
        case 'LAST_QUARTER':
          apiTimeFrame = 'quarter';
          break;
        case 'LAST_YEAR':
          apiTimeFrame = 'year';
          break;
        case 'ALL':
          apiTimeFrame = 'all';
          break;
        default:
          apiTimeFrame = 'month'; // Default to month if not specified
      }

      final response = await _makeRequest(
        endpoint: '/api/asset_report/spending/$apiTimeFrame',
        method: 'GET',
        requireAuth: true,
      );

      // Format the response to match what the UI expects
      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      _logger.e('Error getting spending analysis:', error: e);
      return {
        'success': false,
        'message': 'Failed to load expense data',
        'error': e.toString(),
      };
    }
  }

  Future<List<Map<String, dynamic>>> getRecurringExpenses(
      {String? userId}) async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/transactions/recurring',
        method: 'GET',
        body: userId != null ? {'userId': userId} : null,
        requireAuth: true,
      );
      return List<Map<String, dynamic>>.from(response['recurring_expenses']);
    } catch (e) {
      _logger.e('Error getting recurring expenses:', error: e);
      rethrow;
    }
  }

  // Blink Advance
  Future<Map<String, dynamic>> getBlinkAdvanceApprovalStatus() async {
    try {
      // Get the user ID from storage
      final userId = await _storageService.getUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('User ID not found');
      }

      final response = await _makeRequest(
        endpoint: '/api/cash-advance/approval-status/$userId',
        method: 'GET',
        requireAuth: true,
      );
      return response;
    } catch (e) {
      _logger.e('Error getting Blink Advance approval status:', error: e);
      rethrow;
    }
  }

  // Check for linked bank accounts
  Future<Map<String, dynamic>> checkLinkedBankAccount() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/plaid/linked-account-status',
        method: 'GET',
        requireAuth: true,
      );
      return response;
    } catch (e) {
      _logger.e('Error checking linked bank account:', error: e);
      rethrow;
    }
  }

  // Get Plaid access token
  Future<String> getPlaidAccessToken() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/plaid/access-token',
        method: 'GET',
        requireAuth: true,
      );

      if (response['access_token'] == null) {
        throw Exception('No access token received from server');
      }

      return response['access_token'];
    } catch (e) {
      _logger.e('Error getting Plaid access token:', error: e);
      rethrow;
    }
  }

  // New authentication endpoints will be added here

  Future<Map<String, dynamic>> createAssetReport({
    required List<String> accessTokens,
    required int daysRequested,
    Map<String, dynamic>? options,
  }) async {
    try {
      _logger.i('Creating asset report with options: $options');
      final response = await _makeRequest(
        endpoint: '/api/asset_report/create',
        method: 'POST',
        body: {
          'access_tokens': accessTokens,
          'days_requested': daysRequested,
          if (options != null) 'options': options,
        },
        requireAuth: true,
      );

      if (response['asset_report_token'] == null) {
        throw Exception('No asset report token received from server');
      }

      _logger.i('Asset report creation successful');
      return {
        'asset_report_token': response['asset_report_token'],
        'asset_report_id': response['asset_report_id'],
        'request_id': response['request_id'],
      };
    } catch (e) {
      _logger.e('Error creating asset report:', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAssetReport({
    required String assetReportToken,
    bool includeInsights = false,
  }) async {
    try {
      _logger.i(
          'Retrieving asset report with token: ${assetReportToken.substring(0, 10)}...');
      final response = await _makeRequest(
        endpoint: '/api/asset_report/get',
        method: 'POST',
        body: {
          'asset_report_token': assetReportToken,
          'include_insights': includeInsights,
        },
        requireAuth: true,
      );

      if (response['report'] == null) {
        throw Exception('No report data received from server');
      }

      _logger.i('Asset report retrieved successfully');
      return response['report'];
    } catch (e) {
      _logger.e('Error retrieving asset report:', error: e);
      rethrow;
    }
  }

  Future<List<Transaction>> getLatestTransactions({int limit = 7}) async {
    try {
      final dynamic response = await _makeRequest(
        endpoint: '/api/plaid/transactions/latest',
        method: 'GET',
        body: limit != 7 ? {'limit': limit.toString()} : null,
        requireAuth: true,
      );

      // Check if response is a list and convert it to transactions
      if (response is List) {
        final transactions = <Transaction>[];
        for (var item in response) {
          if (item is Map<String, dynamic>) {
            try {
              transactions.add(Transaction.fromJson(item));
            } catch (e) {
              _logger.e('Error parsing transaction: $e');
              // Skip invalid transactions
            }
          }
        }
        return transactions;
      }

      // If response is not a list, log an error and return an empty list
      _logger
          .e('Unexpected response format for latest transactions: $response');
      return [];
    } catch (e) {
      _logger.e('Error getting latest transactions:', error: e);
      rethrow;
    }
  }

  // Get All Transactions from Plaid endpoint
  Future<List<Transaction>> getAllTransactions() async {
    try {
      final dynamic response = await _makeRequest(
        endpoint: '/api/plaid/transactions/all',
        method: 'GET',
        requireAuth: true,
      );

      // Check if response is a list and convert it to transactions
      if (response is List) {
        final transactions = <Transaction>[];
        for (var item in response) {
          if (item is Map<String, dynamic>) {
            try {
              transactions.add(Transaction.fromJson(item));
            } catch (e) {
              _logger.e('Error parsing transaction: $e');
              // Skip invalid transactions
            }
          }
        }
        _logger
            .i('Fetched ${transactions.length} transactions from all accounts');
        return transactions;
      }

      // If response is not a list, log an error and return an empty list
      _logger.e('Unexpected response format for all transactions: $response');
      return [];
    } catch (e) {
      _logger.e('Error getting all transactions:', error: e);
      rethrow;
    }
  }

  // Get transaction location data by transaction ID
  Future<Map<String, dynamic>?> getTransactionLocation(
      String transactionId) async {
    try {
      // For demonstration purposes, we're simulating data from a database query
      // In a real app, this would likely make an API call or database query

      // Example API call (commented out):
      // final dynamic response = await _makeRequest(
      //   endpoint: '/api/plaid/transactions/$transactionId/location',
      //   method: 'GET',
      //   requireAuth: true,
      // );

      // Instead, we'll simulate a database query by returning sample data
      // This would typically be fetched from your backend or database

      // Simulate a delay similar to a network request
      await Future.delayed(const Duration(milliseconds: 300));

      // Return simulated location data based on transaction ID
      // In production, this would be real data from your database
      final firstDigit =
          transactionId.isNotEmpty ? transactionId[0].codeUnitAt(0) % 5 : 0;

      // Create a few sample locations for variety
      final locations = [
        {
          'location': {
            'lat': 25.7617,
            'lon': -80.1918,
            'city': 'Miami',
            'region': 'FL',
            'address': '1100 Biscayne Blvd',
            'country': 'US',
            'postal_code': '33132',
            'store_number': 'MIA042'
          }
        },
        {
          'location': {
            'lat': 25.8013,
            'lon': -80.1997,
            'city': 'Miami',
            'region': 'FL',
            'address': '2550 NW 2nd Ave',
            'country': 'US',
            'postal_code': '33127',
            'store_number': 'WYN015'
          }
        },
        {
          'location': {
            'lat': 25.7825,
            'lon': -80.1340,
            'city': 'Miami Beach',
            'region': 'FL',
            'address': '1001 Ocean Drive',
            'country': 'US',
            'postal_code': '33139',
            'store_number': 'SBE103'
          }
        },
        {
          'location': {
            'lat': 25.7501,
            'lon': -80.2567,
            'city': 'Coral Gables',
            'region': 'FL',
            'address': '280 Miracle Mile',
            'country': 'US',
            'postal_code': '33134',
            'store_number': 'CGB024'
          }
        },
        {
          'location': {
            'lat': 25.7602,
            'lon': -80.1959,
            'city': 'Miami',
            'region': 'FL',
            'address': '901 S Miami Ave',
            'country': 'US',
            'postal_code': '33130',
            'store_number': 'BRK078'
          }
        }
      ];

      return locations[firstDigit];
    } catch (e) {
      _logger.e('Error getting transaction location:', error: e);
      return null;
    }
  }

  // Get transaction location data from dedicated endpoint
  Future<Map<String, dynamic>?> getTransactionLocationFromEndpoint(
      String transactionId) async {
    try {
      // Call our dedicated endpoint for transaction location data
      final dynamic response = await _makeRequest(
        endpoint: '/api/asset_report/transaction/location/$transactionId',
        method: 'GET',
        requireAuth: true,
      );

      if (response != null) {
        _logger.i('Retrieved location data for transaction $transactionId');
        // The response contains the location data directly
        return response as Map<String, dynamic>;
      }

      _logger.w('No location data found for transaction $transactionId');
      return null;
    } catch (e) {
      _logger.e('Error fetching transaction location from endpoint:', error: e);
      return null;
    }
  }

  Future<Map<String, dynamic>> getRecurringExpensesAnalysis(
      {String? timeFrame}) async {
    try {
      // Convert timeFrame to the format expected by the new endpoint
      String apiTimeFrame;
      switch (timeFrame) {
        case 'LAST_WEEK':
          apiTimeFrame = 'week';
          break;
        case 'LAST_MONTH':
          apiTimeFrame = 'month';
          break;
        case 'LAST_QUARTER':
          apiTimeFrame = 'quarter';
          break;
        case 'LAST_YEAR':
          apiTimeFrame = 'year';
          break;
        case 'ALL':
          apiTimeFrame = 'all';
          break;
        default:
          apiTimeFrame = 'month'; // Default to month if not specified
      }

      final response = await _makeRequest(
        endpoint: '/api/asset_report/recurring/$apiTimeFrame',
        method: 'GET',
        requireAuth: true,
      );

      // Format the response to match what the UI expects
      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      _logger.e('Error getting recurring expenses analysis:', error: e);
      return {
        'success': false,
        'message': 'Failed to load recurring expenses data',
        'error': e.toString(),
      };
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
    // Handle category which can be a String or a List<dynamic>
    String? category;
    if (json['category'] is String) {
      category = json['category'] as String?;
    } else if (json['category'] is List &&
        (json['category'] as List).isNotEmpty) {
      // Join all categories or just use the first one
      category = (json['category'] as List).join(', ');
    }

    return TransactionDetail(
      id: json['id'] as String,
      merchantName: json['merchantName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: category,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
