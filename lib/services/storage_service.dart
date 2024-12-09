import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageKeys {
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String state = 'state';
  static const String zipcode = 'zipcode';
  static const String email = 'email';
  static const String userId = 'userId';
  static const String token = 'token'; // Consistent key usage
  static const String bankAccountId = 'bankAccountId';
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  final Logger _logger = Logger();
  late SharedPreferences _prefs;
  late encrypt.Key _encryptionKey;
  final encrypt.IV _iv = encrypt.IV.fromLength(16);
  late encrypt.Encrypter _encrypter;

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  /// Initializes SharedPreferences and encryption settings. Must be called before using the service.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _logger.i('SharedPreferences initialized successfully.');

      // Load encryption key from environment variables
      final keyString = dotenv.env['ENCRYPTION_KEY'];
      if (keyString == null || keyString.length != 32) {
        throw Exception('Invalid or missing ENCRYPTION_KEY in .env file.');
      }

      _encryptionKey = encrypt.Key.fromUtf8(keyString);
      _encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));

      _logger.i('Encryption key initialized successfully.');
    } catch (e) {
      _logger.e('Failed to initialize StorageService: $e');
      throw Exception('Failed to initialize StorageService');
    }
  }

  /// Encrypts a plain text string.
  String _encrypt(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts an encrypted string.
  String _decrypt(String encryptedText) {
    final decrypted = _encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }

  // User Information

  Future<void> setFirstName(String firstName) async {
    try {
      await _prefs.setString(StorageKeys.firstName, firstName);
    } catch (e) {
      _logger.e('Failed to set first name: $e');
      throw Exception('Failed to set first name');
    }
  }

  String? getFirstName() {
    try {
      return _prefs.getString(StorageKeys.firstName);
    } catch (e) {
      _logger.e('Failed to get first name: $e');
      return null;
    }
  }

  Future<void> setLastName(String lastName) async {
    try {
      await _prefs.setString(StorageKeys.lastName, lastName);
    } catch (e) {
      _logger.e('Failed to set last name: $e');
      throw Exception('Failed to set last name');
    }
  }

  String? getLastName() {
    try {
      return _prefs.getString(StorageKeys.lastName);
    } catch (e) {
      _logger.e('Failed to get last name: $e');
      return null;
    }
  }

  Future<void> setState(String state) async {
    try {
      await _prefs.setString(StorageKeys.state, state);
    } catch (e) {
      _logger.e('Failed to set state: $e');
      throw Exception('Failed to set state');
    }
  }

  String? getState() {
    try {
      return _prefs.getString(StorageKeys.state);
    } catch (e) {
      _logger.e('Failed to get state: $e');
      return null;
    }
  }

  Future<void> setZipcode(String zipcode) async {
    try {
      await _prefs.setString(StorageKeys.zipcode, zipcode);
    } catch (e) {
      _logger.e('Failed to set zipcode: $e');
      throw Exception('Failed to set zipcode');
    }
  }

  String? getZipcode() {
    try {
      return _prefs.getString(StorageKeys.zipcode);
    } catch (e) {
      _logger.e('Failed to get zipcode: $e');
      return null;
    }
  }

  Future<void> setEmail(String email) async {
    try {
      await _prefs.setString(StorageKeys.email, email);
    } catch (e) {
      _logger.e('Failed to set email: $e');
      throw Exception('Failed to set email');
    }
  }

  String? getEmail() {
    try {
      return _prefs.getString(StorageKeys.email);
    } catch (e) {
      _logger.e('Failed to get email: $e');
      return null;
    }
  }

  Future<void> setUserId(String userId) async {
    try {
      await _prefs.setString(StorageKeys.userId, userId);
    } catch (e) {
      _logger.e('Failed to set user ID: $e');
      throw Exception('Failed to set user ID');
    }
  }

  String? getUserId() {
    try {
      return _prefs.getString(StorageKeys.userId);
    } catch (e) {
      _logger.e('Failed to get user ID: $e');
      return null;
    }
  }

  // Full Name Management
  Future<void> setFullName(String fullName) async {
    try {
      await _prefs.setString(
          'fullName', fullName); // Use a simple key for full name
    } catch (e) {
      _logger.e('Failed to set full name: $e');
      throw Exception('Failed to set full name');
    }
  }

  String? getFullName() {
    try {
      return _prefs
          .getString('fullName'); // Use the same key to retrieve full name
    } catch (e) {
      _logger.e('Failed to get full name: $e');
      return null;
    }
  }

  // Token Management

  Future<void> setToken(String token) async {
    try {
      final encryptedToken = _encrypt(token);
      await _prefs.setString(StorageKeys.token, encryptedToken);
    } catch (e) {
      _logger.e('Failed to set token: $e');
      throw Exception('Failed to set token');
    }
  }

  String? getToken() {
    try {
      final encryptedToken = _prefs.getString(StorageKeys.token);
      if (encryptedToken == null) return null;
      return _decrypt(encryptedToken);
    } catch (e) {
      _logger.e('Failed to get token: $e');
      return null;
    }
  }

  // Bank Account ID
  Future<void> setBankAccountId(String id) async {
    try {
      await _prefs.setString(StorageKeys.bankAccountId, id);
    } catch (e) {
      _logger.e('Failed to set bank account ID: $e');
      throw Exception('Failed to set bank account ID');
    }
  }

  String? getBankAccountId() {
    try {
      return _prefs.getString(StorageKeys.bankAccountId);
    } catch (e) {
      _logger.e('Failed to get bank account ID: $e');
      return null;
    }
  }

  // Clear all stored data
  Future<void> clearAll() async {
    try {
      await _prefs.clear();
      _logger.i('All stored data cleared successfully.');
    } catch (e) {
      _logger.e('Failed to clear all data: $e');
      throw Exception('Failed to clear all data');
    }
  }
}
