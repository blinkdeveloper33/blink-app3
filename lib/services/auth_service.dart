import 'dart:convert';
import 'package:myapp/services/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

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
      amount: amount,
      isOutflow: isOutflow,
    );
  }
}

enum UserStatus { newUser, noBankAccount, complete }

/// A service class responsible for handling authentication and Plaid-related API interactions.
class AuthService {
  /// Base URL of the backend API.
  final String _baseUrl = dotenv.env['BACKEND_URL'] ??
      'https://your-backend-url.com'; // Update to your actual backend URL

  /// Logger instance for logging information and errors.
  final Logger _logger;

  /// Reference to the StorageService for token management.
  final StorageService _storageService;

  /// Constructor for AuthService. Initializes StorageService and allows injecting a custom Logger.
  AuthService({Logger? logger, required StorageService storageService})
      : _logger = logger ?? Logger(),
        _storageService = storageService;

  /// Helper method to make API requests.
  ///
  /// [endpoint]: The API endpoint (e.g., '/api/users/login').
  /// [body]: The JSON body to send with the request.
  /// [method]: HTTP method ('POST' or 'GET').
  /// [requireAuth]: Whether the request requires an Authorization header.
  Future<Map<String, dynamic>> _makeRequest({
    required String endpoint,
    required Map<String, dynamic> body,
    required String method,
    bool requireAuth = false,
  }) async {
    final headers = {'Content-Type': 'application/json'};

    // If the endpoint requires authentication, retrieve and include the JWT token.
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

      // Make the appropriate HTTP request based on the method.
      if (method.toUpperCase() == 'POST') {
        response =
            await http.post(url, headers: headers, body: jsonEncode(body));
      } else if (method.toUpperCase() == 'GET') {
        response = await http.get(url, headers: headers);
      } else {
        throw UnsupportedMethodException('Unsupported HTTP method: $method');
      }

      _logger.i(
          'Response from $endpoint: ${response.statusCode} - ${response.body}');

      // Parse and return the JSON response for successful requests.
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        // Attempt to parse the error message from the response.
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

  /// Initiates user registration by sending an OTP to the provided email.
  ///
  /// [email]: The user's email address.
  Future<Map<String, dynamic>> registerInitial(String email) async {
    return _makeRequest(
      endpoint: '/api/users/register-initial',
      body: {'email': email},
      method: 'POST',
      requireAuth: false,
    );
  }

  /// Verifies the OTP sent to the user's email.
  ///
  /// [email]: The user's email address.
  /// [otp]: The OTP code received by the user.
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    return _makeRequest(
      endpoint: '/api/users/verify-otp',
      body: {'email': email, 'otp': otp},
      method: 'POST',
      requireAuth: false,
    );
  }

  /// Resends the OTP to the user's email.
  ///
  /// [email]: The user's email address.
  Future<Map<String, dynamic>> sendOtp(String email) async {
    return _makeRequest(
      endpoint: '/api/users/resend-otp',
      body: {'email': email},
      method: 'POST',
      requireAuth: false,
    );
  }

  /// Completes user registration by submitting password and personal information.
  ///
  /// [email]: The user's email address.
  /// [password]: The user's chosen password.
  /// [firstName]: The user's first name.
  /// [lastName]: The user's last name.
  /// [state]: The user's state of residence.
  /// [zipcode]: The user's ZIP code.
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
      requireAuth: false,
    );
  }

  /// Logs in the user by validating their email and password.
  ///
  /// [email]: The user's email address.
  /// [password]: The user's password.
  ///
  /// Returns a map containing the JWT token and user information on success.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _makeRequest(
      endpoint: '/api/users/login',
      body: {'email': email, 'password': password},
      method: 'POST',
      requireAuth: false,
    );

    if (response['success']) {
      // Store the JWT token securely upon successful login.
      await _storageService.setToken(response['token']);
      await _storageService.setUserId(response['userId']);

      // Store the user's full name
      final fullName = '${response['firstName']} ${response['lastName']}';
      await _storageService.setFullName(fullName);

      // Fetch and store user profile information
      await _fetchAndStoreUserProfile();
    }

    return response;
  }

  /// Logs out the user by clearing the JWT token from StorageService.
  Future<void> logout() async {
    await _storageService.clearAll();
    // Optionally, implement a backend logout endpoint and call it here.
  }

  /// Creates a Plaid Link token to initialize the Plaid Link flow.
  ///
  /// [userId]: The unique identifier of the user.
  ///
  /// Returns the `link_token` string on success.
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

  /// Exchanges a Plaid public token for an access token and associates it with the user.
  ///
  /// [publicToken]: The public token obtained from the Plaid Link flow.
  /// [userId]: The unique identifier of the user.
  ///
  /// Returns a map containing information about the connected bank accounts.
  Future<Map<String, dynamic>> exchangePublicToken(
      String publicToken, String userId) async {
    return _makeRequest(
      endpoint: '/api/plaid/exchange_public_token',
      body: {'publicToken': publicToken, 'userId': userId},
      method: 'POST',
      requireAuth: true,
    );
  }

  /// Synchronizes transactions for the specified user by fetching the latest data from Plaid.
  ///
  /// [userId]: The unique identifier of the user.
  ///
  /// Returns a map containing statistics about the synchronization process.
  Future<Map<String, dynamic>> syncTransactions(String userId) async {
    return _makeRequest(
      endpoint: '/api/plaid/sync',
      body: {'userId': userId},
      method: 'POST',
      requireAuth: true,
    );
  }

  /// Retrieves a paginated list of transactions for a specific bank account or all accounts within a date range.
  ///
  /// [userId]: The unique identifier of the user.
  /// [bankAccountId]: The unique identifier of the bank account. Use 'all' for all accounts.
  /// [startDate]: The start date in ISO 8601 format (e.g., "2024-01-01").
  /// [endDate]: The end date in ISO 8601 format (e.g., "2024-01-31").
  /// [page]: The page number for pagination (default is 1).
  /// [limit]: The number of transactions per page (default is 50, maximum is 100).
  ///
  /// Returns a map containing the list of transactions and pagination details.
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

    // Only include bankAccountId in the request if it's not 'all'
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

  /// Synchronizes account balances for all linked bank accounts of the user.
  ///
  /// [userId]: The unique identifier of the user.
  ///
  /// Returns a map containing the synchronization status.
  Future<Map<String, dynamic>> syncBalances(String userId) async {
    return _makeRequest(
      endpoint: '/api/plaid/sync_balances',
      body: {'userId': userId},
      method: 'POST',
      requireAuth: true,
    );
  }

  /// Generates a Plaid Sandbox public token for testing purposes.
  ///
  /// [institutionId]: (Optional) The ID of the institution to connect with. Defaults to 'ins_109508'.
  /// [initialProducts]: (Optional) List of initial products to enable. Defaults to ['transactions'].
  /// [webhook]: (Optional) The webhook URL to receive Plaid events.
  ///
  /// Returns a map containing the `public_token` and `request_id`.
  Future<Map<String, dynamic>> generateSandboxPublicToken({
    String? institutionId,
    List<String>? initialProducts,
    String? webhook,
  }) async {
    return _makeRequest(
      endpoint: '/api/plaid/sandbox/public_token/create',
      body: {
        if (institutionId != null) 'institution_id': institutionId,
        if (initialProducts != null) 'initial_products': initialProducts,
        if (webhook != null) 'webhook': webhook,
      },
      method: 'POST',
      requireAuth: true,
    );
  }

  /// Initialize method if needed for future use.
  Future<void> init() async {
    // Implement any initialization logic if necessary
  }

  /// Get the user's status (new user, no bank account, or complete).
  ///
  /// Returns the UserStatus enum value.
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

  Future<Map<String, dynamic>> createBlinkAdvance({
    required String userId,
    required double requestedAmount,
    required String transferSpeed,
    required DateTime repayDate,
    required String bankAccountId,
  }) async {
    return _makeRequest(
      endpoint: '/api/blink-advances/',
      body: {
        'requestedAmount': requestedAmount,
        'transferSpeed': transferSpeed,
        'repayDate': repayDate.toIso8601String(),
        'bankAccountId': bankAccountId,
      },
      method: 'POST',
      requireAuth: true,
    );
  }

  Future<void> _fetchAndStoreUserProfile() async {
    try {
      final response = await _makeRequest(
        endpoint: '/api/users/profile', // Assuming this endpoint exists
        body: {},
        method: 'GET',
        requireAuth: true,
      );

      if (response['success']) {
        final profile = response['profile'];
        // Store necessary profile information in StorageService
        _storageService.setFirstName(profile['firstName']);
        _storageService.setLastName(profile['lastName']);
        // ... store other relevant profile data
      }
    } catch (e) {
      _logger.e('Error fetching user profile: $e');
      // Handle error appropriately, e.g., show an error message
    }
  }
}

/// Custom exception class for API-related errors.
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';
}

/// Custom exception class for unsupported HTTP methods.
class UnsupportedMethodException implements Exception {
  final String message;
  UnsupportedMethodException(this.message);

  @override
  String toString() => 'UnsupportedMethodException: $message';
}

/// Custom exception class for scenarios where the user already exists.
class UserAlreadyExistsException implements Exception {
  final String message;
  UserAlreadyExistsException(this.message);

  @override
  String toString() => 'UserAlreadyExistsException: $message';
}

/// Custom exception class for invalid OTP scenarios.
class InvalidOtpException implements Exception {
  final String message;
  InvalidOtpException(this.message);

  @override
  String toString() => 'InvalidOtpException: $message';
}
