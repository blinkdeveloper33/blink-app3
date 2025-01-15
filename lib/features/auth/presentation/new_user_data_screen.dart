import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blink_app/features/auth/presentation/create_password_screen.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

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
    'Alabama',
    'Alaska',
    'Arizona',
    'Arkansas',
    'California',
    'Colorado',
    'Connecticut',
    'Delaware',
    'Florida',
    'Georgia',
    'Hawaii',
    'Idaho',
    'Illinois',
    'Indiana',
    'Iowa',
    'Kansas',
    'Kentucky',
    'Louisiana',
    'Maine',
    'Maryland',
    'Massachusetts',
    'Michigan',
    'Minnesota',
    'Mississippi',
    'Missouri',
    'Montana',
    'Nebraska',
    'Nevada',
    'New Hampshire',
    'New Jersey',
    'New Mexico',
    'New York',
    'North Carolina',
    'North Dakota',
    'Ohio',
    'Oklahoma',
    'Oregon',
    'Pennsylvania',
    'Rhode Island',
    'South Carolina',
    'South Dakota',
    'Tennessee',
    'Texas',
    'Utah',
    'Vermont',
    'Virginia',
    'Washington',
    'West Virginia',
    'Wisconsin',
    'Wyoming'
  ];

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  final List<Color> _stepColors = [
    const Color(0xFF1E3A8A),
    const Color(0xFF2563EB),
  ];

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
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
              dropdownMenuTheme: DropdownMenuThemeData(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w500,
                ),
                menuStyle: MenuStyle(
                  backgroundColor:
                      MaterialStateProperty.all(const Color(0xFF1E3A8A)),
                  elevation: MaterialStateProperty.all(8),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedState,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your state';
                }
                return null;
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
                prefixIcon: Icon(
                  Icons.location_on,
                  color: Colors.white.withOpacity(0.7),
                ),
                suffixIcon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white.withOpacity(0.7),
                  size: 28,
                ),
              ),
              dropdownColor: const Color(0xFF1E3A8A),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Onest',
                fontWeight: FontWeight.w500,
              ),
              icon: const SizedBox.shrink(), // Hide default icon
              hint: Text(
                'Select State',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w500,
                ),
              ),
              menuMaxHeight: 300,
              isExpanded: true,
              items: _states.map((String state) {
                return DropdownMenuItem<String>(
                  value: state,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      state,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedState = newValue;
                });
              },
            ),
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
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
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
    switch (_currentStep) {
      case 0:
        return Column(
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
            const SizedBox(height: 16),
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
        return _buildDropdownField();
      case 2:
        return Column(
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
            const SizedBox(height: 24),
            _buildCheckbox(),
            const SizedBox(height: 32),
            _buildContinueButton(),
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
                blurRadius: 20,
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
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
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
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
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
    final bubbles = _generateBubbles();
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF2563EB),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Animated Bubbles
            ...bubbles,
            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: 'Go Back',
                            ),
                            Hero(
                              tag: 'logo',
                              child: Image.asset(
                                'assets/images/blink_logo_white.png',
                                height: 42,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        FadeInLeft(
                          duration: const Duration(milliseconds: 600),
                          child: Text(
                            _getStepTitle(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
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
                              fontSize: 16,
                              fontFamily: 'Onest',
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: _buildStepContent(),
                          ),
                        ),
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
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Personal Information';
      case 1:
        return 'Location Details';
      case 2:
        return 'Almost Done';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Tell us a bit about yourself';
      case 1:
        return 'Where are you located?';
      case 2:
        return 'Just a few more details to complete your profile';
      default:
        return '';
    }
  }

  List<Widget> _generateBubbles() {
    final List<Widget> bubbles = [];
    final random = math.Random();

    for (int i = 0; i < 10; i++) {
      final size = 40 + random.nextDouble() * 20;
      final initialX = random.nextDouble() * MediaQuery.of(context).size.width;
      final initialY = random.nextDouble() * MediaQuery.of(context).size.height;
      final duration = Duration(seconds: 5 + random.nextInt(10));

      bubbles.add(
        AnimatedBubble(
          size: size,
          initialX: initialX,
          initialY: initialY,
          duration: duration,
        ),
      );
    }

    return bubbles;
  }
}
