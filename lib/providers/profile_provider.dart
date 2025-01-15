import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_storage_service.dart';

class ProfileProvider extends ChangeNotifier {
  String? _profilePictureUrl;

  String? get profilePictureUrl => _profilePictureUrl;

  Future<void> updateProfilePicture(String? url) async {
    _profilePictureUrl = url;
    notifyListeners();
  }

  Future<void> loadProfilePicture(String userId) async {
    final supabaseStorage = SupabaseStorageService(Supabase.instance.client);

    try {
      final existingFiles = await supabaseStorage.listFiles(userId);
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
        final url =
            supabaseStorage.getProfilePictureUrl(userId, latestProfilePic);
        if (url != null) {
          await updateProfilePicture(url);
        }
      }
    } catch (e) {
      debugPrint('Error loading profile picture: $e');
    }
  }
}
