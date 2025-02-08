import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:animate_do/animate_do.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _stateController;
  late TextEditingController _zipcodeController;
  late AnimationController _saveButtonController;
  late Animation<double> _saveButtonAnimation;

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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    haptics.Haptics.vibrate(haptics.HapticsType.medium);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final response = await authService.updateUserProfile({
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'state': _stateController.text,
        'zipcode': _zipcodeController.text,
      });

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
      }
    } catch (e) {
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
            child: AnimatedContainer(
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
              child: Stack(
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
                      _fieldFocusController.reverse();
                    },
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
                        horizontal: 16,
                        vertical: 16,
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
                          Icons.edit_outlined,
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
          'Personal Information',
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
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
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
                            color: isDarkMode ? Colors.white60 : Colors.grey,
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
                          helperText: 'Enter 2-letter state code (e.g., CA)',
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
                            if (value.length != 5) {
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
                                  ? _saveChanges
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
                                          const Icon(Icons.save_outlined,
                                              size: 20),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(
                                          _hasChanges
                                              ? 'Save Changes'
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
