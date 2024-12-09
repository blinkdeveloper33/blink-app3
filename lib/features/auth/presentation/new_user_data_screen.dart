import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/features/auth/presentation/create_password_screen.dart';
import 'package:myapp/services/storage_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NewUserDataScreen extends StatefulWidget {
  final String email;

  const NewUserDataScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<NewUserDataScreen> createState() => _NewUserDataScreenState();
}

class _NewUserDataScreenState extends State<NewUserDataScreen>
    with SingleTickerProviderStateMixin {
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
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.white70)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              prefixIcon: Icon(Icons.location_on, color: Colors.white70),
            ),
            dropdownColor: const Color(0xFF061535),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Onest',
            ),
            iconEnabledColor: const Color(0xFF2196F3),
            hint: Text(
              'Select State',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
                fontFamily: 'Onest',
              ),
            ),
            items: _states.map((String state) {
              return DropdownMenuItem<String>(
                value: state,
                child: Text(state),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedState = newValue;
              });
            },
          ),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (!_acknowledgeAccuracy) {
        _showSnackBar('Please acknowledge the accuracy of your information.',
            isError: true);
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

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CreatePasswordScreen(email: widget.email),
          ),
        );
      } catch (e, stackTrace) {
        _logger.e('Error submitting form', error: e, stackTrace: stackTrace);
        if (mounted) {
          _showErrorDialog('An unexpected error occurred. Please try again.');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
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
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
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
                return Colors.white.withOpacity(0.1);
              },
            ),
            checkColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'I acknowledge that all information provided is accurate and true.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontFamily: 'Onest',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          disabledBackgroundColor: Colors.grey,
          elevation: 5,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: index == _currentStep ? 30 : 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: index == _currentStep
                ? const Color(0xFF2196F3)
                : Colors.white.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return FadeInRight(
          duration: const Duration(milliseconds: 300),
          child: Column(
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
          ),
        );
      case 1:
        return FadeInRight(
          duration: const Duration(milliseconds: 300),
          child: _buildDropdownField(),
        );
      case 2:
        return FadeInRight(
          duration: const Duration(milliseconds: 300),
          child: Column(
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
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061535),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: FadeTransition(
              opacity: _fadeInAnimation,
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
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.white),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Go Back',
                        ),
                        Image.asset(
                          'assets/images/blink_logo.png',
                          height: 30,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: SvgPicture.asset(
                          'assets/images/personal_info.svg',
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInLeft(
                      duration: const Duration(milliseconds: 800),
                      child: const Text(
                        'Personal Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInLeft(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'Please provide your personal information to continue',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildProgressIndicator(),
                    const SizedBox(height: 24),
                    _buildStepContent(),
                    const SizedBox(height: 32),
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentStep > 0)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _currentStep--;
                                });
                              },
                              child: const Text(
                                'Previous',
                                style: TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontSize: 16,
                                  fontFamily: 'Onest',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (_currentStep < 2)
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _currentStep++;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                'Next',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Onest',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
