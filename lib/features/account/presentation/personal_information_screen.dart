import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:blink_app/providers/color_palette_provider.dart';
import 'package:blink_app/providers/profile_provider.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:animate_do/animate_do.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:blink_app/config/api_config.dart';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:local_auth/local_auth.dart';

// Define an animated emoji for profile information
// final profileEmojiData = AnimatedEmojiData('1f60e', name: 'sunglasses-face');

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isRequestingOtp = false;
  bool _isVerifyingOtp = false;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _stateController;
  late TextEditingController _zipcodeController;
  late TextEditingController _otpController;
  late AnimationController _saveButtonController;
  late Animation<double> _saveButtonAnimation;
  final ImagePicker _imagePicker = ImagePicker();
  final ImageCropper _imageCropper = ImageCropper();
  final LocalAuthentication _localAuth = LocalAuthentication();

  final Map<String, FocusNode> _focusNodes = {
    'firstName': FocusNode(),
    'lastName': FocusNode(),
    'email': FocusNode(),
    'state': FocusNode(),
    'zipcode': FocusNode(),
  };

  bool _hasChanges = false;

  late AnimationController _fieldFocusController;
  late Animation<double> _fieldScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
    _loadProfilePicture();
    _setupFocusNodes();
    _setupAnimations();

    // Add listeners to detect changes
    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);
    _stateController.addListener(_onFieldChanged);
    _zipcodeController.addListener(_onFieldChanged);

    // Setup field focus animations
    _fieldFocusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fieldScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _fieldFocusController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _setupAnimations() {
    _saveButtonController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _saveButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _saveButtonController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _onFieldChanged() {
    final hasChanges =
        _firstNameController.text != _initialValues['firstName'] ||
            _lastNameController.text != _initialValues['lastName'] ||
            _stateController.text != _initialValues['state'] ||
            _zipcodeController.text != _initialValues['zipcode'];

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });

      if (hasChanges) {
        _saveButtonController.repeat(reverse: true);
      } else {
        _saveButtonController.stop();
        _saveButtonController.reset();
      }
    }
  }

  void _setupFocusNodes() {
    _focusNodes.forEach((key, node) {
      node.addListener(() {
        setState(() {});
      });
    });
  }

  late Map<String, String?> _initialValues = {};

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _stateController = TextEditingController();
    _zipcodeController = TextEditingController();
    _otpController = TextEditingController();
  }

  Future<void> _loadUserData() async {
    final storageService = Provider.of<StorageService>(context, listen: false);

    setState(() {
      _firstNameController.text = storageService.getFirstName() ?? '';
      _lastNameController.text = storageService.getLastName() ?? '';
      _emailController.text = storageService.getEmail() ?? '';
      _stateController.text = storageService.getState() ?? '';
      _zipcodeController.text = storageService.getZipcode() ?? '';

      _initialValues = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'state': _stateController.text,
        'zipcode': _zipcodeController.text,
      };
    });
  }

  Future<void> _loadProfilePicture() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final userId = storageService.getUserId();

    if (userId != null) {
      await profileProvider.loadProfilePicture(userId);
      // Extract colors after loading the profile picture
      final colorPaletteProvider =
          Provider.of<ColorPaletteProvider>(context, listen: false);
      if (profileProvider.profilePictureUrl != null) {
        colorPaletteProvider
            .extractColorsFromProfileImage(profileProvider.profilePictureUrl);
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
        _isUploadingImage = true;
      });

      // Get auth token
      final authService = Provider.of<AuthService>(context, listen: false);
      final String? authToken = await authService.getToken();
      if (authToken == null) {
        setState(() {
          _isUploadingImage = false;
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
      debugPrint('Sending profile picture to endpoint: $url');
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
            break; // Success, exit retry loop
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

          // Get the profile picture URL from the response
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

              // Extract colors from the new profile picture
              final colorPaletteProvider =
                  Provider.of<ColorPaletteProvider>(context, listen: false);
              colorPaletteProvider
                  .extractColorsFromProfileImage(profilePictureUrl);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Profile picture updated successfully!')),
              );
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
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    haptics.Haptics.vibrate(haptics.HapticsType.medium);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Format data according to backend API expectations
      final updateData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'state': _stateController.text,
        'zipCode': _zipcodeController.text,
      };

      final response = await authService.updateUserProfile(updateData);

      if (response['success'] == true) {
        if (!mounted) return;

        // Update local storage
        final storageService =
            Provider.of<StorageService>(context, listen: false);
        await storageService.setFirstName(_firstNameController.text);
        await storageService.setLastName(_lastNameController.text);
        await storageService.setState(_stateController.text);
        await storageService.setZipcode(_zipcodeController.text);

        // Update initial values
        _initialValues = {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'state': _stateController.text,
          'zipcode': _zipcodeController.text,
        };

        setState(() {
          _hasChanges = false;
        });
        _saveButtonController.stop();
        _saveButtonController.reset();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Profile updated successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        haptics.Haptics.vibrate(haptics.HapticsType.success);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          response['message'] ?? 'Failed to update profile')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        haptics.Haptics.vibrate(haptics.HapticsType.error);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Failed to update profile: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      haptics.Haptics.vibrate(haptics.HapticsType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required FocusNode focusNode,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? helperText,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final colorPaletteProvider = Provider.of<ColorPaletteProvider>(context);
    final isFocused = focusNode.hasFocus;

    // Get a color from the palette for accents
    final accentColor = isDarkMode
        ? Colors.white.withOpacity(0.8)
        : colorPaletteProvider.hasCustomColors
            ? colorPaletteProvider.startColor
            : const Color(0xFF2196F3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(vertical: isFocused ? 12 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: GoogleFonts.inter(
              fontSize: isFocused ? 15 : 14,
              fontWeight: isFocused ? FontWeight.w600 : FontWeight.w500,
              color: isFocused
                  ? (isDarkMode ? Colors.white : accentColor)
                  : (isDarkMode ? Colors.white70 : Colors.black87),
            ),
            child: Text(label),
          ),
          const SizedBox(height: 8),
          ScaleTransition(
            scale: _fieldScaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (isFocused)
                    BoxShadow(
                      color: (isDarkMode ? Colors.white24 : accentColor)
                          .withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  TextFormField(
                    controller: controller,
                    enabled: enabled,
                    focusNode: focusNode,
                    validator: validator,
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    style: GoogleFonts.inter(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    onTap: () {
                      _fieldFocusController.forward();
                      haptics.Haptics.vibrate(haptics.HapticsType.light);
                    },
                    onEditingComplete: () {
                      TextInput.finishAutofillContext();
                      _fieldFocusController.reverse();
                    },
                    autocorrect: false,
                    enableSuggestions: false,
                    enableInteractiveSelection: true,
                    autofillHints: _getAutofillHints(label),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.white.withOpacity(isFocused ? 0.08 : 0.05)
                          : Colors.grey.withOpacity(isFocused ? 0.15 : 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.3)
                              : accentColor,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.red.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.red.withOpacity(0.8),
                          width: 1.5,
                        ),
                      ),
                      helperText: helperText,
                      helperStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                      ),
                      errorStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.red.withOpacity(0.8),
                      ),
                      prefixText: prefixText,
                      prefixStyle: GoogleFonts.inter(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        fontSize: 16,
                      ),
                      suffixIcon: suffixIcon,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                    ),
                  ),
                  if (isFocused)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: isDarkMode ? Colors.white70 : accentColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getAutofillHints(String label) {
    switch (label.toLowerCase()) {
      case 'first name':
        return [AutofillHints.givenName];
      case 'last name':
        return [AutofillHints.familyName];
      case 'email':
        return [AutofillHints.email];
      case 'state':
        return [AutofillHints.addressState];
      case 'zipcode':
        return [AutofillHints.postalCode];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final colorPaletteProvider = Provider.of<ColorPaletteProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10,
              sigmaY: 10,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? colorPaletteProvider.startColor.withOpacity(0.5)
                    : colorPaletteProvider.startColor.withOpacity(0.7),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Personal Information',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () {
            haptics.Haptics.vibrate(haptics.HapticsType.light);
            if (_hasChanges) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor:
                      isDarkMode ? const Color(0xFF1A2942) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Unsaved Changes',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  content: Text(
                    'You have unsaved changes. Do you want to discard them?',
                    style: GoogleFonts.inter(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: isDarkMode ? Colors.white60 : Colors.grey,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Discard',
                        style: GoogleFonts.inter(
                          color: Colors.red.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Stack(
        children: [
          // Dynamic gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: colorPaletteProvider.createGradient(isDarkMode),
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SafeArea(
              child: Column(
                children: [
                  // Add profile picture section
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          // Profile picture with edit button
                          Stack(
                            children: [
                              // Profile picture
                              GestureDetector(
                                onTap: _isUploadingImage
                                    ? null
                                    : _pickAndUploadImage,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: _isUploadingImage
                                        ? Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white.withOpacity(0.8),
                                              ),
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : profileProvider.profilePictureUrl !=
                                                null
                                            ? Image.network(
                                                profileProvider
                                                    .profilePictureUrl!,
                                                fit: BoxFit.cover,
                                                width: 120,
                                                height: 120,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Center(
                                                    child:
                                                        CircularProgressIndicator(
                                                      value: loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        Colors.white
                                                            .withOpacity(0.8),
                                                      ),
                                                      strokeWidth: 2,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    color: isDarkMode
                                                        ? Colors.grey[800]
                                                        : Colors.grey[300],
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 60,
                                                      color: isDarkMode
                                                          ? Colors.white
                                                              .withOpacity(0.7)
                                                          : Colors.grey[600],
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: isDarkMode
                                                    ? Colors.grey[800]
                                                    : Colors.grey[300],
                                                child: Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: isDarkMode
                                                      ? Colors.white
                                                          .withOpacity(0.7)
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                  ),
                                ),
                              ),
                              // Edit icon
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _isUploadingImage
                                      ? null
                                      : _pickAndUploadImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.white.withOpacity(0.2)
                                          : colorPaletteProvider.startColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDarkMode
                                            ? Colors.white.withOpacity(0.3)
                                            : Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Text to instruct users
                          Text(
                            'Tap to update your profile picture',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black.withOpacity(0.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.2),
                        ),
                        boxShadow: [
                          if (!isDarkMode)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header with Animated Emoji
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: AnimatedEmoji(
                                  AnimatedEmojis.sunglassesFace,
                                  size: 36,
                                  repeat: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Profile Details',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FadeInUp(
                                  duration: const Duration(milliseconds: 300),
                                  child: _buildTextField(
                                    label: 'First Name',
                                    controller: _firstNameController,
                                    enabled: true,
                                    focusNode: _focusNodes['firstName']!,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your first name';
                                      }
                                      return null;
                                    },
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z\s]'),
                                      ),
                                    ],
                                  ),
                                ),
                                FadeInUp(
                                  duration: const Duration(milliseconds: 400),
                                  child: _buildTextField(
                                    label: 'Last Name',
                                    controller: _lastNameController,
                                    enabled: true,
                                    focusNode: _focusNodes['lastName']!,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your last name';
                                      }
                                      return null;
                                    },
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z\s]'),
                                      ),
                                    ],
                                  ),
                                ),
                                FadeInUp(
                                  duration: const Duration(milliseconds: 500),
                                  child: _buildTextField(
                                    label: 'Email',
                                    controller: _emailController,
                                    enabled: false,
                                    focusNode: _focusNodes['email']!,
                                    keyboardType: TextInputType.emailAddress,
                                    helperText:
                                        'Contact support to change your email address',
                                    suffixIcon: Icon(
                                      Icons.lock_outline,
                                      size: 18,
                                      color: isDarkMode
                                          ? Colors.white60
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                FadeInUp(
                                  duration: const Duration(milliseconds: 600),
                                  child: _buildTextField(
                                    label: 'State',
                                    controller: _stateController,
                                    enabled: true,
                                    focusNode: _focusNodes['state']!,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your state';
                                      }

                                      // Check against allowed state values from backend
                                      final validStates = [
                                        'NV',
                                        'MO',
                                        'WI',
                                        'KS',
                                        'SC',
                                        'FL'
                                      ];
                                      if (!validStates
                                          .contains(value.toUpperCase())) {
                                        return 'Please enter a valid state code (NV, MO, WI, KS, SC, FL)';
                                      }

                                      return null;
                                    },
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z\s]'),
                                      ),
                                      TextInputFormatter.withFunction(
                                          (oldValue, newValue) {
                                        if (newValue.text.length > 2) {
                                          return oldValue;
                                        }
                                        return newValue.copyWith(
                                          text: newValue.text.toUpperCase(),
                                        );
                                      }),
                                    ],
                                    helperText:
                                        'Enter 2-letter state code (e.g., FL)',
                                  ),
                                ),
                                FadeInUp(
                                  duration: const Duration(milliseconds: 700),
                                  child: _buildTextField(
                                    label: 'Zipcode',
                                    controller: _zipcodeController,
                                    enabled: true,
                                    focusNode: _focusNodes['zipcode']!,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your zipcode';
                                      }

                                      // Validate zipcode format: 5 digits or 5+4 format
                                      final zipRegex =
                                          RegExp(r'^\d{5}(-\d{4})?$');
                                      if (!zipRegex.hasMatch(value)) {
                                        return 'Please enter a valid 5-digit zipcode';
                                      }

                                      return null;
                                    },
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(5),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                FadeInUp(
                                  duration: const Duration(milliseconds: 800),
                                  child: ScaleTransition(
                                    scale: _saveButtonAnimation,
                                    child: Container(
                                      width: double.infinity,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          if (_hasChanges)
                                            BoxShadow(
                                              color: (isDarkMode
                                                      ? Colors.white24
                                                      : colorPaletteProvider
                                                          .startColor)
                                                  .withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _hasChanges && !_isLoading
                                            ? _saveChanges
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDarkMode
                                              ? Colors.white.withOpacity(0.1)
                                              : colorPaletteProvider.startColor,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: isDarkMode
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.grey.withOpacity(0.1),
                                          elevation: _hasChanges ? 4 : 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    isDarkMode
                                                        ? Colors.white70
                                                        : Colors.white,
                                                  ),
                                                ),
                                              )
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  if (_hasChanges) ...[
                                                    const Icon(
                                                        Icons.save_outlined,
                                                        size: 20),
                                                    const SizedBox(width: 8),
                                                  ],
                                                  Text(
                                                    _hasChanges
                                                        ? 'Save Changes'
                                                        : 'No Changes',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      shadows: _hasChanges
                                                          ? [
                                                              Shadow(
                                                                offset:
                                                                    const Offset(
                                                                        0, 1),
                                                                blurRadius: 2,
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.2),
                                                              ),
                                                            ]
                                                          : null,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _stateController.dispose();
    _zipcodeController.dispose();
    _saveButtonController.dispose();
    _fieldFocusController.dispose();
    _focusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }
}
