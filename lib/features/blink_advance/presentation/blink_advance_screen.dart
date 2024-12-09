import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/storage_service.dart';
import 'package:myapp/services/auth_service.dart'
    show AuthService, TransferSpeed;
import 'package:intl/intl.dart';
import 'package:myapp/features/home/presentation/home_screen.dart';
import 'dart:math' show pi, sin;
import 'package:myapp/utils/theme_manager.dart';
import 'package:myapp/widgets/confetti_overlay.dart';
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
  TransferSpeed? _selectedSpeed; // Updated to use TransferSpeed enum
  DateTime? _selectedDate;
  final ScrollController _scrollController = ScrollController();
  int? _animatingMessageIndex;
  bool _isTyping = false;
  final ThemeManager _themeManager = ThemeManager();
  final GlobalKey _confettiKey = GlobalKey();
  final List<int> _amountOptions =
      List.generate(21, (index) => 100 + index * 10); // Updated amount options
  late AnimationController _fadeController;
  late AnimationController _inputSectionController;
  late Animation<Offset> _inputSectionAnimation;
  String? _bankAccountId = ''; // Updated to String? _bankAccountId = '';

  @override
  void initState() {
    super.initState();
    _bankAccountId = widget.bankAccountId; // Initialize _bankAccountId
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

    // Delay the appearance of the input section
    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted) {
        _inputSectionController.forward();
      }
    });
    _loadBankAccountId(); // Add this line to load the bank account ID
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _inputSectionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final firstName = storageService.getFirstName() ?? 'User';
    setState(() {
      _userName = firstName;
    });
  }

  Future<void> _loadBankAccountId() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final bankAccountId = storageService.getBankAccountId();
    setState(() {
      _bankAccountId = bankAccountId;
    });
  }

  void _addInitialMessage() {
    _addMessage(ChatMessage(
      text:
          'Hello $_userName! I\'m here to help you with your Blink Advance. How much do you need today?',
      isUser: false,
      timestamp: DateTime.now(),
      emoji: AnimatedEmoji(AnimatedEmojis.moneyWithWings, size: 24),
    ));
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
      _animatingMessageIndex = _messages.length - 1;
    });
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // Stop animation after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _animatingMessageIndex = null;
        });
      }
    });
  }

  void _showTypingIndicator() {
    setState(() {
      _isTyping = true;
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
    setState(() {
      _selectedAmount = amount;
    });
    _addMessage(ChatMessage(
      text: 'I would like to use Blink to get \$$amount.',
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _showTypingIndicator();
    Future.delayed(Duration(milliseconds: 2000), () {
      _addMessage(ChatMessage(
        text:
            'Great Choice! We are preparing your \$$amount Blink Advance.  Let me know if you need anything else!',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.partyPopper, size: 24),
      ));
      Future.delayed(Duration(milliseconds: 1000), () {
        _showTypingIndicator();
      });
      Future.delayed(Duration(milliseconds: 3000), () {
        _addMessage(ChatMessage(
          text:
              '$_userName! Tell me.\nHow fast do you need the \$$amount Blink Advance?',
          isUser: false,
          timestamp: DateTime.now(),
          emoji: AnimatedEmoji(AnimatedEmojis.alarmClock, size: 24),
        ));
      });
    });
  }

  void _handleSpeedSelection(TransferSpeed speed) {
    // Updated to use TransferSpeed enum
    setState(() {
      _selectedSpeed = speed;
    });

    _addMessage(ChatMessage(
      text:
          'I would like to get access to the \$$_selectedAmount Blink Advance ${speed.toString().split('.').last} speed.',
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _showTypingIndicator();

    Future.delayed(Duration(milliseconds: 2000), () {
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
    setState(() {
      _selectedDate = date;
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
      _addMessage(ChatMessage(
        text: 'Great! Let\'s confirm your Blink Advance details:\n\n'
            '• Amount: \$$_selectedAmount\n'
            '• Speed: ${_selectedSpeed?.toString().split('.').last ?? ''}\n' // Handle potential null value
            '• Fee: \$${_selectedSpeed == TransferSpeed.instant ? '9.50' : '4.50'}\n' // Handle fee based on speed
            '• Repayment Date: $formattedDate\n\n'
            'Is this correct? Please confirm to complete or let me know if you need to make any changes.',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.checkMark, size: 24),
      ));
    });
  }

  void _handleConfirmation(bool confirmed) {
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
    final bankAccountId = storageService.getBankAccountId();

    if (userId == null) {
      _showErrorMessage('User ID not found. Please log in again.');
      return;
    }

    if (bankAccountId == null) {
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
        _showSuccessMessage();
      } else {
        _showErrorMessage(response['message'] ??
            'Failed to create Blink Advance. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('An unexpected error occurred. Please try again.');
    }
  }

  void _showSuccessMessage() {
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
    // Navigate back to HomeScreen after a short delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => HomeScreen(
                  userName: _userName, bankAccountId: _bankAccountId ?? '')),
        );
      }
    });
  }

  void _showErrorMessage(String message) {
    _addMessage(ChatMessage(
      text:
          'I\'m sorry, but there was an error processing your Blink Advance: $message',
      isUser: false,
      timestamp: DateTime.now(),
      emoji: AnimatedEmoji(AnimatedEmojis.sad, size: 24),
    ));

    // Also show a snackbar for immediate visibility
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

  List<Map<String, dynamic>>? _getDetailedBankAccounts() {
    final storageService = Provider.of<StorageService>(context, listen: false);
    return storageService.getDetailedBankAccounts();
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
                    color: Colors.white.withOpacity(0.8),
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
                          message: message.text,
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
    if (_messages.isNotEmpty) {
      // Update: Changed condition to _messages.isNotEmpty
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedAmount == null && _messages.length >= 1) ...[
            _buildHelpButton('Need help choosing an amount?'),
            SizedBox(height: 8),
            _buildAmountButtons(),
          ] else if (_selectedSpeed == null && _messages.length >= 3) ...[
            _buildHelpButton('What\'s the difference between speeds?'),
            SizedBox(height: 8),
            _buildSpeedSelector(),
          ] else if (_selectedDate == null && _messages.length >= 5) ...[
            _buildHelpButton('How do I choose a repayment date?'),
            SizedBox(height: 8),
            _buildDateSelector(),
          ] else if (_messages.length >= 7) ...[
            _buildConfirmationButtons(),
          ],
        ],
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildAmountButtons() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _themeManager.currentTheme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _amountOptions.map((amount) {
            final isSelected = _selectedAmount == amount.toString();
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _handleAmountSelection(amount.toString()),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isSelected
                          ? [kSecondaryColor, kPrimaryColor]
                          : [kPrimaryColor.withOpacity(0.8), kPrimaryColor],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '\$$amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
                    .animate()
                    .scale(duration: 200.ms, curve: Curves.easeOut)
                    .fade(duration: 200.ms),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSpeedSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeManager.currentTheme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleSpeedSelection(TransferSpeed.instant),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Instant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$9.50',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleSpeedSelection(TransferSpeed.normal),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Normal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$4.50',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
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

  Widget _buildDateSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeManager.currentTheme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(Duration(days: 1)),
            firstDate: DateTime.now().add(Duration(days: 1)),
            lastDate:
                DateTime.now().add(Duration(days: 31)), // Updated date picker
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: kPrimaryColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Select Repayment Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _themeManager.currentTheme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleConfirmation(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleConfirmation(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 3,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Confirm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildHelpButton(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextButton(
        onPressed: () {
          _addMessage(ChatMessage(
            text: text,
            isUser: true,
            timestamp: DateTime.now(),
          ));
          // Add logic to provide help based on the question
        },
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AnimatedEmoji? emoji;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.emoji,
  });
}

class CustomChatBubble extends StatelessWidget {
  final String message;
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
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                _buildAvatar(),
                SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isUser
                          ? [kSecondaryColor, kPrimaryColor]
                          : [Colors.grey[200]!, Colors.grey[100]!],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 16,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (emoji != null) ...[
                        SizedBox(width: 8),
                        emoji!,
                      ],
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                SizedBox(width: 8),
                _buildAvatar(),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isUser ? 0 : 48,
              right: isUser ? 48 : 0,
            ),
            child: Text(
              DateFormat('MMM d, h:mm a').format(timestamp),
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
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
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isUser ? Colors.grey[300]! : Colors.white,
            isUser ? Colors.grey[400]! : Colors.white.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isUser
          ? Icon(Icons.person, color: Colors.grey[600], size: 20)
          : ClipOval(
              child: Image.asset(
                'assets/images/blinky-avatar.png',
                fit: BoxFit.cover,
              ),
            ),
    )
        .animate(target: isAnimating ? 1 : 0)
        .shake(duration: 400.ms, rotation: 0.1)
        .scale(
            begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0), duration: 200.ms);
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
            color: Colors.black.withOpacity(0.1),
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
