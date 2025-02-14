import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:blink_app/services/auth_service.dart'
    show AuthService, TransferSpeed;
import 'package:intl/intl.dart';
import 'package:blink_app/features/home/presentation/home_screen.dart';
import 'dart:math' show pi, sin, cos, Random, sqrt, pow;
import 'package:blink_app/widgets/confetti_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:blink_app/widgets/typing_indicator.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:blink_app/providers/profile_provider.dart';

const Color kPrimaryColor = Color(0xFF0E6BA8);
const Color kSecondaryColor = Color(0xFF1A237E);
const Color kBackgroundColor = Color(0xFF061535);
const Color kTextColor = Colors.white;
const Color kTextColorDark = Colors.black87;

enum ConversationState {
  initial,
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

enum TransferSpeed { instant, standard }

enum RepaymentDate { sevenDays, fifteenDays }

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;
  final int numberOfParticles = 75;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    particles = List.generate(
      numberOfParticles,
      (index) => Particle.random(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base solid color layer
        Container(
          color: const Color(0xFF061535),
        ),
        // Static gradient layer
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A237E).withOpacity(0.95),
                const Color(0xFF0D47A1).withOpacity(0.95),
                const Color(0xFF1565C0).withOpacity(0.95),
              ],
            ),
          ),
        ),
        // Animated gradient and particles layer
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                // Animated gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(
                        cos(_controller.value * 2 * pi),
                        sin(_controller.value * 2 * pi),
                      ),
                      end: Alignment(
                        cos(_controller.value * 2 * pi + pi),
                        sin(_controller.value * 2 * pi + pi),
                      ),
                      colors: [
                        Color(0xFF0E6BA8).withOpacity(0.3),
                        Color(0xFF1A237E).withOpacity(0.3),
                        Color(0xFF0E6BA8).withOpacity(0.3),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Particles layer
                CustomPaint(
                  painter: ParticlePainter(
                    particles: particles,
                    animation: _controller,
                  ),
                ),
              ],
            );
          },
        ),
        // Blur overlay
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: widget.child,
        ),
      ],
    );
  }
}

class Particle {
  double x;
  double y;
  double speed;
  double theta;
  double radius;
  Color color;
  double opacity;
  double velocityX;
  double velocityY;
  double glowRadius;
  double glowIntensity;
  final random = Random();

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.theta,
    required this.radius,
    required this.color,
    required this.opacity,
    required this.velocityX,
    required this.velocityY,
    required this.glowRadius,
    required this.glowIntensity,
  });

  factory Particle.random() {
    final random = Random();
    final baseRadius = random.nextDouble() * 2 + 1;
    return Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      speed: random.nextDouble() * 0.2 + 0.1,
      theta: random.nextDouble() * 2 * pi,
      radius: baseRadius,
      color: Colors.white.withOpacity(random.nextDouble() * 0.3),
      opacity: random.nextDouble() * 0.5,
      velocityX: (random.nextDouble() - 0.5) * 0.01,
      velocityY: (random.nextDouble() - 0.5) * 0.01,
      glowRadius: baseRadius * 3,
      glowIntensity: random.nextDouble() * 0.3 + 0.2,
    );
  }

  void update(double animation) {
    x += velocityX * sin(animation * pi * 2);
    y += velocityY * cos(animation * pi * 2);
    opacity += (random.nextDouble() - 0.5) * 0.01;
    opacity = opacity.clamp(0.1, 0.5);

    radius += sin(animation * pi * 4) * 0.1;
    glowRadius = radius * 3 + sin(animation * pi * 2) * radius;
    glowIntensity = (0.2 + sin(animation * pi * 2) * 0.1).clamp(0.1, 0.4);

    if (x < 0) {
      x = 1;
      velocityX = -velocityX;
    } else if (x > 1) {
      x = 0;
      velocityX = -velocityX;
    }

    if (y < 0) {
      y = 1;
      velocityY = -velocityY;
    } else if (y > 1) {
      y = 0;
      velocityY = -velocityY;
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Animation<double> animation;
  final random = Random();

  ParticlePainter({
    required this.particles,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      particle.update(animation.value);

      // Draw particle glow with multiple layers for smooth transition
      final glowPaint = Paint()
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          particle.glowRadius,
        );

      // Outer glow
      glowPaint.color = Colors.white.withOpacity(particle.glowIntensity * 0.1);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.glowRadius * 3,
        glowPaint,
      );

      // Middle glow
      glowPaint.color = Colors.white.withOpacity(particle.glowIntensity * 0.2);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.glowRadius * 2,
        glowPaint,
      );

      // Inner glow
      glowPaint.color = Colors.white.withOpacity(particle.glowIntensity * 0.3);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.glowRadius,
        glowPaint,
      );

      // Core particle
      paint.color = Colors.white.withOpacity(particle.opacity);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius,
        paint,
      );

      // Draw connecting lines with smooth opacity transition
      for (var other in particles) {
        final distance = _calculateDistance(
          particle.x * size.width,
          particle.y * size.height,
          other.x * size.width,
          other.y * size.height,
        );

        if (distance < 100) {
          final opacity = (1 - distance / 100) * 0.15 * particle.opacity;
          canvas.drawLine(
            Offset(particle.x * size.width, particle.y * size.height),
            Offset(other.x * size.width, other.y * size.height),
            Paint()
              ..color = Colors.white.withOpacity(opacity)
              ..strokeWidth = 0.5
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }
  }

  double _calculateDistance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
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
  final Widget? emoji;

  const CustomChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.isAnimating = false,
    this.emoji,
  }) : super(key: key);

  @override
  State<CustomChatBubble> createState() => _CustomChatBubbleState();
}

class _CustomChatBubbleState extends State<CustomChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _slideAnimation = Tween<double>(
      begin: widget.isUser ? 20.0 : -20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_slideAnimation.value, 0),
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: widget.isUser
                                  ? const Color(0xFF1E3A8A).withOpacity(0.25)
                                  : Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: widget.isUser
                                    ? const Color(0xFF1E3A8A).withOpacity(0.95)
                                    : Colors.white.withOpacity(0.98),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: widget.isUser
                                      ? Colors.white.withOpacity(0.15)
                                      : const Color(0xFF1E3A8A)
                                          .withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.message.text,
                                          style: TextStyle(
                                            fontFamily: 'Onest',
                                            color: widget.isUser
                                                ? Colors.white
                                                : const Color(0xFF1E3A8A),
                                            fontSize: 16,
                                            height: 1.5,
                                            letterSpacing: 0.3,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ).animate().fadeIn(
                                              duration: 300.ms,
                                              curve: Curves.easeOut,
                                            ),
                                      ),
                                      if (widget.emoji != null) ...[
                                        const SizedBox(width: 8),
                                        widget.emoji!,
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat('HH:mm')
                                            .format(widget.timestamp),
                                        style: TextStyle(
                                          fontFamily: 'Onest',
                                          color: widget.isUser
                                              ? Colors.white.withOpacity(0.7)
                                              : const Color(0xFF1E3A8A)
                                                  .withOpacity(0.6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (!widget.isUser) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.check_circle,
                                          size: 12,
                                          color: const Color(0xFF1E3A8A)
                                              .withOpacity(0.6),
                                        ).animate().scale(
                                              duration: 200.ms,
                                              delay: 300.ms,
                                              curve: Curves.easeOut,
                                            ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAssistantAvatar() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E40AF),
              const Color(0xFF2563EB),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E40AF).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            'assets/images/blink_logo_white.png',
            width: 20,
            height: 20,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          final profilePictureUrl = profileProvider.profilePictureUrl;

          return Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade400,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: profilePictureUrl != null
                  ? Image.network(
                      profilePictureUrl,
                      fit: BoxFit.cover,
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.person,
                        color: Colors.grey.shade600,
                        size: 18,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
            ),
          );
        },
      ),
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
  bool _isBottomSheetCollapsed = false;
  bool _showQuickActions = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _inputSectionController;
  late AnimationController _sectionTransitionController;
  late AnimationController _backgroundPulseController;
  late Animation<double> _sectionExitAnimation;
  late Animation<double> _sectionEntryAnimation;
  late Animation<double> _backgroundPulseAnimation;
  ConversationState _conversationState = ConversationState.initial;
  TransferSpeed? _selectedSpeed;
  DateTime? _selectedDate;
  final List<ChatMessage> _messages = [];
  String _userName = '';
  final double _advanceAmount = 200.0;
  late Animation<Offset> _inputSectionAnimation;
  String? _bankAccountId = '';
  bool _isLoading = false;
  bool _isTyping = false;
  late AnimationController _confettiController;
  final List<int> _sectionBreaks = [];
  double _previousSectionOffset = 0.0;
  final GlobalKey _confettiKey = GlobalKey();
  int? _animatingMessageIndex;
  bool _isTransitioning = false;
  List<double> _messageOffsets = [];
  final double _collapsedHeight = 80.0;
  final double _expandedHeight = 380.0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserName();
    _addInitialMessage();
  }

  void _initializeControllers() {
    _bankAccountId = widget.bankAccountId;

    // Input section controller for bottom sheet
    _inputSectionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Section transition controller
    _sectionTransitionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Background pulse controller
    _backgroundPulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _inputSectionAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _inputSectionController,
      curve: Curves.easeInOut,
    ));

    _sectionExitAnimation = CurvedAnimation(
      parent: _sectionTransitionController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    );

    _sectionEntryAnimation = CurvedAnimation(
      parent: _sectionTransitionController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
    );

    _backgroundPulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundPulseController,
      curve: Curves.easeInOut,
    ));

    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
  }

  @override
  void dispose() {
    _inputSectionController.dispose();
    _sectionTransitionController.dispose();
    _backgroundPulseController.dispose();
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _toggleBottomSheet() {
    HapticFeedback.selectionClick();
    setState(() {
      _isBottomSheetCollapsed = !_isBottomSheetCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(48),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AppBar(
              toolbarHeight: 48,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leadingWidth: 48,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  height: 32,
                  width: 32,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 0.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white.withOpacity(0.7),
                          size: 14,
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop();
                        },
                        style: ButtonStyle(
                          overlayColor: MaterialStateProperty.all(
                            Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              systemOverlayStyle: SystemUiOverlayStyle.light,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildBackground(),
          ),
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: _buildMessageList(),
                ),
              ),
              if (_showQuickActions) _buildFixedBottomSheet(),
            ],
          ),
        ],
      ),
    );
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
    // Initial delay before starting the conversation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _conversationState = ConversationState.initial;
      });

      // First message - Welcome
      _addMessage(ChatMessage(
        text: 'Welcome back, $_userName! 👋',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.sparkles, size: 24),
      ));

      // Second message - After 3 seconds
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (!mounted) return;

        // Add subtle haptic feedback
        HapticFeedback.selectionClick();

        _addMessage(ChatMessage(
          text:
              'Are you looking for Extra Cash? You can get a \$200 Advance right now! 💫',
          isUser: false,
          timestamp: DateTime.now(),
          emoji: AnimatedEmoji(AnimatedEmojis.moneyWithWings, size: 24),
        ));

        // Third message - After another 3 seconds
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (!mounted) return;

          // Add subtle haptic feedback
          HapticFeedback.selectionClick();

          _addMessage(ChatMessage(
            text: 'How quickly would you like to receive your funds?',
            isUser: false,
            timestamp: DateTime.now(),
            emoji: AnimatedEmoji(AnimatedEmojis.rocket, size: 24),
          ));

          // Show speed selection options after 3 seconds
          Future.delayed(const Duration(milliseconds: 3000), () {
            if (!mounted) return;

            // Add medium haptic feedback for the transition
            HapticFeedback.mediumImpact();

            setState(() {
              _conversationState = ConversationState.speedSelection;
              _showQuickActions = true;
            });

            // Animate the bottom sheet smoothly
            _inputSectionController.forward();
          });
        });
      });
    });
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade800,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: List.generate(3, (index) {
                return Container(
                  margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade300.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(),
                    )
                    .scale(
                      duration: 600.ms,
                      delay: (index * 200).ms,
                      begin: Offset(0.5, 0.5),
                      end: Offset(1, 1),
                    )
                    .fadeIn(
                      duration: 200.ms,
                      delay: (index * 200).ms,
                    );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedBottomSheet() {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight =
        screenHeight * 0.2 * 1.2; // 1/5 of screen height * 1.2 for extra height

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: _isBottomSheetCollapsed ? 60 : bottomSheetHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onVerticalDragEnd: (details) {
                      if (details.primaryVelocity! > 0) {
                        if (!_isBottomSheetCollapsed) _toggleBottomSheet();
                      } else if (details.primaryVelocity! < 0) {
                        if (_isBottomSheetCollapsed) _toggleBottomSheet();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getBottomSheetTitle(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                fontFamily: 'Onest',
                              ),
                            ).animate().fadeIn(
                                  duration: 400.ms,
                                  curve: Curves.easeOut,
                                ),
                            const SizedBox(height: 12),
                            _buildBottomSheetContent(),
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
      ),
    );
  }

  String _getBottomSheetTitle() {
    switch (_conversationState) {
      case ConversationState.speedSelection:
        return 'Select Transfer Speed';
      case ConversationState.dateSelection:
        return 'Select Repayment Date';
      case ConversationState.summary:
        return 'Confirm Advance';
      default:
        return '';
    }
  }

  Widget _buildBottomSheetContent() {
    switch (_conversationState) {
      case ConversationState.speedSelection:
        return Row(
          children: [
            Expanded(
              child: _buildCompactActionButton(
                onTap: () => _handleSpeedSelection(TransferSpeed.instant),
                title: 'Instant',
                subtitle: 'Minutes',
                amount: '\$25.00',
                emoji: AnimatedEmoji(AnimatedEmojis.electricity, size: 22),
                gradientColors: [
                  Color(0xFF9C27B0),
                  Color(0xFF7B1FA2),
                ],
                isHighlighted: true,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildCompactActionButton(
                onTap: () => _handleSpeedSelection(TransferSpeed.standard),
                title: 'Standard',
                subtitle: '1-3 days',
                amount: '\$20.00',
                emoji: AnimatedEmoji(AnimatedEmojis.alarmClock, size: 22),
                gradientColors: [
                  Color(0xFF1E88E5),
                  Color(0xFF1976D2),
                ],
              ),
            ),
          ],
        );
      case ConversationState.dateSelection:
        return Row(
          children: [
            Expanded(
              child: _buildCompactActionButton(
                onTap: () => _handleDateSelection(RepaymentDate.sevenDays),
                title: '7 Days',
                subtitle: 'Save 10% on fees',
                amount: '\$20.00',
                emoji: AnimatedEmoji(AnimatedEmojis.moneyWithWings, size: 22),
                gradientColors: [
                  Color(0xFF43A047),
                  Color(0xFF2E7D32),
                ],
                isHighlighted: true,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildCompactActionButton(
                onTap: () => _handleDateSelection(RepaymentDate.fifteenDays),
                title: '15 Days',
                subtitle: 'More flexibility',
                amount: '\$25.00',
                emoji: AnimatedEmoji(AnimatedEmojis.alarmClock, size: 22),
                gradientColors: [
                  Color(0xFF5E35B1),
                  Color(0xFF4527A0),
                ],
              ),
            ),
          ],
        );
      case ConversationState.summary:
        return Row(
          children: [
            Expanded(
              child: _buildCompactActionButton(
                onTap: () => _handleConfirmation(true),
                title: 'Confirm',
                subtitle: 'Process advance',
                amount: '\$200.00',
                emoji: AnimatedEmoji(AnimatedEmojis.checkMark, size: 22),
                gradientColors: [
                  Color(0xFF43A047),
                  Color(0xFF2E7D32),
                ],
                isHighlighted: true,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildCompactActionButton(
                onTap: () => _handleConfirmation(false),
                title: 'Cancel',
                subtitle: 'Exit process',
                amount: '',
                emoji: AnimatedEmoji(AnimatedEmojis.crossMark, size: 22),
                gradientColors: [
                  Color(0xFFE53935),
                  Color(0xFFC62828),
                ],
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCompactActionButton({
    required VoidCallback onTap,
    required String title,
    required String subtitle,
    required String amount,
    required AnimatedEmoji emoji,
    required List<Color> gradientColors,
    bool isHighlighted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(isHighlighted ? 0.3 : 0.15),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    emoji,
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ),
                  ],
                ),
                if (amount.isNotEmpty) ...[
                  SizedBox(height: 6),
                  Text(
                    amount,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Onest',
                    ),
                  ),
                ],
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Onest',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().scale(
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildHomeButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.home_rounded,
                  size: 24,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(width: 12),
                Text(
                  'Return to Home',
                  style: TextStyle(
                    fontFamily: 'Onest',
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 400.ms,
          curve: Curves.easeOut,
        )
        .scale(
          duration: 400.ms,
          curve: Curves.easeOut,
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
        );
  }

  void _handleSpeedSelection(TransferSpeed speed) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSpeed = speed;
      _showQuickActions = false;
      _inputSectionController.reverse();
    });

    // Add user message immediately
    _addMessage(ChatMessage(
      text: speed == TransferSpeed.instant
          ? "I'd like to receive my funds instantly with the \$25.00 fee. ⚡️"
          : "I'll go with the Standard Transfer for \$20.00. 📅",
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // First assistant response after 3 seconds
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      _addMessage(ChatMessage(
        text: speed == TransferSpeed.instant
            ? "Perfect! Your \$200 advance will be available in your account within minutes. 🚀"
            : "Good choice! Your \$200 advance will be processed and arrive in 1-3 business days. ⏱️",
        isUser: false,
        timestamp: DateTime.now(),
      ));

      // Second assistant response after another 3 seconds
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (!mounted) return;
        _addMessage(ChatMessage(
          text:
              "Now, let's pick your repayment date. Choose 7 days for a 10% fee discount! 💫",
          isUser: false,
          timestamp: DateTime.now(),
          emoji: AnimatedEmoji(AnimatedEmojis.alarmClock, size: 24),
        ));

        // Show date selection options after the last message
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (!mounted) return;
          setState(() {
            _conversationState = ConversationState.dateSelection;
            _showQuickActions = true;
          });
        });
      });
    });
  }

  void _handleDateSelection(RepaymentDate date) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = date == RepaymentDate.sevenDays
          ? DateTime.now().add(Duration(days: 7))
          : DateTime.now().add(Duration(days: 15));
      _showQuickActions = false;
    });

    // Add user message immediately
    _addMessage(ChatMessage(
      text: date == RepaymentDate.sevenDays
          ? "I'll repay in 7 days and save 10% on fees! 💰"
          : "I'll take 15 days for more flexibility with repayment. 📅",
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // First assistant response after 3 seconds
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      _addMessage(ChatMessage(
        text: date == RepaymentDate.sevenDays
            ? "Great choice! You'll save money with the 7-day repayment. 🎯"
            : "Perfect! You'll have more time to manage your repayment. ⏳",
        isUser: false,
        timestamp: DateTime.now(),
      ));

      // Second assistant response after another 3 seconds
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (!mounted) return;
        _showAdvanceSummary();

        // Show confirmation options after the summary
        Future.delayed(const Duration(milliseconds: 3000), () {
          if (!mounted) return;
          setState(() {
            _conversationState = ConversationState.summary;
            _showQuickActions = true;
          });
        });
      });
    });
  }

  Future<void> _processAdvance() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      if (!mounted) return;

      _addMessage(ChatMessage(
        text: "Great! Your \$200 advance has been approved! 🎉\n\n"
            "${_selectedSpeed == TransferSpeed.instant ? 'Your funds will be in your account within minutes. ⚡️' : 'Your funds will arrive in 1-3 business days. 📅'}\n\n"
            "Thanks for using Blink! Need anything else? Just let me know. 💫",
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.partyPopper, size: 24),
      ));

      Future.delayed(Duration(milliseconds: 5200), () {
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    } catch (e) {
      if (!mounted) return;

      _addMessage(ChatMessage(
        text:
            "We encountered an issue processing your advance. Please try again or contact support if the problem persists.",
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.thinkingFace, size: 24),
      ));
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleCancellation() {
    _addMessage(ChatMessage(
      text: "I'd like to cancel this advance request.",
      isUser: true,
      timestamp: DateTime.now(),
    ));

    Future.delayed(Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _addMessage(ChatMessage(
        text:
            "No problem at all! Feel free to come back whenever you need a cash advance. Have a great day! ✨",
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.wave, size: 24),
      ));

      Future.delayed(Duration(milliseconds: 5200), () {
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    });
  }

  void _showAdvanceSummary() {
    final baseFee = _selectedSpeed == TransferSpeed.instant ? 25.00 : 20.00;
    final isSevenDayRepayment =
        _selectedDate!.difference(DateTime.now()).inDays <= 7;
    final feeDiscount = isSevenDayRepayment ? 0.1 : 0.0;
    final finalFee = baseFee * (1 - feeDiscount);

    _addMessage(ChatMessage(
      text: """Here's your advance summary ✨

💰 Amount: \$200
⚡️ Transfer: ${_selectedSpeed == TransferSpeed.instant ? 'Instant' : 'Standard'}
💵 Fee: \$${finalFee.toStringAsFixed(2)}${isSevenDayRepayment ? ' (with 10% discount)' : ''}
📅 Repayment: ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}

Ready to proceed?""",
      isUser: false,
      timestamp: DateTime.now(),
      emoji: AnimatedEmoji(AnimatedEmojis.sparkles, size: 24),
    ));
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
      _animatingMessageIndex = _messages.length - 1;
      _messageOffsets.add(0.0);

      // Only mark section breaks for user messages
      if (message.isUser) {
        _sectionBreaks.add(_messages.length - 1);
      }
    });

    // For user messages, don't animate previous section
    if (message.isUser) {
      _scrollToBottom();
    } else {
      // For assistant messages, show typing indicator and delayed appearance
      setState(() => _isTyping = true);

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() => _isTyping = false);

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _scrollToBottom();
        });
      });
    }
  }

  Widget _buildMessageList() {
    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(
            top: 24,
            bottom: 150,
            left: 16,
            right: 16,
          ),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final message = _messages[index];
            final isAnimating = _animatingMessageIndex == index;

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: 1.0,
              child: CustomChatBubble(
                message: message,
                isUser: message.isUser,
                timestamp: message.timestamp,
                isAnimating: isAnimating,
              ),
            );
          },
        ),
        if (_isTyping)
          Positioned(
            bottom: 16,
            left: 16,
            child: _buildTypingIndicator(),
          ),
      ],
    );
  }

  Widget _buildSectionSeparator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0),
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E40AF),
            const Color(0xFF1E3A8A),
            const Color(0xFF2563EB),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      final extraPadding = _showQuickActions
          ? (_conversationState == ConversationState.dateSelection
              ? 340.0
              : 200.0)
          : 0.0;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + extraPadding,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handleConfirmation(bool confirmed) {
    if (confirmed) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF061535),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 32,
                      width: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.9)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Processing your advance...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      _processAdvance();
    } else {
      _handleCancellation();
    }
  }
}
