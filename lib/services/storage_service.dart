// lib/services/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:blink_app/models/transaction.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageKeys {
  static const String firstName = 'firstName';
  static const String lastName = 'lastName';
  static const String state = 'state';
  static const String zipcode = 'zipcode';
  static const String email = 'email';
  static const String userId = 'userId';
  static const String token = 'token';
  static const String bankAccountId = 'bankAccountId';
  static const String bankAccountName = 'bankAccountName';
  static const String transactions = 'transactions';
  static const String lastUpdated = 'lastUpdated';
  static const String createdAt = 'createdAt';
  static const String encryptionKey = 'encryptionKey';
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  final Logger _logger = Logger();
  late final SharedPreferences _prefs;
  late final encrypt.Key _encryptionKey;
  final encrypt.IV _iv = encrypt.IV.fromLength(16);
  late final encrypt.Encrypter _encrypter;
  bool _isInitialized = false;
  late final SupabaseClient _supabase;

  factory StorageService(SharedPreferences prefs) {
    _instance._prefs = prefs;
    _instance._supabase = Supabase.instance.client;
    _instance._init();
    return _instance;
  }

  StorageService._internal();

  void _init() {
    if (!_isInitialized) {
      final key = _prefs.getString(StorageKeys.encryptionKey);
      if (key != null) {
        _encryptionKey = encrypt.Key.fromBase64(key);
        _encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      } else {
        _encryptionKey = encrypt.Key.fromSecureRandom(32);
        _prefs.setString(StorageKeys.encryptionKey, _encryptionKey.base64);
        _encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
      }
      _isInitialized = true;
    }
  }

  String _encrypt(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String _decrypt(String encryptedText) {
    final decrypted = _encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }

  // User Information

  Future<void> setFirstName(String firstName) async {
    try {
      await _prefs.setString(StorageKeys.firstName, firstName);
      _logger.i('First name set: $firstName');
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
      _logger.i('Last name set: $lastName');
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

  // Full Name Management
  Future<void> setFullName(String fullName) async {
    try {
      await _prefs.setString(
          'fullName', fullName); // Use a simple key for full name
      _logger.i('Full name set to: $fullName');
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

  Future<void> setState(String state) async {
    try {
      await _prefs.setString(StorageKeys.state, state);
      _logger.i('State set: $state');
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
      _logger.i('Zipcode set: $zipcode');
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
      _logger.i('Email set: $email');
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
      _logger.i('User ID set: $userId');
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

  // Token Management

  Future<void> setToken(String token) async {
    try {
      final encryptedToken = _encrypt(token);
      await _prefs.setString(StorageKeys.token, encryptedToken);
      _logger.i('Token set and encrypted.');
    } catch (e) {
      _logger.e('Failed to set token: $e');
      throw Exception('Failed to set token');
    }
  }

  String? getToken() {
    try {
      final encryptedToken = _prefs.getString(StorageKeys.token);
      if (encryptedToken == null) return null;
      final decryptedToken = _decrypt(encryptedToken);
      _logger.i('Token retrieved and decrypted.');
      return decryptedToken;
    } catch (e) {
      _logger.e('Failed to get token: $e');
      return null;
    }
  }

  // Bank Account ID
  Future<void> setBankAccountId(String id) async {
    try {
      await _prefs.setString(StorageKeys.bankAccountId, id);
      _logger.i('Bank account ID set: $id');
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

  // Bank Account Name
  Future<void> setBankAccountName(String name) async {
    try {
      await _prefs.setString(StorageKeys.bankAccountName, name);
      _logger.i('Bank account name set: $name');
    } catch (e) {
      _logger.e('Failed to set bank account name: $e');
      throw Exception('Failed to set bank account name');
    }
  }

  String? getBankAccountName() {
    try {
      return _prefs.getString(StorageKeys.bankAccountName);
    } catch (e) {
      _logger.e('Failed to get bank account name: $e');
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

  Future<void> setDetailedBankAccounts(
      List<Map<String, dynamic>> accounts) async {
    try {
      final jsonString = json.encode(accounts);
      await _prefs.setString('detailedBankAccounts', jsonString);
      _logger.i('Detailed bank accounts stored successfully');
    } catch (e) {
      _logger.e('Failed to store detailed bank accounts: $e');
      throw Exception('Failed to store detailed bank accounts');
    }
  }

  List<Map<String, dynamic>>? getDetailedBankAccounts() {
    try {
      final jsonString = _prefs.getString('detailedBankAccounts');
      if (jsonString != null) {
        return List<Map<String, dynamic>>.from(json.decode(jsonString));
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get detailed bank accounts: $e');
      return null;
    }
  }

  Future<void> setPrimaryAccountName(String name) async {
    try {
      await _prefs.setString('primaryAccountName', name);
      _logger.i('Primary account name set: $name');
    } catch (e) {
      _logger.e('Failed to set primary account name: $e');
      throw Exception('Failed to set primary account name');
    }
  }

  String? getPrimaryAccountName() {
    try {
      return _prefs.getString('primaryAccountName');
    } catch (e) {
      _logger.e('Failed to get primary account name: $e');
      return null;
    }
  }

  // New methods for storing and retrieving transactions
  Future<void> storeTransactions(List<Transaction> transactions) async {
    try {
      final jsonTransactions = transactions.map((t) => t.toJson()).toList();
      final jsonString = json.encode(jsonTransactions);
      final encryptedString = _encrypt(jsonString);
      await _prefs.setString(StorageKeys.transactions, encryptedString);
      await _prefs.setInt(
          StorageKeys.lastUpdated, DateTime.now().millisecondsSinceEpoch);
      _logger.i('Transactions stored successfully');
    } catch (e) {
      _logger.e('Failed to store transactions: $e');
      throw Exception('Failed to store transactions');
    }
  }

  List<Transaction>? getStoredTransactions() {
    try {
      final encryptedString = _prefs.getString(StorageKeys.transactions);
      if (encryptedString == null) return null;
      final jsonString = _decrypt(encryptedString);
      final jsonTransactions = json.decode(jsonString) as List;
      return jsonTransactions
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      _logger.e('Failed to retrieve stored transactions: $e');
      return null;
    }
  }

  bool isDataStale() {
    final lastUpdated = _prefs.getInt(StorageKeys.lastUpdated);
    if (lastUpdated == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - lastUpdated;
    // Consider data stale if it's older than 1 hour
    return difference > 3600000;
  }

  Future<void> clearTransactions() async {
    try {
      await _prefs.remove(StorageKeys.transactions);
      _logger.i('Transactions cleared successfully');
    } catch (e) {
      _logger.e('Failed to clear transactions: $e');
      throw Exception('Failed to clear transactions');
    }
  }

  Future<void> setAccountStatistics(Map<String, dynamic> statistics) async {
    try {
      final jsonString = json.encode(statistics);
      final encryptedString = _encrypt(jsonString);
      await _prefs.setString('accountStatistics', encryptedString);
      _logger.i('Account statistics stored successfully');
    } catch (e) {
      _logger.e('Failed to store account statistics: $e');
      throw Exception('Failed to store account statistics');
    }
  }

  Map<String, dynamic>? getAccountStatistics() {
    try {
      final encryptedString = _prefs.getString('accountStatistics');
      if (encryptedString == null) return null;
      final jsonString = _decrypt(encryptedString);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Failed to retrieve account statistics: $e');
      return null;
    }
  }

  Future<void> setUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final jsonString = json.encode(preferences);
      await _prefs.setString('userPreferences', jsonString);
      _logger.i('User preferences stored successfully');
    } catch (e) {
      _logger.e('Failed to store user preferences: $e');
      throw Exception('Failed to store user preferences');
    }
  }

  Map<String, dynamic>? getUserPreferences() {
    try {
      final jsonString = _prefs.getString('userPreferences');
      if (jsonString == null) return null;
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Failed to retrieve user preferences: $e');
      return null;
    }
  }

  Future<void> setCreatedAt(DateTime createdAt) async {
    try {
      await _prefs.setString('createdAt', createdAt.toIso8601String());
      _logger.i('Created at date set: $createdAt');
    } catch (e) {
      _logger.e('Failed to set created at date: $e');
      throw Exception('Failed to set created at date');
    }
  }

  DateTime? getCreatedAt() {
    try {
      final createdAtString = _prefs.getString('createdAt');
      return createdAtString != null ? DateTime.parse(createdAtString) : null;
    } catch (e) {
      _logger.e('Failed to get created at date: $e');
      return null;
    }
  }

  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final fileExt = path.extension(imageFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId-$timestamp$fileExt';

      _logger.i('Uploading profile picture: $fileName');

      await _supabase.storage.from('profiles').upload(fileName, imageFile,
          fileOptions: const FileOptions(upsert: true));

      final imageUrl =
          _supabase.storage.from('profiles').getPublicUrl(fileName);

      _logger.i('Profile picture uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      _logger.e('Error uploading profile picture', error: e);
      return null;
    }
  }

  String? getProfilePictureUrl(String userId) {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return _supabase.storage
          .from('profiles')
          .getPublicUrl('$userId-$timestamp.jpg');
    } catch (e) {
      _logger.e('Error getting profile picture URL', error: e);
      return null;
    }
  }
}
