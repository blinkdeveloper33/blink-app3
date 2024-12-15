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

const Color kPrimaryColor = Color(0xFF0E6BA8);
const Color kSecondaryColor = Color(0xFF1A237E);
const Color kBackgroundColor = Color(0xFF061535);
const Color kTextColor = Colors.white;
const Color kTextColorDark = Colors.black87;

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
  final List<ChatMessage> _messages = [];
  String _userName = '';
  String? _selectedAmount;
  TransferSpeed? _selectedSpeed;
  DateTime? _selectedDate;
  final ScrollController _scrollController = ScrollController();
  int? _animatingMessageIndex;
  bool _isTyping = false;
  final GlobalKey _confettiKey = GlobalKey();
  final List<int> _amountOptions =
      List.generate(7, (index) => 150 + index * 25);
  late AnimationController _fadeController;
  late AnimationController _inputSectionController;
  late Animation<Offset> _inputSectionAnimation;
  String? _bankAccountId = '';
  bool _showQuickActions = false;

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

    // Initialize the input section animation after a delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _inputSectionController.forward();
        setState(() {
          _showQuickActions = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _inputSectionController.dispose();
    _scrollController.dispose();
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
    _addMessage(ChatMessage(
      text:
          'Hello $_userName! I\'m here to help you with your Blink Advance. How much do you need today?',
      isUser: false,
      timestamp: DateTime.now(),
      emoji: AnimatedEmoji(AnimatedEmojis.moneyWithWings, size: 24),
      richText: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(text: 'Hello '),
            TextSpan(
              text: _userName,
              style: TextStyle(
                color: Color(0xFF007FFF),
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
                text:
                    '! I\'m here to help you with your Blink Advance. How much do you need today?'),
          ],
        ),
      ),
    ));
    _showQuickActionsWithDelay();
  }

  void _addMessage(ChatMessage message) {
    if (!mounted) return;

    setState(() {
      _messages.add(message);
      _animatingMessageIndex = _messages.length - 1;
      _showQuickActions = false;
    });

    Future.delayed(Duration(milliseconds: 100), () {
      if (!mounted) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Show quick actions after message animation completes
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _animatingMessageIndex = null;
        });
        _inputSectionController.forward();
        setState(() {
          _showQuickActions = true;
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
    if (!mounted) return;

    setState(() {
      _selectedAmount = amount;
      _showQuickActions = false;
    });
    _inputSectionController.reverse();

    _addMessage(ChatMessage(
      text: 'I would like to use Blink to get \$$amount.',
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _showTypingIndicator();

    Future.delayed(Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _addMessage(ChatMessage(
        text: 'Great Choice! We are preparing your \$$amount Blink Advance.',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.partyPopper, size: 24),
      ));

      Future.delayed(Duration(milliseconds: 1000), () {
        if (mounted) {
          _showTypingIndicator();
        }
      });

      Future.delayed(Duration(milliseconds: 3000), () {
        if (!mounted) return;
        _addMessage(ChatMessage(
          text:
              'Hey $_userName! When do you need your \$$amount Blink Advance? Let\'s make it happen! ⚡️',
          isUser: false,
          timestamp: DateTime.now(),
          emoji: AnimatedEmoji(AnimatedEmojis.rocket, size: 24),
        ));
        _resetInputSection();
      });
    });
  }

  void _handleSpeedSelection(TransferSpeed speed) {
    if (!mounted) return;

    setState(() {
      _selectedSpeed = speed;
      _showQuickActions = false;
    });

    _addMessage(ChatMessage(
      text:
          'I would like to get access to the \$$_selectedAmount Blink Advance ${speed.toString().split('.').last} speed.',
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _showTypingIndicator();

    Future.delayed(Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _addMessage(ChatMessage(
        text:
            'Got it! You\'ve selected the ${speed.toString().split('.').last} speed option. Now to finalize, please let me know when you\'re planning to repay your Blink Advance.',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.moneyWithWings, size: 24),
      ));
    });
  }

  void _handleDateSelection(DateTime date) {
    if (!mounted) return;

    setState(() {
      _selectedDate = date;
      _showQuickActions = false;
    });
    final formattedDate = DateFormat('MMMM d, yyyy').format(date);
    _addMessage(ChatMessage(
      text:
          'I will repay the ${_selectedSpeed?.toString().split('.').last ?? ''} Blink Advance plus the fee on $formattedDate.',
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _showTypingIndicator();
    Future.delayed(Duration(milliseconds: 2000), () {
      if (!mounted) return;
      _addMessage(ChatMessage(
        text: 'Great! Let\'s confirm your Blink Advance details:\n\n'
            '• Amount: \$$_selectedAmount\n'
            '• Speed: ${_selectedSpeed?.toString().split('.').last ?? ''}\n'
            '• Fee: \$${_selectedSpeed == TransferSpeed.instant ? '8.99' : '3.99'}\n'
            '• Repayment Date: $formattedDate\n\n'
            'Is this correct? Please confirm to complete or let me know if you need to make any changes.',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.checkMark, size: 24),
      ));
    });
  }

  void _handleConfirmation(bool confirmed) {
    if (!mounted) return;

    setState(() {
      _showQuickActions = false;
    });

    if (confirmed) {
      _addMessage(ChatMessage(
        text: 'I confirm the Blink Advance.',
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _showTypingIndicator();
      _createBlinkAdvance();
    } else {
      _addMessage(ChatMessage(
        text: 'I want to cancel the Blink Advance.',
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _showTypingIndicator();
      Future.delayed(Duration(milliseconds: 2000), () {
        if (!mounted) return;
        _addMessage(ChatMessage(
          text:
              'No problem, $_userName. Your Blink Advance request has been cancelled. Is there anything else I can help you with?',
          isUser: false,
          timestamp: DateTime.now(),
          emoji: AnimatedEmoji(AnimatedEmojis.thinkingFace, size: 24),
        ));
      });
    }
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
    }
  }

  void _showSuccessMessage() {
    if (!mounted) return;

    _addMessage(ChatMessage(
      text:
          'Great! Your Blink Advance has been processed. The funds will be available in your account shortly. Have a great day!',
      isUser: false,
      timestamp: DateTime.now(),
      emoji: AnimatedEmoji(AnimatedEmojis.rocket, size: 24),
    ));
    if (_confettiKey.currentContext != null) {
      ConfettiOverlay.of(_confettiKey.currentContext!)?.showConfetti();
    }
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
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

  void _showQuickActionsWithDelay() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showQuickActions = true;
        });
      }
    });
  }

  void _resetInputSection() {
    _inputSectionController.reset();
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        _inputSectionController.forward();
      }
    });
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
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blinky',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Advance for $bankAccountName',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withAlpha(204),
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Image.asset(
                  'assets/images/blink_logo.png',
                  height: 30,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
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
                  child: _buildInputSection(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(left: 16, bottom: 16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(),
            SizedBox(width: 4),
            _buildDot(),
            SizedBox(width: 4),
            _buildDot(),
          ],
        ),
      ),
    );
  }

  Widget _buildDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -3 * sin(value * pi)),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputSection() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _buildCurrentInputWidget(),
    );
  }

  Widget _buildCurrentInputWidget() {
    if (_selectedAmount == null) {
      return _buildAmountSelection();
    } else if (_selectedSpeed == null) {
      return _buildSpeedSelection();
    } else if (_selectedDate == null) {
      return _buildDateSelection();
    } else {
      return _buildConfirmation();
    }
  }

  Widget _buildAmountSelection() {
    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: _amountOptions.map((amount) {
          return ElevatedButton(
            onPressed: () => _handleAmountSelection(amount.toString()),
            child: Text(
              '\$$amount',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 5,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 100.ms)
              .scale(begin: Offset(0.8, 0.8), end: Offset(1, 1));
        }).toList(),
      ),
    );
  }

  Widget _buildSpeedSelection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSpeedButton(
                speed: TransferSpeed.instant,
                title: 'For now',
                subtitle: 'Instant',
                fee: 8.99,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                ),
                textColor: Colors.white,
                emoji: AnimatedEmoji(AnimatedEmojis.electricity, size: 28),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSpeedButton(
                speed: TransferSpeed.normal,
                title: 'For tomorrow',
                subtitle: 'Standard',
                fee: 3.99,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF3F4F6)],
                ),
                textColor: kPrimaryColor,
                emoji: AnimatedEmoji(AnimatedEmojis.alarmClock, size: 28),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms).scale(
          begin: Offset(0.95, 0.95),
          end: Offset(1, 1),
        );
  }

  Widget _buildSpeedButton({
    required TransferSpeed speed,
    required String title,
    required String subtitle,
    required double fee,
    required Gradient gradient,
    required Color textColor,
    required Widget emoji,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleSpeedSelection(speed),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.15),
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
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 150.ms)
        .scale(begin: Offset(0.95, 0.95), end: Offset(1, 1))
        .then()
        .shimmer(duration: 1200.ms, delay: 300.ms);
  }

  Widget _buildDateSelection() {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.white.withAlpha(204),
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Choose a repayment date within the next 30 days',
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(Duration(days: 1)),
                firstDate: DateTime.now().add(Duration(days: 1)),
                lastDate: DateTime.now().add(Duration(days: 30)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: kPrimaryColor,
                        onPrimary: Colors.white,
                        surface: Color(0xFF1A1A1A),
                        onSurface: Colors.white,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: kPrimaryColor,
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
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: kPrimaryColor,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
            ),
            child: Row(
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
              .fadeIn(duration: 300.ms, delay: 100.ms)
              .scale(begin: Offset(0.9, 0.9), end: Offset(1, 1))
              .then()
              .shimmer(duration: 1200.ms, delay: 600.ms),
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

  Widget _buildConfirmation() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleConfirmation(true),
            child: Text('Confirm',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
              elevation: 5,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 100.ms)
              .slideX(begin: -0.2, end: 0),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleConfirmation(false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(vertical: 12),
              elevation: 5,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: 100.ms)
              .slideX(begin: 0.2, end: 0),
        ),
      ],
    );
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment:
            widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isUser) ...[
                _buildAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isUser
                          ? [kSecondaryColor, kPrimaryColor]
                          : [Colors.grey[200]!, Colors.grey[100]!],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(widget.isUser ? 20 : 4),
                      bottomRight: Radius.circular(widget.isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: widget.message.richText ??
                            Text(
                              widget.message.text,
                              style: TextStyle(
                                color: widget.isUser
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 16,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                      ),
                      if (widget.emoji != null) ...[
                        const SizedBox(width: 8),
                        widget.emoji!,
                      ],
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
              left: widget.isUser ? 0 : 48,
              right: widget.isUser ? 48 : 0,
            ),
            child: Text(
              DateFormat('MMM d, h:mm a').format(widget.timestamp),
              style: TextStyle(
                color: widget.isUser
                    ? Colors.white.withAlpha(179)
                    : Colors.black87.withAlpha(179),
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: widget.isUser
                ? Icon(Icons.person, color: Colors.grey[600], size: 20)
                : ClipOval(
                    child: Image.asset(
                      'assets/images/blinky-avatar.png',
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
