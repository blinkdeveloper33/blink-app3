import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blink_app/features/auth/presentation/create_password_screen.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';

class AnimatedBubble extends StatefulWidget {
  final double size;
  final double initialX;
  final double initialY;
  final Duration duration;

  const AnimatedBubble({
    Key? key,
    required this.size,
    required this.initialX,
    required this.initialY,
    required this.duration,
  }) : super(key: key);

  @override
  State<AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<AnimatedBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _positionAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.initialX + _positionAnimation.value,
          top: widget.initialY + _positionAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(_opacityAnimation.value * 0.1),
            ),
          ),
        );
      },
    );
  }
}

class NewUserDataScreen extends StatefulWidget {
  final String email;

  const NewUserDataScreen({
    super.key,
    required this.email,
  });

  @override
  State<NewUserDataScreen> createState() => _NewUserDataScreenState();
}

class _NewUserDataScreenState extends State<NewUserDataScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _zipCodeController = TextEditingController();
  String? _selectedState;
  bool _acknowledgeAccuracy = false;
  bool _isSubmitting = false;
  int _currentStep = 0;

  late StorageService _storageService;
  final Logger _logger = Logger();

  final List<String> _states = [
    'Nevada',
    'Missouri',
    'Wisconsin',
    'Kansas',
    'South Carolina',
    'Florida',
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  final List<String> animations = [
    'assets/animations/personal_info.json',
    'assets/animations/location.json',
    'assets/animations/confirmation.json',
  ];

  @override
  void initState() {
    super.initState();
    _storageService = Provider.of<StorageService>(context, listen: false);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _zipCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Onest',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          cursorColor: Colors.white,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Onest',
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontFamily: 'Onest',
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.white.withOpacity(0.7))
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'State',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Onest',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _selectedState != null
                  ? Colors.white.withAlpha(77)
                  : Colors.white.withAlpha(51),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedState,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white.withAlpha(179),
            ),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: InputBorder.none,
              hintText: 'Select your state',
              hintStyle: TextStyle(
                color: Colors.white.withAlpha(128),
                fontSize: 16,
                fontFamily: 'Onest',
              ),
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: Colors.white.withAlpha(179),
              ),
            ),
            dropdownColor: const Color(0xFF1E3A8A),
            items: _states.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Onest',
                  ),
                ),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your state';
              }
              return null;
            },
            onChanged: (String? newValue) {
              setState(() {
                _selectedState = newValue;
              });
            },
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Onest',
            ),
            menuMaxHeight: 300,
            isExpanded: true,
            elevation: 8,
            focusColor: Colors.transparent,
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acknowledgeAccuracy) {
      _showErrorDialog(
          'Please acknowledge that the information provided is accurate.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _storageService.setFirstName(_firstNameController.text.trim());
      await _storageService.setLastName(_lastNameController.text.trim());
      await _storageService.setState(_selectedState!);
      await _storageService.setZipcode(_zipCodeController.text.trim());
      await _storageService.setEmail(widget.email);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CreatePasswordScreen(
              email: widget.email,
            ),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error saving user data', error: e);
      if (mounted) {
        _showErrorDialog('An error occurred while saving your information.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF061535),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Error',
            style: TextStyle(
              color: Colors.redAccent,
              fontFamily: 'Onest',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Onest',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF2196F3),
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: _acknowledgeAccuracy
                  ? const Color(0xFF2196F3)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _acknowledgeAccuracy
                    ? const Color(0xFF2196F3)
                    : Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Checkbox(
              value: _acknowledgeAccuracy,
              onChanged: (bool? value) {
                setState(() {
                  _acknowledgeAccuracy = value ?? false;
                });
              },
              fillColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return const Color(0xFF2196F3);
                  }
                  return Colors.transparent;
                },
              ),
              checkColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'I acknowledge that all information provided is accurate and true.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontFamily: 'Onest',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          foregroundColor: const Color(0xFF1E3A8A),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFF1E3A8A)),
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(
                  fontFamily: 'Onest',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => Container(
            width: index == _currentStep ? 32 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: index == _currentStep
                  ? Colors.white
                  : index < _currentStep
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white.withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.25, 0.0),
          end: Offset.zero,
        ).animate(_fadeInAnimation),
        child: Column(
          children: [
            Lottie.asset(
              animations[_currentStep],
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            _buildStepSpecificContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepSpecificContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getStepInstructions(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontFamily: 'Onest',
              height: 1.5,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 24),
          _buildStepFields(),
        ],
      ),
    );
  }

  Widget _buildStepFields() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'First Name',
              controller: _firstNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your first name';
                }
                return null;
              },
              hintText: 'Enter your first name',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Last Name',
              controller: _lastNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your last name';
                }
                return null;
              },
              hintText: 'Enter your last name',
              prefixIcon: Icons.person_outline,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownField(),
            const SizedBox(height: 16),
            Text(
              '* Your state helps us provide relevant services and improve your experience',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontFamily: 'Onest',
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'ZIP Code',
              controller: _zipCodeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your ZIP code';
                }
                if (value.length != 5) {
                  return 'ZIP code must be 5 digits';
                }
                return null;
              },
              hintText: 'Enter your ZIP code',
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 8),
            Text(
              '* Your ZIP code helps us connect you with nearby services',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontFamily: 'Onest',
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildCheckbox(),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          TextButton(
            onPressed: () {
              setState(() {
                _currentStep--;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back,
                  color: Colors.white.withOpacity(0.9),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Previous',
                  style: TextStyle(
                    fontFamily: 'Onest',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox(width: 80),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (_currentStep < 2) {
                  setState(() {
                    _currentStep++;
                  });
                } else {
                  _submitForm();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A8A),
              backgroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentStep == 2 ? 'Submit' : 'Next',
                  style: const TextStyle(
                    fontFamily: 'Onest',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_currentStep < 2) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF1E3A8A),
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarBrightness:
            Brightness.dark, // For iOS: dark background = white content
        statusBarIconBrightness: Brightness.light, // For Android: white icons
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E3A8A),
                Color(0xFF2563EB),
              ],
              stops: [0.0, 1.0],
            ),
          ),
          child: Column(
            children: [
              // Fixed Header
              Container(
                color: const Color(0xFF1E3A8A).withOpacity(0.95),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 24, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context)
                              .pushReplacementNamed('/auth'),
                          tooltip: 'Go Back',
                        ),
                        Hero(
                          tag: 'logo',
                          child: Image.asset(
                            'assets/images/blink_logo_white.png',
                            height: 23,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          FadeInLeft(
                            duration: const Duration(milliseconds: 600),
                            child: Text(
                              _getStepTitle(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontFamily: 'Onest',
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeInLeft(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 200),
                            child: Text(
                              _getStepSubtitle(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 15,
                                fontFamily: 'Onest',
                                height: 1.5,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildStepContent(),
                          const SizedBox(height: 32),
                          FadeInUp(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 200),
                            child: _buildProgressIndicator(),
                          ),
                          const SizedBox(height: 24),
                          FadeInUp(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 400),
                            child: _buildNavigationButtons(),
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
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Create Your Profile';
      case 1:
        return 'Set Your Location';
      case 2:
        return 'Final Step';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Help us personalize your experience by sharing your name';
      case 1:
        return 'Choose your location to access relevant features and services';
      case 2:
        return 'Confirm your details to complete your account setup';
      default:
        return '';
    }
  }

  String _getStepInstructions() {
    switch (_currentStep) {
      case 0:
        return 'Please enter your first and last name as they appear on your official documents. This helps us maintain a secure and trustworthy community.';
      case 1:
        return 'Select your state to help us provide you with location-specific services and connect you with nearby users. Your location information is securely stored.';
      case 2:
        return 'Enter your ZIP code and verify that all provided information is accurate. This information helps us enhance your experience and ensure account security.';
      default:
        return '';
    }
  }
}
