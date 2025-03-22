import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'dart:async'; // Add async for timeout
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
import 'package:blink_app/providers/color_palette_provider.dart';
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
import 'package:shimmer/shimmer.dart'; // Add shimmer package for professional loading effects
import 'package:path_provider/path_provider.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:blink_app/features/account/presentation/components/profile_header.dart';
import 'package:blink_app/features/account/presentation/components/bank_account_section.dart';
import 'package:blink_app/features/account/presentation/components/settings_section.dart';
import 'package:blink_app/features/account/presentation/components/action_buttons.dart';

// Define a custom AnimatedEmojiData for the locked emoji
final lockedEmoji = AnimatedEmojiData('1f512', name: 'locked');

// Helper function to deserialize BankAccount
BankAccount bankAccountFromJson(Map<String, dynamic> json) {
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
  bool _isInitialLoad = true; // Track if this is the first load
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  final ImagePicker _imagePicker = ImagePicker();
  final ImageCropper _imageCropper = ImageCropper();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  // New method to handle initial data loading
  Future<void> _loadInitialData() async {
    // First try to load data from cache
    await _loadCachedUserData();
    await _loadCachedBankAccounts();

    // Extract colors from profile picture if available
    _extractColorsFromProfilePicture();

    // Then refresh data in the background
    _refreshDataInBackground();
  }

  // Load user data from cache first
  Future<void> _loadCachedUserData() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    // Load profile picture if available
    final userId = storageService.getUserId();
    if (userId != null) {
      await profileProvider.loadProfilePicture(userId);
    }

    // Set user data from local storage
    final cachedName =
        '${storageService.getFirstName() ?? ''} ${storageService.getLastName() ?? ''}'
            .trim();
    final cachedEmail = storageService.getEmail() ?? '';

    if (mounted && (cachedName.isNotEmpty || cachedEmail.isNotEmpty)) {
      setState(() {
        _userName = cachedName;
        _email = cachedEmail;
      });
    }
  }

  // Load bank accounts from cache
  Future<void> _loadCachedBankAccounts() async {
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final userPreferences = await storageService.getUserPreferences() ?? {};

      if (userPreferences.containsKey('bank_accounts_cache')) {
        final cachedAccounts =
            jsonDecode(userPreferences['bank_accounts_cache']);
        if (cachedAccounts is List && cachedAccounts.isNotEmpty) {
          if (mounted) {
            setState(() {
              _bankAccounts = cachedAccounts
                  .map((account) =>
                      bankAccountFromJson(account as Map<String, dynamic>))
                  .toList();
              _isInitialLoad = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cached bank accounts: $e');
    }
  }

  // Refresh data in background without showing loading indicators if we already have data
  Future<void> _refreshDataInBackground() async {
    // Only show loading indicators if this is the initial load
    if (_isInitialLoad) {
      if (mounted) {
        setState(() {
          _isLoadingBankAccounts = _bankAccounts == null;
        });
      }
    }

    // Refresh data from API
    await Future.wait([
      _loadUserProfileFromAPI(showLoading: _isInitialLoad),
      _loadBankAccountsFromAPI(showLoading: _isInitialLoad),
    ]);

    // Mark initial load as complete
    if (mounted && _isInitialLoad) {
      setState(() {
        _isInitialLoad = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Cancel the color extraction timer
    _colorExtractionTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });

    // Don't extract colors while scrolling to save resources
    if (!_isLoadingBankAccounts && !_isInitialLoad) {
      _debounceColorExtraction();
    }
  }

  // Debouncer for color extraction
  Timer? _colorExtractionTimer;

  void _debounceColorExtraction() {
    // If a timer is already active, cancel it
    if (_colorExtractionTimer?.isActive ?? false) {
      _colorExtractionTimer!.cancel();
    }

    // Set a new timer - only extract colors after scrolling stops for 500ms
    _colorExtractionTimer = Timer(const Duration(milliseconds: 500), () {
      _extractColorsFromProfilePicture();
    });
  }

  void _extractColorsFromProfilePicture() {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final colorPaletteProvider =
        Provider.of<ColorPaletteProvider>(context, listen: false);

    if (profileProvider.profilePictureUrl != null) {
      colorPaletteProvider
          .extractColorsFromProfileImage(profileProvider.profilePictureUrl);
    }
  }

  Future<void> _loadUserProfileFromAPI({bool showLoading = true}) async {
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
          final storageService =
              Provider.of<StorageService>(context, listen: false);

          if (mounted) {
            setState(() {
              _userName =
                  '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                      .trim();
              _email = userData['email'] ?? '';
              debugPrint('Updated user profile from API: $_userName, $_email');
            });
          }
        } else {
          debugPrint('User profile API returned success=false or no data');
          // Don't call _loadUserData() if we already have data and this is a background refresh
          if (showLoading || _userName.isEmpty) {
            await _loadUserData();
          }
        }
      } else {
        debugPrint('Failed to get user profile: HTTP ${response.statusCode}');
        // Don't call _loadUserData() if we already have data and this is a background refresh
        if (showLoading || _userName.isEmpty) {
          await _loadUserData();
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile from API: $e');
      // Don't call _loadUserData() if we already have data and this is a background refresh
      if (showLoading || _userName.isEmpty) {
        await _loadUserData();
      }
    }
  }

  Future<void> _loadBankAccountsFromAPI({bool showLoading = true}) async {
    if (mounted && showLoading) {
      setState(() {
        _isLoadingBankAccounts = true;
      });
    }

    try {
      debugPrint('Fetching bank accounts from API...');
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      final storageService =
          Provider.of<StorageService>(context, listen: false);

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
          final List<BankAccount> accounts = accountsData.map((account) {
            return BankAccount(
              bankAccountId: account['id'] ?? '',
              accountName: account['account_name'] ??
                  account['institution_name'] ??
                  'Bank Account',
              accountType: account['account_subtype'] ?? 'Unknown',
              accountSubtype: account['account_subtype'] ?? '',
              accountMask: account['account_mask'] ?? '****',
              availableBalance:
                  double.tryParse(account['balance_available'] ?? '0') ?? 0.0,
              currentBalance:
                  double.tryParse(account['balance_current'] ?? '0') ?? 0.0,
              currency: account['iso_currency_code'] ?? 'USD',
              createdAt: DateTime.tryParse(account['created_at'] ?? '') ??
                  DateTime.now(),
              cursor: account['id'] ?? '',
            );
          }).toList();

          if (mounted) {
            setState(() {
              _bankAccounts = accounts;
              _isLoadingBankAccounts = false;
              debugPrint(
                  'Updated ${_bankAccounts?.length ?? 0} bank accounts from API');
            });
          }

          // Cache the bank accounts data
          try {
            final userPreferences =
                await storageService.getUserPreferences() ?? {};
            userPreferences['bank_accounts_cache'] = jsonEncode(
              accounts
                  .map((account) => {
                        'bankAccountId': account.bankAccountId,
                        'accountName': account.accountName,
                        'accountType': account.accountType,
                        'accountSubtype': account.accountSubtype,
                        'accountMask': account.accountMask,
                        'availableBalance': account.availableBalance,
                        'currentBalance': account.currentBalance,
                        'currency': account.currency,
                        'createdAt': account.createdAt.toIso8601String(),
                        'cursor': account.cursor,
                      })
                  .toList(),
            );
            await storageService.setUserPreferences(userPreferences);
            debugPrint('Bank accounts cached successfully');
          } catch (e) {
            debugPrint('Error caching bank accounts: $e');
          }
        } else {
          debugPrint('Bank accounts API returned success=false or no data');
          if (mounted && showLoading) {
            setState(() {
              _isLoadingBankAccounts = false;
            });
          }
          // Only call fallback if we don't have data or if explicitly showing loading
          if (showLoading || _bankAccounts == null || _bankAccounts!.isEmpty) {
            await _loadBankAccounts();
          }
        }
      } else {
        debugPrint('Failed to get bank accounts: HTTP ${response.statusCode}');
        if (mounted && showLoading) {
          setState(() {
            _isLoadingBankAccounts = false;
          });
        }
        // Only call fallback if we don't have data or if explicitly showing loading
        if (showLoading || _bankAccounts == null || _bankAccounts!.isEmpty) {
          await _loadBankAccounts();
        }
      }
    } catch (e) {
      debugPrint('Error loading bank accounts from API: $e');
      if (mounted && showLoading) {
        setState(() {
          _isLoadingBankAccounts = false;
        });
      }
      // Only call fallback if we don't have data or if explicitly showing loading
      if (showLoading || _bankAccounts == null || _bankAccounts!.isEmpty) {
        await _loadBankAccounts();
      }
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
      // Extract colors after loading the profile picture
      _extractColorsFromProfilePicture();
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Limit image width
        maxHeight: 800, // Limit image height
        imageQuality: 60, // Reduce quality further
      );
      if (pickedFile == null) return;

      final croppedFile = await _imageCropper.cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 50, // Reduce quality for smaller file size
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
        debugPrint(
            'Sending profile picture upload request to ${ApiConfig.baseUrl}/api/user-profile/upload-profile-picture');

        // Implement retry logic with exponential backoff
        int retries = 3;
        http.StreamedResponse? streamedResponse;

        while (retries > 0) {
          try {
            // Send request with timeout
            streamedResponse = await client.send(request).timeout(
                const Duration(seconds: 60)); // 1 minute timeout per attempt
            break; // Success, exit retry loop
          } catch (e) {
            retries--;
            if (retries == 0) {
              // Re-throw on last attempt
              rethrow;
            }

            // Wait with exponential backoff
            final backoffSeconds = pow(2, 3 - retries).toInt();
            debugPrint(
                'Upload failed, retrying in $backoffSeconds seconds. ${retries} retries left.');
            await Future.delayed(Duration(seconds: backoffSeconds));
          }
        }

        if (streamedResponse == null) {
          throw Exception('Failed to upload after retry attempts');
        }

        debugPrint('Profile picture upload response received');
        final response = await http.Response.fromStream(streamedResponse);
        debugPrint('Response status: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseBody = response.body;
          debugPrint('Response body: $responseBody');

          Map<String, dynamic> data;
          try {
            data = jsonDecode(responseBody);
            debugPrint('Parsed JSON: $data');

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
              debugPrint('Profile picture URL: $profilePictureUrl');

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
          } catch (e) {
            debugPrint('Error parsing response: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Error processing server response: ${e.toString()}')),
              );
            }
          }
        } else {
          debugPrint(
              'Failed to upload profile picture: ${response.statusCode} - ${response.body}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Failed to update profile picture. Server returned ${response.statusCode}')),
            );
          }
        }
      } on TimeoutException {
        debugPrint('Profile picture upload timed out');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Connection timed out. Please try with a smaller image or check your network')),
          );
        }
      } catch (e) {
        debugPrint('Error in HTTP request: $e');
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
      debugPrint('Error updating profile picture: $e');
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
              .map((account) => bankAccountFromJson(account))
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final appBarOpacity = (_scrollOffset / 100).clamp(0.0, 0.8);
    final localizations = AppLocalizations.of(context)!;
    final colorPaletteProvider = Provider.of<ColorPaletteProvider>(context);

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
          // Enhanced background gradient - now using colors from profile picture
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: colorPaletteProvider.createGradient(isDarkMode),
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
                // Profile Header (in a centered container for proper alignment)
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: ProfileHeader(
                    onReload: _refreshDataInBackground,
                    userName: _userName,
                    email: _email,
                    showEmail: false,
                  ),
                ),

                // Content sections with glass effect background
                Container(
                  margin: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height < 700 ? 0 : 8),
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

                        // Bank Account Section
                        BankAccountSection(
                          bankAccounts: _bankAccounts,
                          isLoading: _isLoadingBankAccounts,
                          onConnectBankAccount: () {
                            // Implement Plaid connection
                          },
                        ),

                        const SizedBox(height: 16),

                        // Settings Section
                        const SettingsSection(),

                        const SizedBox(height: 16),

                        // Action Buttons
                        const ActionButtons(),

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
}
