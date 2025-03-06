import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Base URL for the API
  static String get baseUrl {
    final url = dotenv.env['BACKEND_URL'] ??
        'blinkbackendproduction-production.up.railway.app';
    // Ensure the URL has https:// prefix
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
