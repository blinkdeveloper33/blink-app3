import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Base URL for the API
  static String get baseUrl {
    final url =
        dotenv.env['BACKEND_URL'] ?? 'blinkbackend2-production.up.railway.app';
    // Ensure the URL has https:// prefix
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  // API Endpoints
  static const String blinkAdvances = '/api/blink-advances';

  // API Versions
  static const String apiVersion = 'v1';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
