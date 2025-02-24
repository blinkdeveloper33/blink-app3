import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';

// Add this class at the top of the file, before SupabaseStorageService
class ProfileImageCache {
  final String url;
  final DateTime timestamp;
  final String etag;

  ProfileImageCache({
    required this.url,
    required this.timestamp,
    required this.etag,
  });
}

class SupabaseStorageService {
  final SupabaseClient _supabase;
  final Logger _logger = Logger();
  static const String _bucketName = 'profiles';

  // Cache to store profile picture URLs with timestamps
  final Map<String, ProfileImageCache> _profilePictureCache = {};

  SupabaseStorageService(this._supabase);

  String _generateCacheBustingUrl(String baseUrl) {
    return '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String?> getLatestProfilePictureUrl(String userId) async {
    try {
      // Check if we have a valid cached URL that's less than 5 minutes old
      final cachedData = _profilePictureCache[userId];
      final cacheExpiration = Duration(minutes: 5);

      if (cachedData != null &&
          DateTime.now().difference(cachedData.timestamp) < cacheExpiration) {
        return cachedData.url;
      }

      // Clear any existing cache for this user
      await clearCache(userId);

      // Get the latest profile picture
      final existingFiles = await listFiles(userId);
      String? latestProfilePic;
      DateTime latestTimestamp = DateTime(1970);

      for (final file in existingFiles) {
        if (file.name.startsWith('profile_')) {
          final timestamp = int.tryParse(file.name.split('_')[1].split('.')[0]);
          if (timestamp != null) {
            final fileTimestamp =
                DateTime.fromMillisecondsSinceEpoch(timestamp);
            if (fileTimestamp.isAfter(latestTimestamp)) {
              latestTimestamp = fileTimestamp;
              latestProfilePic = file.name;
            }
          }
        }
      }

      if (latestProfilePic != null) {
        final baseUrl = _supabase.storage
            .from(_bucketName)
            .getPublicUrl('$userId/$latestProfilePic');
        final cacheBustedUrl = _generateCacheBustingUrl(baseUrl);

        // Store in cache with current timestamp and etag
        _profilePictureCache[userId] = ProfileImageCache(
          url: cacheBustedUrl,
          timestamp: DateTime.now(),
          etag: DateTime.now().millisecondsSinceEpoch.toString(),
        );

        return cacheBustedUrl;
      }

      return null;
    } catch (e) {
      _logger.e('Error getting latest profile picture URL: $e');
      return null;
    }
  }

  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      // Generate file path with timestamp to avoid caching issues
      final fileExt = path.extension(imageFile.path).toLowerCase();
      if (!_isValidImageExtension(fileExt)) {
        _logger.e('Invalid file extension: $fileExt');
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_$timestamp$fileExt';
      final filePath = '$userId/$fileName';

      _logger.i('Starting profile picture upload');
      _logger.i('File path: $filePath');
      _logger.i('File extension: $fileExt');

      // Try to remove existing files first
      try {
        final existingFiles =
            await _supabase.storage.from(_bucketName).list(path: userId);
        for (final file in existingFiles) {
          if (file.name.startsWith('profile_')) {
            await _supabase.storage
                .from(_bucketName)
                .remove(['$userId/${file.name}']);
            _logger.i('Removed existing file: ${file.name}');
          }
        }
      } catch (e) {
        _logger.w('Error while checking/removing existing files: $e');
        // Continue with upload even if removal fails
      }

      // Set the correct content type based on file extension
      String contentType;
      switch (fileExt) {
        case '.jpg':
        case '.jpeg':
          contentType = 'image/jpeg';
          break;
        case '.png':
          contentType = 'image/png';
          break;
        case '.gif':
          contentType = 'image/gif';
          break;
        default:
          contentType = 'image/jpeg'; // fallback
      }

      // Upload new file
      _logger.i('Uploading new file with content type: $contentType');
      await _supabase.storage.from(_bucketName).upload(
            filePath,
            imageFile,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: contentType,
            ),
          );

      // Get public URL
      final imageUrl =
          _supabase.storage.from(_bucketName).getPublicUrl(filePath);
      _logger.i('Upload successful: $imageUrl');

      return imageUrl;
    } catch (e, stackTrace) {
      _logger.e('Error uploading profile picture: $e');
      _logger.e('Stack trace: $stackTrace');
      return null;
    }
  }

  String? getProfilePictureUrl(String userId, String fileName) {
    try {
      final filePath = '$userId/$fileName';
      return _supabase.storage.from(_bucketName).getPublicUrl(filePath);
    } catch (e) {
      _logger.e('Error getting profile picture URL: $e');
      return null;
    }
  }

  Future<List<FileObject>> listFiles(String path) async {
    try {
      return await _supabase.storage.from(_bucketName).list(path: path);
    } catch (e) {
      _logger.e('Error listing files: $e');
      return [];
    }
  }

  bool _isValidImageExtension(String extension) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
    return validExtensions.contains(extension.toLowerCase());
  }

  Future<void> clearCache(String userId) async {
    try {
      // Remove from in-memory cache
      _profilePictureCache.remove(userId);

      // Clear network image cache if available
      try {
        // This would be implemented if using cached_network_image package
        // await DefaultCacheManager().removeFile(getProfilePictureUrl(userId, '*'));
      } catch (e) {
        _logger.w('Error clearing network cache: $e');
      }

      _logger.i('Cleared cache for user: $userId');
    } catch (e) {
      _logger.e('Error clearing cache for user $userId: $e');
    }
  }
}
