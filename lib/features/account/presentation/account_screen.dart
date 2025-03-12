import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:blink_app/services/supabase_storage_service.dart';
import 'package:blink_app/widgets/glass_container.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:blink_app/features/notifications/notifications.dart';
import 'package:blink_app/providers/profile_provider.dart';
import 'package:blink_app/features/account/presentation/personal_information_screen.dart';
import 'package:blink_app/features/account/presentation/security_screen.dart';
import 'package:blink_app/features/account/presentation/help_support_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart' as ui;
import 'package:blink_app/features/account/presentation/app_settings_screen.dart';
import 'package:blink_app/utils/temp_localizations.dart'; // Added temporary localization
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:blink_app/config/api_config.dart';

class BankAccount {
  final String bankAccountId;
  final String accountName;
  final String accountType;
  final String accountSubtype;
  final String accountMask;
  final double availableBalance;
  final double currentBalance;
  final String currency;
  final DateTime createdAt;
  final String cursor;

  BankAccount({
    required this.bankAccountId,
    required this.accountName,
    required this.accountType,
    required this.accountSubtype,
    required this.accountMask,
    required this.availableBalance,
    required this.currentBalance,
    required this.currency,
    required this.createdAt,
    required this.cursor,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      bankAccountId: json['bankAccountId'] as String,
      accountName: json['accountName'] as String,
      accountType: json['accountType'] as String,
      accountSubtype: json['accountSubtype'] as String,
      accountMask: json['accountMask'] as String,
      availableBalance: (json['availableBalance'] as num).toDouble(),
      currentBalance: (json['currentBalance'] as num).toDouble(),
      currency: json['currency'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      cursor: json['cursor'] as String,
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoading = false;
  String _userName = '';
  String _email = '';
  List<BankAccount>? _bankAccounts;
  bool _isLoadingBankAccounts = false;
  Map<String, dynamic>? _accountData;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  final ImagePicker _imagePicker = ImagePicker();
  final ImageCropper _imageCropper = ImageCropper();

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _loadUserProfileFromAPI();
    _loadBankAccountsFromAPI();
    _loadAccountData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  Future<void> _loadUserProfileFromAPI() async {
    try {
      debugPrint('Fetching user profile from API...');
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

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

          if (mounted) {
            setState(() {
              _userName =
                  '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                      .trim();
              _email = userData['email'] ?? '';
              debugPrint('Loaded user profile: $_userName, $_email');
            });
          }
        } else {
          debugPrint('User profile API returned success=false or no data');
          _loadUserData(); // Fall back to local storage
        }
      } else {
        debugPrint('Failed to get user profile: HTTP ${response.statusCode}');
        _loadUserData(); // Fall back to local storage
      }
    } catch (e) {
      debugPrint('Error loading user profile from API: $e');
      _loadUserData(); // Fall back to local storage
    }
  }

  Future<void> _loadBankAccountsFromAPI() async {
    if (mounted) {
      setState(() {
        _isLoadingBankAccounts = true;
      });
    }

    try {
      debugPrint('Fetching bank accounts from API...');
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/bank-accounts/plaid-items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final accountsData = responseData['data'] as List;

          if (mounted) {
            setState(() {
              _bankAccounts = accountsData.map((account) {
                return BankAccount(
                  bankAccountId: account['id'] ?? '',
                  accountName: account['account_name'] ??
                      account['institution_name'] ??
                      'Bank Account',
                  accountType: account['account_subtype'] ?? 'Unknown',
                  accountSubtype: account['account_subtype'] ?? '',
                  accountMask: account['account_mask'] ?? '****',
                  availableBalance:
                      double.tryParse(account['balance_available'] ?? '0') ??
                          0.0,
                  currentBalance:
                      double.tryParse(account['balance_current'] ?? '0') ?? 0.0,
                  currency: account['iso_currency_code'] ?? 'USD',
                  createdAt: DateTime.tryParse(account['created_at'] ?? '') ??
                      DateTime.now(),
                  cursor: account['id'] ?? '',
                );
              }).toList();
              _isLoadingBankAccounts = false;
              debugPrint(
                  'Loaded ${_bankAccounts?.length ?? 0} bank accounts from API');
            });
          }
        } else {
          debugPrint('Bank accounts API returned success=false or no data');
          if (mounted) {
            setState(() {
              _isLoadingBankAccounts = false;
            });
          }
          _loadBankAccounts(); // Fall back to old method
        }
      } else {
        debugPrint('Failed to get bank accounts: HTTP ${response.statusCode}');
        if (mounted) {
          setState(() {
            _isLoadingBankAccounts = false;
          });
        }
        _loadBankAccounts(); // Fall back to old method
      }
    } catch (e) {
      debugPrint('Error loading bank accounts from API: $e');
      if (mounted) {
        setState(() {
          _isLoadingBankAccounts = false;
        });
      }
      _loadBankAccounts(); // Fall back to old method
    }
  }

  Future<void> _loadUserData() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    setState(() {
      _userName =
          '${storageService.getFirstName() ?? ''} ${storageService.getLastName() ?? ''}'
              .trim();
      _email = storageService.getEmail() ?? '';
    });
  }

  Future<void> _loadProfilePicture() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final userId = storageService.getUserId();

    if (userId != null) {
      await profileProvider.loadProfilePicture(userId);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final croppedFile = await _imageCropper.cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70,
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

      // Create multipart request
      final url = Uri.parse('${ApiConfig.baseUrl}/api/users/profile-picture');
      final request = http.MultipartRequest('POST', url);

      // Add auth header
      request.headers['Authorization'] = 'Bearer $authToken';

      // Add file
      final file = await http.MultipartFile.fromPath(
          'profile_picture', croppedFile.path,
          contentType: MediaType('image', 'jpeg'));
      request.files.add(file);

      // Send request
      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Read response
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);

        // Get the profile picture URL from the response
        final String profilePictureUrl = data['profile_picture_url'];

        // Update profile provider
        if (mounted) {
          final profileProvider =
              Provider.of<ProfileProvider>(context, listen: false);
          profileProvider.updateProfilePicture(profilePictureUrl);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Profile picture updated successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Failed to update profile picture. Status: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error updating profile picture: ${e.toString()}')),
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

  Future<void> _loadBankAccounts() async {
    if (mounted) {
      setState(() {
        _isLoadingBankAccounts = true;
      });
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final detailedAccounts = await authService.getDetailedBankAccounts();

      if (mounted) {
        setState(() {
          _bankAccounts = detailedAccounts
              .map((account) => BankAccount.fromJson(account))
              .toList();
          _isLoadingBankAccounts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bank accounts: $e');
      if (mounted) {
        setState(() {
          _isLoadingBankAccounts = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bank accounts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAccountData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final accountData = await authService.getAccountData();

      if (mounted) {
        setState(() {
          _accountData = accountData;
        });
      }
    } catch (e) {
      debugPrint('Error loading account data: $e');
    }
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

  Widget _buildProfilePicture() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Hero(
      tag: 'profilePicture',
      child: GestureDetector(
        onTap: _isLoading
            ? null
            : () {
                haptics.Haptics.vibrate(haptics.HapticsType.light);
                _showImagePickerBottomSheet();
              },
        child: Stack(
          children: [
            Consumer<ProfileProvider>(
              builder: (context, profileProvider, child) {
                final profilePictureUrl = profileProvider.profilePictureUrl;
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
                    child: profilePictureUrl != null
                        ? Image.network(
                            profilePictureUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDarkMode
                                          ? Colors.white
                                          : const Color(0xFF2196F3),
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildAvatarFallback();
                            },
                          )
                        : _buildAvatarFallback(),
                  ),
                );
              },
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDarkMode ? Colors.white : const Color(0xFF2196F3),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white : const Color(0xFF2196F3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF1A2942) : Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: isDarkMode ? const Color(0xFF1A2942) : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildHeader() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final headerHeight = min(size.height * 0.38, 320.0);

    return Container(
      height: headerHeight,
      padding: EdgeInsets.only(top: padding.top + 56), // Add padding for AppBar
      child: Stack(
        children: [
          // Add gradient overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
          // Profile section
          LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              final profileSize = min(availableHeight * 0.45, 110.0);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile picture with edit button
                  Center(
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'profilePicture',
                          child: GestureDetector(
                            onTap:
                                _isLoading ? null : _showImagePickerBottomSheet,
                            child: Container(
                              width: profileSize,
                              height: profileSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 16,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: _buildProfilePictureContent(),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap:
                                _isLoading ? null : _showImagePickerBottomSheet,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF1A237E),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: min(availableHeight * 0.04, 16.0)),
                  // Name with shadow for better readability
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        _userName,
                        style: TextStyle(
                          fontSize: min(26, availableHeight * 0.1),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: min(availableHeight * 0.02, 8.0)),
                  // Enhanced email container
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 15,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _email,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        onPressed: () {
          haptics.Haptics.vibrate(haptics.HapticsType.light);
          Navigator.pop(context);
        },
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white.withOpacity(0.9),
          size: 20,
        ),
        splashRadius: 24,
      ),
    );
  }

  Widget _buildProfilePictureContent() {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final profilePictureUrl = profileProvider.profilePictureUrl;
        return ClipOval(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (profilePictureUrl != null)
                Image.network(
                  profilePictureUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.white.withOpacity(0.1),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  color: Colors.white.withOpacity(0.1),
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.white70,
                  ),
                ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDarkMode ? Colors.white60 : Colors.black45,
                    size: 24,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(
      {required String title, required List<Widget> children}) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDarkMode ? Colors.white60 : Colors.grey[700],
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingsSection() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.settings,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  localizations.settings,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          _buildSettingsGroup(
            title: localizations.account,
            children: [
              _buildSettingTile(
                icon: Icons.person_outline,
                title: localizations.personalInformation,
                subtitle: localizations.managePersonalDetails,
                onTap: () {
                  haptics.Haptics.vibrate(haptics.HapticsType.light);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PersonalInformationScreen(),
                    ),
                  );
                },
              ),
              _buildSettingTile(
                icon: Icons.security_outlined,
                title: localizations.security,
                subtitle: localizations.manageSecuritySettings,
                onTap: () {
                  haptics.Haptics.vibrate(haptics.HapticsType.light);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecurityScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          _buildSettingsGroup(
            title: localizations.general,
            children: [
              _buildSettingTile(
                icon: Icons.notifications_outlined,
                title: localizations.notifications,
                subtitle: localizations.configureNotifications,
                onTap: () {
                  haptics.Haptics.vibrate(haptics.HapticsType.light);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountSection() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final localizations = AppLocalizations.of(context)!;

    if (_isLoadingBankAccounts) {
      return FadeIn(
        duration: const Duration(milliseconds: 300),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
            ),
            boxShadow: [
              if (!isDarkMode)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDarkMode ? Colors.white : Colors.black87,
                    ),
                    strokeWidth: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading Account Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bankAccount = _bankAccounts?.firstOrNull;

    if (bankAccount == null) {
      return FadeInUp(
        duration: const Duration(milliseconds: 400),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
            ),
            boxShadow: [
              if (!isDarkMode)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.bankAccount,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizations.connectToGetStarted,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.03)
                      : Colors.grey.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            localizations.accountConnectionRequired,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localizations.accountConnectionMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    haptics.Haptics.vibrate(haptics.HapticsType.light);
                    // TODO: Implement Plaid connection
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    localizations.connectBankAccount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            if (!isDarkMode)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.account_balance,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bankAccount.accountName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${bankAccount.accountType} Account',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '**** ${bankAccount.accountMask}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.03)
                    : Colors.grey.withOpacity(0.03),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.availableBalance,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '\$${bankAccount.availableBalance.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '.${bankAccount.availableBalance.toStringAsFixed(2).split('.')[1]}',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            localizations.connectedOn(DateFormat('MMM d, yyyy')
                                .format(bankAccount.createdAt)),
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  isDarkMode ? Colors.white60 : Colors.black54,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.support_outlined,
            title: localizations.helpAndSupport,
            subtitle: localizations.getHelpWithAccount,
            onTap: () {
              haptics.Haptics.vibrate(haptics.HapticsType.light);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.logout,
            title: localizations.logOut,
            subtitle: localizations.signOutOfAccount,
            isDestructive: true,
            onTap: () async {
              haptics.Haptics.vibrate(haptics.HapticsType.heavy);
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/auth',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDestructive
              ? (isDarkMode
                  ? Colors.red.withOpacity(0.1)
                  : Colors.red.withOpacity(0.05))
              : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDestructive
                ? (isDarkMode
                    ? Colors.red.withOpacity(0.2)
                    : Colors.red.withOpacity(0.1))
                : (isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2)),
          ),
          boxShadow: !isDarkMode && !isDestructive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? (isDarkMode
                            ? Colors.red.withOpacity(0.15)
                            : Colors.red.withOpacity(0.1))
                        : (isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isDestructive
                        ? Colors.red
                        : (isDarkMode ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDestructive
                              ? Colors.red
                              : (isDarkMode ? Colors.white : Colors.black87),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDestructive
                      ? Colors.red.withOpacity(0.7)
                      : (isDarkMode ? Colors.white60 : Colors.black45),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final appBarOpacity = (_scrollOffset / 100).clamp(0.0, 0.8);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor:
            (isDarkMode ? const Color(0xFF1A237E) : const Color(0xFF1A237E))
                .withOpacity(appBarOpacity),
        elevation: appBarOpacity > 0 ? 1 : 0,
        leadingWidth: 56,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: appBarOpacity * 10,
              sigmaY: appBarOpacity * 10,
            ),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _buildBackButton(),
        ),
        title: Text(
          localizations.account,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  haptics.Haptics.vibrate(haptics.HapticsType.light);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppSettingsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Enhanced background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.2, 0.5, 1.0],
                  colors: [
                    const Color(0xFF1A237E).withOpacity(0.95),
                    const Color(0xFF0D47A1).withOpacity(0.8),
                    isDarkMode
                        ? const Color(0xFF121212).withOpacity(0.95)
                        : const Color(0xFFF5F5F7).withOpacity(0.95),
                    isDarkMode
                        ? const Color(0xFF121212)
                        : const Color(0xFFF5F5F7),
                  ],
                ),
              ),
            ),
          ),
          // Subtle pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.02,
              child: CustomPaint(
                painter: PatternPainter(),
              ),
            ),
          ),
          // Main content
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                // Content sections with glass effect background
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: (isDarkMode ? Colors.white : Colors.black)
                        .withOpacity(0.03),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        _buildBankAccountSection(),
                        const SizedBox(height: 16),
                        _buildSettingsSection(),
                        const SizedBox(height: 16),
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final spacing = 20.0;
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(i, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
