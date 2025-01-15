import 'dart:io';
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

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    _loadUserData();
    _loadBankAccounts();
    _loadAccountData();
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

  Future<File?> _cropImage(String imagePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      maxWidth: 1024,
      maxHeight: 1024,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile Picture',
          toolbarColor: Theme.of(context).primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Profile Picture',
          aspectRatioLockEnabled: true,
          minimumAspectRatio: 1.0,
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (image != null) {
        final File? croppedImage = await _cropImage(image.path);
        if (croppedImage == null) {
          return;
        }

        final storageService =
            Provider.of<StorageService>(context, listen: false);
        final supabaseStorage =
            Provider.of<SupabaseStorageService>(context, listen: false);
        final profileProvider =
            Provider.of<ProfileProvider>(context, listen: false);

        final userId = storageService.getUserId();
        if (userId == null) {
          throw Exception('Not logged in. Please log in again.');
        }

        final url =
            await supabaseStorage.uploadProfilePicture(userId, croppedImage);

        if (url != null) {
          if (!mounted) return;

          await profileProvider.updateProfilePicture(url);

          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          haptics.Haptics.vibrate(haptics.HapticsType.light);
        } else {
          throw Exception(
              'Failed to upload profile picture. Please try again.');
        }
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
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
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: 32,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDarkMode ? const Color(0xFF1A2942) : const Color(0xFF2196F3),
            isDarkMode
                ? const Color(0xFF1A2942).withOpacity(0.85)
                : const Color(0xFF64B5F6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 24,
            ),
            child: Row(
              children: [
                _buildHeaderButton(
                  icon: Icons.arrow_back,
                  onTap: () {
                    haptics.Haptics.vibrate(haptics.HapticsType.light);
                    Navigator.pop(context);
                  },
                ),
                const Expanded(
                  child: Text(
                    'Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: _buildProfilePicture(),
          ),
          const SizedBox(height: 20),
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Text(
              _email,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDarkMode ? Colors.white : const Color(0xFF2196F3),
                  size: 22,
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
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDarkMode ? Colors.white70 : Colors.black45,
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDestructive
                ? (isDarkMode
                    ? Colors.red.withOpacity(0.15)
                    : Colors.red.withOpacity(0.08))
                : (isDarkMode
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFF2196F3).withOpacity(0.08)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive
                  ? (isDarkMode
                      ? Colors.red.withOpacity(0.3)
                      : Colors.red.withOpacity(0.2))
                  : (isDarkMode
                      ? Colors.white.withOpacity(0.15)
                      : const Color(0xFF2196F3).withOpacity(0.15)),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? (isDarkMode
                          ? Colors.red.withOpacity(0.2)
                          : Colors.red.withOpacity(0.1))
                      : (isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : const Color(0xFF2196F3).withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isDestructive
                      ? Colors.red
                      : (isDarkMode ? Colors.white : const Color(0xFF2196F3)),
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
                        color: isDestructive
                            ? Colors.red
                            : (isDarkMode ? Colors.white : Colors.black87),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 13,
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
                    : (isDarkMode ? Colors.white70 : Colors.black45),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankAccountCard(BankAccount account) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.accountName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${account.accountType} - ${account.accountSubtype}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '**** ${account.accountMask}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isDarkMode ? Colors.white70 : const Color(0xFF2196F3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceInfo(
                'Available',
                account.availableBalance,
                account.currency,
                isDarkMode,
              ),
              _buildBalanceInfo(
                'Current',
                account.currentBalance,
                account.currency,
                isDarkMode,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFF2196F3).withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: isDarkMode ? Colors.white60 : const Color(0xFF2196F3),
                ),
                const SizedBox(width: 4),
                Text(
                  'Added on ${account.createdAt.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDarkMode ? Colors.white60 : const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo(
      String label, double amount, String currency, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${currency.toUpperCase()} ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBankAccountSection() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    if (_isLoadingBankAccounts) {
      return FadeIn(
        duration: const Duration(milliseconds: 300),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
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
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode ? Colors.white : const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Loading bank details...',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_bankAccounts == null || _bankAccounts!.isEmpty) {
      return FadeInUp(
        duration: const Duration(milliseconds: 400),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF2196F3),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Bank Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.03)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: isDarkMode
                              ? Colors.white70
                              : const Color(0xFF2196F3),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'No bank account connected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Connect your bank account to start using all features',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          haptics.Haptics.vibrate(haptics.HapticsType.light);
                          // Navigate to bank connection flow
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : const Color(0xFF2196F3),
                          foregroundColor:
                              isDarkMode ? Colors.white : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Connect Bank Account',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
      );
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.account_balance,
                        color:
                            isDarkMode ? Colors.white : const Color(0xFF2196F3),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Connected Accounts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_bankAccounts?.length ?? 0} Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF2196F3),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...(_bankAccounts ?? [])
                .map((account) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildBankAccountCard(account),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.settings,
                  color: isDarkMode ? Colors.white : const Color(0xFF2196F3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsGroup(
            title: 'Account',
            children: [
              _buildSettingTile(
                icon: Icons.person_outline,
                title: 'Personal Information',
                subtitle: 'Manage your personal details',
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
                title: 'Security',
                subtitle: 'Manage your security settings',
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
          const SizedBox(height: 24),
          _buildSettingsGroup(
            title: 'Preferences',
            children: [
              _buildSettingTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Configure your notifications',
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
              _buildSettingTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Toggle dark mode appearance',
                trailing: Switch.adaptive(
                  value: isDarkMode,
                  activeColor: const Color(0xFF2196F3),
                  onChanged: (value) {
                    haptics.Haptics.vibrate(haptics.HapticsType.light);
                    Provider.of<ThemeProvider>(context, listen: false)
                        .toggleTheme();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildActionButton(
            icon: Icons.support_outlined,
            title: 'Help & Support',
            subtitle: 'Get help with your account',
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
            title: 'Log Out',
            subtitle: 'Sign out of your account',
            isDestructive: true,
            onTap: () async {
              haptics.Haptics.vibrate(haptics.HapticsType.heavy);
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBankAccountSection(),
                  _buildSettingsSection(),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
