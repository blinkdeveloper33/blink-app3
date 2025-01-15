import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:animate_do/animate_do.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _hasChanges = false;

  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  late AnimationController _saveButtonController;
  late Animation<double> _saveButtonAnimation;
  late AnimationController _fieldFocusController;
  late Animation<double> _fieldScaleAnimation;
  late Animation<double> _toggleAnimation;

  final Map<String, FocusNode> _focusNodes = {
    'currentPassword': FocusNode(),
    'newPassword': FocusNode(),
    'confirmPassword': FocusNode(),
  };

  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _setupFocusNodes();
    _setupAnimations();
    _setupControllerListeners();
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

    _toggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fieldFocusController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _setupFocusNodes() {
    _focusNodes.forEach((key, node) {
      node.addListener(() {
        setState(() {});
      });
    });
  }

  void _setupControllerListeners() {
    void listener() {
      final hasInput = _currentPasswordController.text.isNotEmpty ||
          _newPasswordController.text.isNotEmpty ||
          _confirmPasswordController.text.isNotEmpty;

      if (hasInput != _hasChanges) {
        setState(() {
          _hasChanges = hasInput;
        });

        if (hasInput) {
          _saveButtonController.repeat(reverse: true);
        } else {
          _saveButtonController.stop();
          _saveButtonController.reset();
        }
      }
    }

    _currentPasswordController.addListener(listener);
    _newPasswordController.addListener(listener);
    _confirmPasswordController.addListener(listener);
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    haptics.Haptics.vibrate(haptics.HapticsType.medium);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.updateUserProfile({
        'current_password': _currentPasswordController.text,
        'new_password': _newPasswordController.text,
      });

      if (response['success'] == true) {
        if (!mounted) return;

        // Clear the form
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

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
                const Text('Password updated successfully'),
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Failed to update password: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      haptics.Haptics.vibrate(haptics.HapticsType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final isFocused = focusNode.hasFocus;

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
                  ? (isDarkMode ? Colors.white : const Color(0xFF2196F3))
                  : (isDarkMode ? Colors.white70 : Colors.black87),
            ),
            child: Text(label),
          ),
          const SizedBox(height: 8),
          ScaleTransition(
            scale: _fieldScaleAnimation,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      if (isFocused)
                        BoxShadow(
                          color: (isDarkMode
                                  ? Colors.white24
                                  : const Color(0xFF2196F3))
                              .withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    obscureText: !showPassword,
                    validator: validator,
                    onTap: () {
                      _fieldFocusController.forward();
                      haptics.Haptics.vibrate(haptics.HapticsType.light);
                    },
                    onEditingComplete: () {
                      _fieldFocusController.reverse();
                    },
                    style: GoogleFonts.inter(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.white.withOpacity(isFocused ? 0.08 : 0.05)
                          : Colors.grey.withOpacity(isFocused ? 0.15 : 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.3)
                              : const Color(0xFF2196F3),
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.red.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.red.withOpacity(0.8),
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isFocused ? 1.0 : 0.7,
                        child: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: isDarkMode
                                ? Colors.white
                                    .withOpacity(isFocused ? 0.9 : 0.5)
                                : Colors.grey
                                    .withOpacity(isFocused ? 0.9 : 0.5),
                            size: 20,
                          ),
                          onPressed: () {
                            onToggleVisibility();
                            haptics.Haptics.vibrate(haptics.HapticsType.light);
                          },
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
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
                            : const Color(0xFF2196F3).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: isDarkMode
                            ? Colors.white70
                            : const Color(0xFF2196F3),
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

  Widget _buildSecurityOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? (isDarkMode
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFF2196F3).withOpacity(0.3))
              : (isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2)),
        ),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: value
                  ? const Color(0xFF2196F3).withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: value
                  ? (isDarkMode
                      ? Colors.white.withOpacity(0.15)
                      : const Color(0xFF2196F3).withOpacity(0.15))
                  : (isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: value
                  ? (isDarkMode ? Colors.white : const Color(0xFF2196F3))
                  : (isDarkMode ? Colors.white70 : Colors.grey),
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
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: value ? 1.05 : 1.0,
            child: Switch.adaptive(
              value: value,
              onChanged: (newValue) {
                haptics.Haptics.vibrate(haptics.HapticsType.light);
                onChanged(newValue);
              },
              activeColor: const Color(0xFF2196F3),
              activeTrackColor: const Color(0xFF2196F3).withOpacity(0.3),
            ),
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
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? const Color(0xFF1A2942) : const Color(0xFF2196F3),
        elevation: 0,
        title: Text(
          'Security',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            haptics.Haptics.vibrate(haptics.HapticsType.light);
            if (_hasChanges) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Unsaved Changes',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  content: Text(
                    'You have unsaved changes. Do you want to discard them?',
                    style: GoogleFonts.inter(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Discard',
                        style: GoogleFonts.inter(color: Colors.red),
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
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    'Change Password',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildPasswordField(
                            label: 'Current Password',
                            controller: _currentPasswordController,
                            focusNode: _focusNodes['currentPassword']!,
                            showPassword: _showCurrentPassword,
                            onToggleVisibility: () {
                              setState(() {
                                _showCurrentPassword = !_showCurrentPassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your current password';
                              }
                              return null;
                            },
                          ),
                          _buildPasswordField(
                            label: 'New Password',
                            controller: _newPasswordController,
                            focusNode: _focusNodes['newPassword']!,
                            showPassword: _showNewPassword,
                            onToggleVisibility: () {
                              setState(() {
                                _showNewPassword = !_showNewPassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a new password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                            helperText: 'Must be at least 8 characters long',
                          ),
                          _buildPasswordField(
                            label: 'Confirm New Password',
                            controller: _confirmPasswordController,
                            focusNode: _focusNodes['confirmPassword']!,
                            showPassword: _showConfirmPassword,
                            onToggleVisibility: () {
                              setState(() {
                                _showConfirmPassword = !_showConfirmPassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your new password';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ScaleTransition(
                            scale: _saveButtonAnimation,
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  if (_hasChanges)
                                    BoxShadow(
                                      color: (isDarkMode
                                              ? Colors.white24
                                              : const Color(0xFF2196F3))
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _hasChanges && !_isLoading
                                    ? _changePassword
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : const Color(0xFF2196F3),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: isDarkMode
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.withOpacity(0.1),
                                  elevation: _hasChanges ? 4 : 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
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
                                            const Icon(Icons.lock_outline,
                                                size: 20),
                                            const SizedBox(width: 8),
                                          ],
                                          Text(
                                            _hasChanges
                                                ? 'Update Password'
                                                : 'No Changes',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    'Security Settings',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: _buildSecurityOption(
                    title: 'Two-Factor Authentication',
                    subtitle: 'Add an extra layer of security to your account',
                    icon: Icons.security,
                    value: _twoFactorEnabled,
                    onChanged: (value) {
                      setState(() {
                        _twoFactorEnabled = value;
                      });
                    },
                  ),
                ),
                FadeInUp(
                  duration: const Duration(milliseconds: 700),
                  child: _buildSecurityOption(
                    title: 'Biometric Authentication',
                    subtitle: 'Use fingerprint or face ID to log in',
                    icon: Icons.fingerprint,
                    value: _biometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        _biometricEnabled = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _saveButtonController.dispose();
    _fieldFocusController.dispose();
    _focusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }
}
