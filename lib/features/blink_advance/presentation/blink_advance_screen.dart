import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:blink_app/services/auth_service.dart'
    show AuthService, TransferSpeed;
import 'package:intl/intl.dart';
import 'package:blink_app/features/home/presentation/home_screen.dart';
import 'dart:math' show pi, sin;
import 'package:blink_app/widgets/confetti_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:blink_app/widgets/typing_indicator.dart';
import 'package:flutter/services.dart';

const Color kPrimaryColor = Color(0xFF0E6BA8);
const Color kSecondaryColor = Color(0xFF1A237E);
const Color kBackgroundColor = Color(0xFF061535);
const Color kTextColor = Colors.white;
const Color kTextColorDark = Colors.black87;

enum ConversationState {
  initial,
  amountSelection,
  speedSelection,
  dateSelection,
  summary,
  completed
}

enum HapticsType {
  light,
  medium,
  heavy,
  success,
  warning,
  error,
  selection,
  rigid,
}

class AnimatedBackground extends StatelessWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2472), Color(0xFF0E6BA8)],
        ),
      ),
      child: child,
    );
  }
}

class BlinkAdvanceScreen extends StatefulWidget {
  final String bankAccountId;

  const BlinkAdvanceScreen({super.key, required this.bankAccountId});

  @override
  State<BlinkAdvanceScreen> createState() => _BlinkAdvanceScreenState();
}

class _BlinkAdvanceScreenState extends State<BlinkAdvanceScreen>
    with TickerProviderStateMixin {
  ConversationState _conversationState = ConversationState.initial;
  final List<ChatMessage> _messages = [];
  String _userName = '';
  String? _selectedAmount;
  TransferSpeed? _selectedSpeed;
  DateTime? _selectedDate;
  late ScrollController _scrollController;
  int? _animatingMessageIndex;
  bool _isTyping = false;
  final GlobalKey _confettiKey = GlobalKey();
  final List<int> _amountOptions = [300, 275, 250, 225, 200, 175, 150];
  late AnimationController _fadeController;
  late AnimationController _inputSectionController;
  late Animation<Offset> _inputSectionAnimation;
  String? _bankAccountId = '';
  bool _showQuickActions = false;
  bool _isLoading = false;
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _bankAccountId = widget.bankAccountId;
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _inputSectionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _inputSectionAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _inputSectionController,
      curve: Curves.easeOut,
    ));
    _loadUserName();
    _addInitialMessage();
    _fadeController.forward();
    _scrollController = ScrollController();

    // Initialize the input section animation after a delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _inputSectionController.forward();
        setState(() {
          _showQuickActions = true;
        });
      }
    });

    _confettiController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _inputSectionController.dispose();
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final firstName = storageService.getFirstName() ?? 'User';
    if (!mounted) return;
    setState(() {
      _userName = firstName;
    });
  }

  void _addInitialMessage() {
    Future.delayed(Duration(milliseconds: 1000), () {
      setState(() {
        _conversationState = ConversationState.initial;
      });

      _addMessage(ChatMessage(
        text: 'Hi $_userName!',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.wave, size: 24),
      ));

      Future.delayed(Duration(milliseconds: 2500), () {
        setState(() {
          _conversationState = ConversationState.amountSelection;
        });

        _addMessage(ChatMessage(
          text: 'How much do you need today? Choose between \$150-\$300',
          isUser: false,
          timestamp: DateTime.now(),
          emoji: AnimatedEmoji(AnimatedEmojis.moneyWithWings, size: 24),
        ));

        Future.delayed(Duration(milliseconds: 1000), () {
          if (mounted &&
              _conversationState == ConversationState.amountSelection) {
            _showQuickActionsWithAnimation();
          }
        });
      });
    });
  }

  void _showQuickActionsWithAnimation() {
    if (!mounted) return;

    setState(() {
      _showQuickActions = true;
    });

    _inputSectionController.forward();
  }

  void _addMessage(ChatMessage message) {
    if (!mounted) return;

    setState(() {
      _messages.add(message);
      _animatingMessageIndex = _messages.length - 1;
      if (_showQuickActions) _showQuickActions = false;
    });

    Future.delayed(Duration(milliseconds: 100), () {
      if (!mounted) return;
      _scrollToBottom();
    });

    // Remove automatic quick actions show
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _animatingMessageIndex = null;
        });
      }
    });
  }

  void _showTypingIndicator() {
    if (!mounted) return;

    setState(() {
      _isTyping = true;
      _showQuickActions = false;
    });
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  void _handleAmountSelection(String amount) {
    _performHapticFeedback(HapticsType.medium);
    if (!mounted) return;

    setState(() {
      _selectedAmount = amount;
      _showQuickActions = false;
      _conversationState = ConversationState.speedSelection;
    });
    _inputSectionController.reverse();

    _addMessage(ChatMessage(
      text: 'I need \$$amount',
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _showTypingIndicator();

    Future.delayed(Duration(milliseconds: 2000), () {
      if (!mounted) return;

      _addMessage(ChatMessage(
        text: 'When do you need these funds?',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.sparkles, size: 24),
      ));

      Future.delayed(Duration(milliseconds: 1000), () {
        if (mounted) {
          _showQuickActionsWithAnimation();
        }
      });
    });
  }

  void _handleSpeedSelection(TransferSpeed speed) {
    if (!mounted) return;

    setState(() {
      _selectedSpeed = speed;
      _showQuickActions = false;
      _conversationState = ConversationState.dateSelection;
    });

    _addMessage(ChatMessage(
      text: 'I prefer the ${speed.toString().split('.').last} transfer option.',
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _showTypingIndicator();

    Future.delayed(Duration(milliseconds: 2000), () {
      if (!mounted) return;

      final speedEmoji = speed == TransferSpeed.instant
          ? AnimatedEmoji(AnimatedEmojis.electricity, size: 24)
          : AnimatedEmoji(AnimatedEmojis.alarmClock, size: 24);

      _addMessage(ChatMessage(
        text: speed == TransferSpeed.instant
            ? 'Your money will arrive in minutes!'
            : 'Your money will arrive in 1-2 business days.',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: speedEmoji,
      ));

      Future.delayed(Duration(milliseconds: 1500), () {
        _addMessage(ChatMessage(
          text: 'When would you like to repay your \$$_selectedAmount advance?',
          isUser: false,
          timestamp: DateTime.now(),
          emoji: AnimatedEmoji(AnimatedEmojis.thinkingFace, size: 24),
        ));

        Future.delayed(Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _conversationState = ConversationState.dateSelection;
            });
            _showQuickActionsWithAnimation();
          }
        });
      });
    });
  }

  Future<void> _showDatePicker() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[600]!,
              onPrimary: Colors.white,
              surface: isDarkMode ? Colors.grey[900]! : Colors.white,
              onSurface: isDarkMode ? Colors.white : Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[600],
                textStyle: const TextStyle(
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _handleDateSelection(picked);
    }
  }

  void _handleDateSelection(DateTime date) {
    setState(() {
      _selectedDate = date;
      _showQuickActions = false;
      _conversationState = ConversationState.summary;
    });

    final formattedDate = DateFormat('MMMM d, yyyy').format(date);

    _addMessage(ChatMessage(
      text: 'I\'ll repay on $formattedDate.',
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _showTypingIndicator();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;

      _addMessage(ChatMessage(
        text: 'Got it! Let me prepare your summary.',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.alarmClock, size: 24),
      ));

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        _showAdvanceSummary();
      });
    });
  }

  void _showAdvanceSummary() {
    final fee = _selectedSpeed == TransferSpeed.instant ? 8.99 : 3.99;
    _addMessage(ChatMessage(
      text: 'Here\'s your advance details:\n\n'
          '• Amount: \$$_selectedAmount\n'
          '• Transfer: ${_selectedSpeed == TransferSpeed.instant ? 'Instant' : 'Standard'}\n'
          '• Fee: \$${fee.toStringAsFixed(2)}\n'
          '• Repayment: ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}\n\n'
          'Ready to proceed?',
      isUser: false,
      timestamp: DateTime.now(),
      emoji: AnimatedEmoji(AnimatedEmojis.moneyWithWings, size: 24),
    ));

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _conversationState = ConversationState.summary;
        });
        _showQuickActionsWithAnimation();
      }
    });
  }

  void _handleConfirmation(bool confirmed) {
    _performHapticFeedback(HapticsType.heavy);

    if (!confirmed) {
      _handleCancellation();
      return;
    }

    setState(() {
      _showQuickActions = false;
      _isLoading = true;
    });

    // Process the advance
    _createBlinkAdvance();
  }

  Future<void> _createBlinkAdvance() async {
    final List<String> missingFields = [];

    if (_selectedAmount == null) missingFields.add('Amount');
    if (_selectedSpeed == null) missingFields.add('Transfer Speed');
    if (_selectedDate == null) missingFields.add('Repayment Date');

    if (missingFields.isNotEmpty) {
      _showErrorMessage(
        'Missing required information: ${missingFields.join(', ')}. Please complete all fields.',
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    final userId = storageService.getUserId();
    final bankAccountId = _bankAccountId;

    if (userId == null) {
      _showErrorMessage('User ID not found. Please log in again.');
      return;
    }

    if (bankAccountId == null || bankAccountId.isEmpty) {
      _showErrorMessage(
          'Bank account ID not found. Please link your bank account again.');
      return;
    }

    try {
      final response = await authService.createBlinkAdvance(
        userId: userId,
        requestedAmount: double.parse(_selectedAmount!),
        transferSpeed: _selectedSpeed!,
        repayDate: _selectedDate!,
        bankAccountId: bankAccountId,
      );

      if (response['success'] == true) {
        if (mounted) {
          _showSuccessMessage();
        }
      } else {
        if (mounted) {
          _showErrorMessage(response['message'] ??
              'Failed to create Blink Advance. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessMessage() {
    if (!mounted) return;

    // First haptic feedback for success
    _performHapticFeedback(HapticsType.success);

    // Show success popup with logo
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success checkmark animation
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 60,
                  ),
                ).animate().scale(
                      begin: Offset(0.5, 0.5),
                      end: Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),
                SizedBox(height: 24),
                // Blink logo
                Image.asset(
                  'assets/images/blink_logo.png',
                  height: 40,
                  fit: BoxFit.contain,
                ).animate().fadeIn(duration: 600.ms).scale(
                      begin: Offset(0.8, 0.8),
                      end: Offset(1, 1),
                      duration: 600.ms,
                    ),
                SizedBox(height: 24),
                Text(
                  'Advance Processed!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                SizedBox(height: 8),
                Text(
                  'Your funds are on the way',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ).animate().scale(
                begin: Offset(0.8, 0.8),
                end: Offset(1, 1),
                duration: 400.ms,
                curve: Curves.easeOut,
              ),
        );
      },
    );

    // Second haptic feedback after a short delay
    Future.delayed(Duration(milliseconds: 300), () {
      _performHapticFeedback(HapticsType.medium);
    });

    // Third haptic feedback for extra satisfaction
    Future.delayed(Duration(milliseconds: 600), () {
      _performHapticFeedback(HapticsType.light);
    });

    // Show confetti effect
    if (_confettiKey.currentContext != null) {
      ConfettiOverlay.of(_confettiKey.currentContext!)?.showConfetti();
    }

    // Add the final message
    _addMessage(ChatMessage(
      text: 'Your advance is on its way! Check your account shortly.',
      isUser: false,
      timestamp: DateTime.now(),
      emoji: AnimatedEmoji(AnimatedEmojis.rocket, size: 24),
    ));

    // Automatically close popup and return to home screen after a delay
    Future.delayed(Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.of(context).pop(); // Close the popup
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    _addMessage(ChatMessage(
      text:
          'I\'m sorry, but there was an error processing your Blink Advance: $message',
      isUser: false,
      timestamp: DateTime.now(),
      emoji: AnimatedEmoji(AnimatedEmojis.sad, size: 24),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleCancellation() {
    setState(() {
      _showQuickActions = false;
      _conversationState = ConversationState.completed;
    });

    _inputSectionController.reverse();

    _addMessage(ChatMessage(
      text: 'I want to cancel the Blink Advance.',
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _showTypingIndicator();

    Future.delayed(Duration(milliseconds: 2000), () {
      if (!mounted) return;

      _addMessage(ChatMessage(
        text: 'No worries! Let me know if you need anything else.',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.wave, size: 24),
      ));

      Future.delayed(Duration(milliseconds: 2000), () {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: Duration(milliseconds: 500),
          ),
        );
      });
    });
  }

  List<Widget> _buildAmountOptions() {
    return _amountOptions.map((amount) {
      return SizedBox(
        width: 95, // Fixed width for amount buttons
        child: ElevatedButton(
          onPressed: () {
            _performHapticFeedback(HapticsType.medium);
            _handleAmountSelection(amount.toString());
          },
          style: _getButtonStyle(
            backgroundColor: Colors.blue[600],
            borderRadius: 20,
            elevation: 2,
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text('\$$amount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
    }).toList();
  }

  List<Widget> _buildSpeedOptions() {
    return [
      SizedBox(
        width: MediaQuery.of(context).size.width * 0.43,
        child: _buildSpeedButton(
          speed: TransferSpeed.instant,
          title: 'For Now',
          subtitle: 'Instant Transfer',
          fee: 8.99,
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          textColor: Colors.white,
          emoji: AnimatedEmoji(AnimatedEmojis.rocket, size: 24),
          particles: true,
        ),
      ),
      SizedBox(
        width: MediaQuery.of(context).size.width * 0.43,
        child: _buildSpeedButton(
          speed: TransferSpeed.standard,
          title: 'For Tomorrow',
          subtitle: 'Standard Transfer',
          fee: 3.99,
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          textColor: Colors.white,
          emoji: AnimatedEmoji(AnimatedEmojis.snail, size: 24),
          particles: false,
        ),
      ),
    ];
  }

  Widget _buildSpeedButton({
    required TransferSpeed speed,
    required String title,
    required String subtitle,
    required double fee,
    required Gradient gradient,
    required Color textColor,
    required Widget emoji,
    required bool particles,
  }) {
    return GestureDetector(
      onTap: () => _handleSpeedSelection(speed),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
            vertical: 20.8,
            horizontal: 12), // Increased vertical padding by 1.3 times
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                emoji,
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.5), // Increased from 6 to 6.5
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withAlpha((0.8 * 255).round()),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 6.5), // Increased from 6 to 6.5
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: textColor.withAlpha((0.15 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '\$${fee.toStringAsFixed(2)} fee',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 150.ms)
        .scale(begin: Offset(0.95, 0.95), end: Offset(1, 1))
        .then()
        .shimmer(duration: 1200.ms, delay: 300.ms);
  }

  List<Widget> _buildConfirmationOptions() {
    return [
      Expanded(
        child: ElevatedButton(
          onPressed: () => _handleConfirmation(true),
          style: _getButtonStyle(
            backgroundColor: Colors.green,
            borderRadius: 30,
            elevation: 5,
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text('Confirm',
              style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: ElevatedButton(
          onPressed: _handleCancellation,
          style: _getButtonStyle(
            backgroundColor: Colors.grey[300],
            borderRadius: 20,
            elevation: 2,
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Cancel'),
        ),
      ),
    ];
  }

  List<Widget> _buildDateOptions() {
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton.icon(
          onPressed: () {
            _performHapticFeedback(HapticsType.medium);
            _showDatePicker();
          },
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          label: const Text('Select Repayment Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          style: _getButtonStyle(
            backgroundColor: Colors.blue[600],
            borderRadius: 20,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
    ];
  }

  Widget _buildDateOptionsLayout(BoxConstraints constraints) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInfoBox('Choose a repayment date within the next 30 days'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              _performHapticFeedback(HapticsType.medium);
              _showDatePicker();
            },
            style: _getButtonStyle(),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 20),
                SizedBox(width: 12),
                Text(
                  'Select Repayment Date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
          SizedBox(height: 8),
          Text(
            'Repayment must be completed within 30 days',
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationLayout(BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleConfirmation(true),
              style: _getButtonStyle(
                backgroundColor: Colors.green[600],
                borderRadius: 20,
                elevation: 2,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Confirm',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleConfirmation(false),
              style: _getButtonStyle(
                backgroundColor: Colors.red[400],
                borderRadius: 20,
                elevation: 2,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  // Consolidated Button Style Method 🎨
  ButtonStyle _getButtonStyle({
    Color? backgroundColor,
    double elevation = 2,
    EdgeInsetsGeometry? padding,
    double borderRadius = 20,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.blue[600],
      foregroundColor: Colors.white,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: elevation,
    );
  }

  Widget _buildInfoBox(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline,
              size: 16, color: Colors.white.withAlpha(204)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withAlpha(204),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performHapticFeedback(HapticsType type) {
    switch (type) {
      case HapticsType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticsType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticsType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticsType.success:
        HapticFeedback.vibrate();
        break;
      case HapticsType.warning:
        HapticFeedback.vibrate();
        break;
      case HapticsType.error:
        HapticFeedback.vibrate();
        break;
      case HapticsType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticsType.rigid:
        HapticFeedback.vibrate();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final bankAccountName =
        storageService.getBankAccountName() ?? 'Your Bank Account';

    return AnimatedBackground(
      child: ConfettiOverlay(
        key: _confettiKey,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: ClipOval(
                        child: Image.network(
                          'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Smilies/Robot.png',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Blinky',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Online',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      onPressed: () {
                        // Show info about Blink Advance
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30)),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(top: 20, bottom: 20),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isTyping) {
                            return _buildTypingIndicator();
                          }
                          final message = _messages[index];
                          return CustomChatBubble(
                            message: message,
                            isUser: message.isUser,
                            timestamp: message.timestamp,
                            isAnimating: _animatingMessageIndex == index &&
                                !message.isUser,
                            emoji: message.emoji,
                          )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.2, end: 0);
                        },
                      ),
                    ),
                  ),
                ),
                if (_showQuickActions && !_isTyping)
                  SlideTransition(
                    position: _inputSectionAnimation,
                    child: _buildQuickActionsSection(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: TypingIndicator(),
    );
  }

  Widget _buildQuickActionsSection() {
    if (!_showQuickActions) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            switch (_conversationState) {
              case ConversationState.amountSelection:
                return _buildAmountOptionsLayout(constraints);
              case ConversationState.speedSelection:
                return _buildSpeedOptionsLayout(constraints);
              case ConversationState.dateSelection:
                return _buildDateOptionsLayout(constraints);
              case ConversationState.summary:
                return _buildConfirmationLayout(constraints);
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  // Removed the following duplicated methods:
  // _buildQuickActionButton()
  // _buildAnimatedButton()
  // _buildConfirmationButtons()
  // _buildCurrentInputWidget()

  // Ensure all functionalities are now handled by their optimized layout methods.

  Widget _buildSpeedOptionsLayout(BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: _buildSpeedOptions(),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildAmountOptionsLayout(BoxConstraints constraints) {
    final buttonWidth = (constraints.maxWidth - 48) / 3;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _buildAmountOptions(),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AnimatedEmoji? emoji;
  final RichText? richText;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.emoji,
    this.richText,
  });
}

class CustomChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isUser;
  final DateTime timestamp;
  final bool isAnimating;
  final AnimatedEmoji? emoji;

  const CustomChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.isAnimating = false,
    this.emoji,
  });

  @override
  State<CustomChatBubble> createState() => _CustomChatBubbleState();
}

class _CustomChatBubbleState extends State<CustomChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation =
        Tween<double>(begin: 0.0, end: 0.1).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void shake() {
    _shakeController.forward().then((_) => _shakeController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: widget.isUser ? 64 : 16,
        right: widget.isUser ? 16 : 64,
        top: 8,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment:
            widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isUser) _buildAvatar(),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isUser
                        ? Colors.blue[600]
                        : isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[100],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(widget.isUser ? 20 : 4),
                      bottomRight: Radius.circular(widget.isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              widget.message.text,
                              style: TextStyle(
                                color: widget.isUser ? Colors.white : null,
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (widget.emoji != null) ...[
                            SizedBox(width: 8),
                            widget.emoji!,
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.isUser) ...[
                const SizedBox(width: 8),
                _buildAvatar(),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
                top: 4,
                left: !widget.isUser ? 48 : 0,
                right: widget.isUser ? 48 : 0),
            child: Text(
              DateFormat('h:mm a').format(widget.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _shakeAnimation.value,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.isUser ? Colors.grey[300]! : Colors.white,
                  widget.isUser
                      ? Colors.grey[400]!
                      : Colors.white.withAlpha(204),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: widget.isUser
                ? Icon(Icons.person, color: Colors.grey[600], size: 20)
                : ClipOval(
                    child: Image.network(
                      'https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Smilies/Robot.png',
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class BlinkyAvatar extends StatelessWidget {
  final double size;

  const BlinkyAvatar({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/blinky-avatar.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const AnimatedButton({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withAlpha((0.3 * 255).round()),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
              horizontal: 20, vertical: 15.6), // Increased by 1.3 times
          child: widget.child,
        ),
      ),
    );
  }
}
