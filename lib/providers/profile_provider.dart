import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_storage_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class ProfileProvider extends ChangeNotifier {
  String? _profilePictureUrl;
  bool _isLoading = false;
  String? _error;
  final AuthService? _authService;
  final StorageService? _storageService;

  ProfileProvider({AuthService? authService, StorageService? storageService})
      : _authService = authService,
        _storageService = storageService;

  String? get profilePictureUrl {
    // Add a cache-busting timestamp parameter to the URL if it exists
    if (_profilePictureUrl != null && _profilePictureUrl!.isNotEmpty) {
      // Check if URL already has query parameters
      if (_profilePictureUrl!.contains('?')) {
        return '$_profilePictureUrl&cache=${DateTime.now().millisecondsSinceEpoch}';
      } else {
        return '$_profilePictureUrl?cache=${DateTime.now().millisecondsSinceEpoch}';
      }
    }
    return _profilePictureUrl;
  }

  // Original URL without cache busting for comparison
  String? get originalProfilePictureUrl => _profilePictureUrl;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> updateProfilePicture(String? url) async {
    _profilePictureUrl = url;
    notifyListeners();
  }

  // Main method to load profile picture - tries API first, then falls back to Supabase
  Future<void> loadProfilePicture(String userId) async {
    // Set loading state but don't notify yet to avoid potential build conflicts
    _isLoading = true;
    _error = null;

    try {
      // First try to get profile from API endpoint
      final apiSuccess = await _loadProfileFromApi();

      // If API method didn't work, fall back to direct Supabase method
      if (!apiSuccess) {
        await _loadProfileFromSupabase(userId);
      }
    } catch (e) {
      debugPrint('Error loading profile picture: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      // Only notify at the end, once all loading is complete
      notifyListeners();
    }
  }

  // Method to load profile from API
  Future<bool> _loadProfileFromApi() async {
    try {
      // Get token through AuthService if available, otherwise try StorageService
      String? token;
      if (_authService != null) {
        token = await _authService!.getToken();
      } else if (_storageService != null) {
        token = await _storageService!.getToken();
      } else {
        // Try to get token from Supabase session as last resort
        final supabase = Supabase.instance.client;
        token = supabase.auth.currentSession?.accessToken;
      }

      if (token == null) {
        debugPrint(
            'No authentication token available for user profile request');
        return false;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final userData = data['data'];

          if (userData['imageUrl'] != null &&
              userData['imageUrl'].toString().isNotEmpty) {
            _profilePictureUrl = userData['imageUrl'];
            debugPrint('Profile image URL from API: $_profilePictureUrl');
            // Don't notify here - will be done at the end of loadProfilePicture
            return true;
          } else {
            debugPrint('No profile image URL found in API response');
          }
        } else {
          debugPrint('API response indicates failure or no data');
        }
      } else {
        debugPrint('Failed to get user profile: HTTP ${response.statusCode}');
      }

      return false;
    } catch (e) {
      debugPrint('Error in API profile picture fetch: $e');
      return false;
    }
  }

  // Fallback method using Supabase directly
  Future<void> _loadProfileFromSupabase(String userId) async {
    final supabaseStorage = SupabaseStorageService(Supabase.instance.client);

    try {
      final url = await supabaseStorage.getLatestProfilePictureUrl(userId);
      if (url != null) {
        _profilePictureUrl = url;
        debugPrint('Profile picture loaded from Supabase storage: $url');
        // Don't notify here - will be done at the end of loadProfilePicture
      } else {
        debugPrint('No profile picture found in Supabase for user $userId');
      }
    } catch (e) {
      debugPrint('Error loading profile picture from Supabase: $e');
      rethrow;
    }
  }
}
