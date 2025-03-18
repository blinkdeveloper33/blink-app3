import 'package:flutter/foundation.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper class for API configuration
class ApiConfig {
  static final Logger _logger = Logger();

  /// Get the base URL for API requests
  static String get baseUrl {
    // Use environment variable if available
    if (dotenv.env.containsKey('API_BASE_URL')) {
      return dotenv.env['API_BASE_URL']!;
    }

    // Fallback to hardcoded values based on build mode
    if (kReleaseMode) {
      return 'https://api.blinkfinances.com';
    } else if (kProfileMode) {
      return 'https://api-staging.blinkfinances.com';
    } else {
      return 'https://api-dev.blinkfinances.com';
    }
  }

  /// Get the headers for authenticated API requests
  static Future<Map<String, String>> getAuthHeaders() async {
    try {
      // Get an instance of SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);
      final token = await storageService.getToken();

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      return headers;
    } catch (e) {
      _logger.e('Error getting auth headers: $e');
      // Return basic headers if token retrieval fails
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    }
  }
}
