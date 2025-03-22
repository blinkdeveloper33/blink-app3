import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:blink_app/providers/profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:async';
import 'dart:convert';
import 'package:blink_app/config/api_config.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/services/storage_service.dart';

// Define a custom AnimatedEmojiData for the locked emoji if not already defined elsewhere
final lockedEmoji = AnimatedEmojiData('1f512', name: 'locked');

class ProfileHeader extends StatefulWidget {
  final VoidCallback onReload;
  final String? userName;
  final String? email;
  final bool showEmail;

  const ProfileHeader({
    Key? key,
    required this.onReload,
    this.userName,
    this.email,
    this.showEmail = true,
  }) : super(key: key);

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  final ImagePicker _imagePicker = ImagePicker();
  final ImageCropper _imageCropper = ImageCropper();
  bool _isLoading = false;
  String _userName = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didUpdateWidget(ProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userName != oldWidget.userName ||
        widget.email != oldWidget.email) {
      _updateFromProps();
    }
  }

  void _updateFromProps() {
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      setState(() {
        _userName = widget.userName!;
      });
    }

    if (widget.email != null && widget.email!.isNotEmpty) {
      setState(() {
        _email = widget.email!;
      });
    }
  }

  Future<void> _loadUserData() async {
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      setState(() {
        _userName = widget.userName!;
      });
    }

    if (widget.email != null && widget.email!.isNotEmpty) {
      setState(() {
        _email = widget.email!;
      });
      return;
    }

    final storageService = Provider.of<StorageService>(context, listen: false);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    final userId = storageService.getUserId();
    if (userId != null) {
      await profileProvider.loadProfilePicture(userId);
    }

    if (_userName.isEmpty) {
      final cachedName =
          '${storageService.getFirstName() ?? ''} ${storageService.getLastName() ?? ''}'
              .trim();
      if (mounted && cachedName.isNotEmpty) {
        setState(() {
          _userName = cachedName;
        });
      }
    }

    if (_email.isEmpty) {
      final cachedEmail = storageService.getEmail() ?? '';
      if (mounted && cachedEmail.isNotEmpty) {
        setState(() {
          _email = cachedEmail;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 60,
      );
      if (pickedFile == null) return;

      final croppedFile = await _imageCropper.cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 50,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Your Profile Picture',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Your Profile Picture',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return;

      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // Get auth token
      final authService = Provider.of<AuthService>(context, listen: false);
      final String? authToken = await authService.getToken();
      if (authToken == null) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication error. Please login again.')),
        );
        return;
      }

      // Create multipart request with a timeout
      final url = Uri.parse(
          '${ApiConfig.baseUrl}/api/user-profile/upload-profile-picture');
      final request = http.MultipartRequest('POST', url);

      // Add auth header
      request.headers['Authorization'] = 'Bearer $authToken';

      // Add file
      final file = await http.MultipartFile.fromPath(
          'profile_picture', croppedFile.path,
          contentType: MediaType('image', 'jpeg'));
      request.files.add(file);

      // Create a client with timeout
      final client = http.Client();
      try {
        // Implement retry logic with exponential backoff
        int retries = 3;
        http.StreamedResponse? streamedResponse;

        while (retries > 0) {
          try {
            // Send request with timeout
            streamedResponse =
                await client.send(request).timeout(const Duration(seconds: 60));
            break;
          } catch (e) {
            retries--;
            if (retries == 0) {
              rethrow;
            }

            // Wait with exponential backoff
            final backoffSeconds = pow(2, 3 - retries).toInt();
            await Future.delayed(Duration(seconds: backoffSeconds));
          }
        }

        if (streamedResponse == null) {
          throw Exception('Failed to upload after retry attempts');
        }

        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseBody = response.body;
          Map<String, dynamic> data = jsonDecode(responseBody);

          // Get the profile picture URL from the response with safer extraction
          String? profilePictureUrl;
          if (data.containsKey('data') &&
              data['data'] is Map<String, dynamic>) {
            final dataMap = data['data'] as Map<String, dynamic>;
            if (dataMap.containsKey('imageUrl')) {
              profilePictureUrl = dataMap['imageUrl'] as String?;
            }
          }

          if (profilePictureUrl != null) {
            // Update profile provider
            if (mounted) {
              final profileProvider =
                  Provider.of<ProfileProvider>(context, listen: false);
              profileProvider.updateProfilePicture(profilePictureUrl);

              // Also reload profile from API to ensure we have the latest
              final storageService =
                  Provider.of<StorageService>(context, listen: false);
              final userId = storageService.getUserId();
              if (userId != null) {
                // Fire and forget - this will update the profile picture URL when the API responds
                profileProvider.loadProfilePicture(userId).catchError((e) {
                  debugPrint('Error refreshing profile from API: $e');
                });
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Profile picture updated successfully!')),
              );

              // Call the onReload callback to refresh parent components
              widget.onReload();
            }
          } else {
            throw Exception('Profile picture URL not found in response');
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Failed to update profile picture. Server returned ${response.statusCode}')),
            );
          }
        }
      } on TimeoutException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Connection timed out. Please try with a smaller image or check your network')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Network error: ${e.toString().substring(0, min(50, e.toString().length))}')),
          );
        }
      } finally {
        client.close();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error updating profile picture. Please try again with a smaller image.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Update Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2196F3),
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  haptics.Haptics.vibrate(haptics.HapticsType.light);
                  Navigator.pop(context);
                  _pickAndUploadImage();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade400,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                title: const Text('Remove Current Picture'),
                onTap: () {
                  haptics.Haptics.vibrate(haptics.HapticsType.heavy);
                  // Implement remove picture functionality
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.2)
              : const Color(0xFF2196F3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[200],
          child: Icon(
            Icons.person,
            size: 60,
            color: isDarkMode ? Colors.white70 : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureContent() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
        final profilePictureUrl = profileProvider.profilePictureUrl;

        return ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (profilePictureUrl != null && profilePictureUrl.isNotEmpty)
                Image.network(
                  profilePictureUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 300,
                  cacheHeight: 300,
                  key: ValueKey(profilePictureUrl),
                  headers: const {
                    'Cache-Control': 'no-cache',
                    'Pragma': 'no-cache',
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;

                    // Enhanced loading state with shimmer effect
                    return Shimmer.fromColors(
                      baseColor:
                          isDarkMode ? Colors.white10 : Colors.grey.shade200,
                      highlightColor:
                          isDarkMode ? Colors.white24 : Colors.grey.shade100,
                      child: Container(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade300,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading profile image: $error');
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        setState(() {});
                      }
                    });
                    return _buildAvatarFallback();
                  },
                )
              else
                _buildAvatarFallback(),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    // Dynamic sizing based on device height
    final isSmallDevice = size.height < 700;

    // Calculate optimal height for container - using more space
    final headerHeight = isSmallDevice
        ? min(size.height * 0.34, 270.0)
        : min(size.height * 0.38, 310.0);

    // Reduce top padding to move content up
    final topPadding = isSmallDevice ? 25 : 35;

    return Container(
      width: double.infinity,
      height: headerHeight,
      padding: EdgeInsets.only(
        top: padding.top + topPadding,
      ),
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none, // Avoid clipping shadows
        children: [
          // Subtle lighting effect for depth
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          // Profile content area - using FittedBox for better scaling
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;

                // Make profile picture larger
                final profileSize = isSmallDevice
                    ? min(availableHeight * 0.60, 130.0)
                    : min(availableHeight * 0.65, 150.0);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile picture with edit button
                    Center(
                      child: Hero(
                        tag: 'profilePicture',
                        child: GestureDetector(
                          onTap:
                              _isLoading ? null : _showImagePickerBottomSheet,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Profile picture
                              Container(
                                width: profileSize,
                                height: profileSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: isSmallDevice ? 2 : 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: _buildProfilePictureContent(),
                              ),

                              // Camera icon - make slightly larger
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: GestureDetector(
                                  onTap: _isLoading
                                      ? null
                                      : _showImagePickerBottomSheet,
                                  child: Container(
                                    padding:
                                        EdgeInsets.all(isSmallDevice ? 7 : 9),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: isSmallDevice ? 14 : 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Spacing - minimal
                    SizedBox(height: isSmallDevice ? 8 : 12),

                    // Name with FittedBox for proper scaling - slightly smaller
                    Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: isSmallDevice ? 24 : 28,
                          maxWidth: size.width * 0.8,
                        ),
                        child: _userName.isEmpty
                            ? Shimmer.fromColors(
                                baseColor: Colors.white24,
                                highlightColor: Colors.white38,
                                child: Container(
                                  height: isSmallDevice ? 16 : 20,
                                  width: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _userName,
                                  style: TextStyle(
                                    fontSize: isSmallDevice ? 16 : 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(0, 1),
                                        blurRadius: 3,
                                        color: Colors.black.withOpacity(0.2),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                ),
                              ),
                      ),
                    ),

                    // Email component - only show if showEmail is true and we have email data
                    if (widget.showEmail &&
                        (_email.isNotEmpty || isSmallDevice))
                      Center(
                        child: Container(
                          margin: EdgeInsets.only(top: isSmallDevice ? 2 : 4),
                          constraints: BoxConstraints(
                            maxHeight: isSmallDevice ? 24 : 28,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallDevice ? 10 : 14,
                                vertical: isSmallDevice ? 3 : 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: isSmallDevice ? 10 : 12,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  SizedBox(width: isSmallDevice ? 3 : 5),
                                  Text(
                                    _email.isEmpty ? 'Email' : _email,
                                    style: TextStyle(
                                      fontSize: isSmallDevice ? 10 : 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.95),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
