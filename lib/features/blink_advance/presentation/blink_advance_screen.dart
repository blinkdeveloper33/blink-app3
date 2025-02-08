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
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _slideAnimation = Tween<double>(
      begin: widget.isUser ? 50.0 : -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
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
      padding: EdgeInsets.only(
        left: widget.isUser ? 64 : 16,
        right: widget.isUser ? 16 : 64,
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
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.isUser
                                          ? Colors.blue
                                          : Colors.black)
                                      .withOpacity(0.1),
                                  offset: Offset(0, 4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: widget.isUser
                                        ? Colors.blue.shade500.withOpacity(0.9)
                                        : Colors.grey.shade900.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: widget.isUser
                                          ? Colors.blue.shade300
                                          : Colors.grey.shade800,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                color: Colors.white,
                                                fontSize: 16,
                                                height: 1.4,
                                                letterSpacing: 0.2,
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
                                              color:
                                                  Colors.white.withOpacity(0.6),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (!widget.isUser) ...[
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.check_circle,
                                              size: 12,
                                              color: Colors.blue.shade300,
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
        ],
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
  ConversationState _conversationState = ConversationState.initial;
  final List<ChatMessage> _messages = [];
  String _userName = '';
  final double _advanceAmount = 200.0;
  TransferSpeed? _selectedSpeed;
  DateTime? _selectedDate;
  late ScrollController _scrollController;
  int? _animatingMessageIndex;
  bool _isTyping = false;
  final GlobalKey _confettiKey = GlobalKey();
  late AnimationController _fadeController;
  late AnimationController _inputSectionController;
  late Animation<Offset> _inputSectionAnimation;
  String? _bankAccountId = '';
  bool _showQuickActions = false;
  bool _isLoading = false;
  late AnimationController _confettiController;
  late AnimationController _backgroundController;
  late Animation<double> _gradientAnimation;
  late List<BackgroundParticle> _particles;
  final _random = Random();
  double _scrollBlur = 0.0;
  final _maxBlur = 10.0;
  Offset? _touchPosition;
  double _touchIntensity = 0.0;
  final _maxTouchIntensity = 0.8;
  final List<int> _sectionBreaks = [];
  double _previousSectionOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _bankAccountId = widget.bankAccountId;
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _inputSectionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _inputSectionAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _inputSectionController,
      curve: Curves.easeOutExpo,
    ));
    _loadUserName();
    _addInitialMessage();
    _fadeController.forward();
    _scrollController = ScrollController();

    _confettiController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(_backgroundController);

    _particles = List.generate(
      20,
      (index) => BackgroundParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        dx: _random.nextDouble() * 0.2 - 0.1,
        dy: _random.nextDouble() * 0.2 - 0.1,
        size: _random.nextDouble() * 2 + 1,
        alpha: _random.nextDouble() * 0.5 + 0.1,
      ),
    );

    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final velocity = _scrollController.position.activity?.velocity ?? 0.0;
    setState(() {
      _scrollBlur = (velocity.abs() / 1000).clamp(0.0, _maxBlur);
    });
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _touchPosition = details.localPosition;
      _touchIntensity = _maxTouchIntensity;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _touchPosition = null;
      _touchIntensity = 0.0;
    });
  }

  void _handleTapCancel() {
    setState(() {
      _touchPosition = null;
      _touchIntensity = 0.0;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _inputSectionController.dispose();
    _scrollController.dispose();
    _confettiController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _scrollBlur,
                    sigmaY: _scrollBlur,
                  ),
                  child: CustomPaint(
                    painter: BackgroundPainter(
                      gradientAngle: _gradientAnimation.value,
                      particles: _particles,
                      isDarkMode:
                          Theme.of(context).brightness == Brightness.dark,
                      touchPosition: _touchPosition,
                      touchIntensity: _touchIntensity,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
          ConfettiOverlay(
            key: _confettiKey,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(
                          top: 16,
                          bottom: _showQuickActions
                              ? (_conversationState ==
                                      ConversationState.dateSelection
                                  ? 340
                                  : 200)
                              : 20,
                        ),
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isTyping) {
                            return _buildTypingIndicator();
                          }

                          final message = _messages[index];
                          final isLastMessage = index == _messages.length - 1;
                          final isStartOfSection =
                              _sectionBreaks.contains(index - 1);

                          return Column(
                            children: [
                              if (isStartOfSection)
                                Container(
                                  margin: EdgeInsets.symmetric(vertical: 16),
                                  child: Container(
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
                                ),
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: isLastMessage &&
                                          _conversationState ==
                                              ConversationState.dateSelection
                                      ? 16.0
                                      : 0.0,
                                ),
                                child: CustomChatBubble(
                                  message: message,
                                  isUser: message.isUser,
                                  timestamp: message.timestamp,
                                  isAnimating:
                                      _animatingMessageIndex == index &&
                                          !message.isUser,
                                  emoji: message.emoji,
                                )
                                    .animate()
                                    .fadeIn(
                                        duration: 200.ms, curve: Curves.easeOut)
                                    .slideY(
                                      begin: 0.1,
                                      end: 0,
                                      duration: 200.ms,
                                      curve: Curves.easeOut,
                                    ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (_showQuickActions && !_isTyping)
                      SlideTransition(
                        position: _inputSectionAnimation,
                        child: Container(
                          margin: EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.2),
                              ],
                            ),
                          ),
                          child: _buildQuickActionsSection(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
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
    Future.delayed(Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _conversationState = ConversationState.initial;
      });

      _addMessage(ChatMessage(
        text: 'Welcome back, $_userName! 👋',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.sparkles, size: 24),
      ));

      Future.delayed(Duration(milliseconds: 1200), () {
        if (!mounted) return;
        _addMessage(ChatMessage(
          text:
              'Need extra cash? You can get an instant \$200 advance right now! 💫',
          isUser: false,
          timestamp: DateTime.now(),
          emoji: AnimatedEmoji(AnimatedEmojis.moneyWithWings, size: 24),
        ));

        Future.delayed(Duration(milliseconds: 1200), () {
          if (!mounted) return;
          _addMessage(ChatMessage(
            text: 'How quickly would you like to receive your funds?',
            isUser: false,
            timestamp: DateTime.now(),
            emoji: AnimatedEmoji(AnimatedEmojis.rocket, size: 24),
          ));

          Future.delayed(Duration(milliseconds: 1500), () {
            if (!mounted) return;
            setState(() {
              _conversationState = ConversationState.speedSelection;
              _showQuickActions = true;
              _inputSectionController.forward();
            });
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

  Widget _buildQuickActionsSection() {
    if (!_showQuickActions) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.05),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                if (_conversationState == ConversationState.speedSelection)
                  _buildSpeedOptions()
                else if (_conversationState == ConversationState.dateSelection)
                  _buildDateOptions()
                else if (_conversationState == ConversationState.summary)
                  _buildConfirmationOptions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required String title,
    required String subtitle,
    required String amount,
    required AnimatedEmoji emoji,
    required List<Color> gradientColors,
    String? additionalInfo,
    bool isHighlighted = false,
  }) {
    return MouseRegion(
      onEnter: (_) => HapticFeedback.lightImpact(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.2),
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      emoji,
                      SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    amount,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (additionalInfo != null) ...[
                    SizedBox(height: 12),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        additionalInfo,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      )
          .animate()
          .scale(
            duration: 200.ms,
            curve: Curves.easeOut,
            begin: Offset(0.97, 0.97),
            end: Offset(1, 1),
          )
          .fadeIn(duration: 300.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildSpeedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActionButton(
          onTap: () => _handleSpeedSelection(TransferSpeed.instant),
          title: 'Instant Transfer',
          subtitle: 'Funds available in minutes',
          amount: '\$24.99',
          emoji: AnimatedEmoji(AnimatedEmojis.electricity, size: 26),
          gradientColors: [
            Color(0xFF9C27B0),
            Color(0xFF7B1FA2),
            Color(0xFF6A1B9A),
          ],
          additionalInfo: '⚡️ Instant processing',
          isHighlighted: true,
        ),
        SizedBox(height: 16),
        _buildActionButton(
          onTap: () => _handleSpeedSelection(TransferSpeed.standard),
          title: 'Standard Transfer',
          subtitle: '1-3 business days',
          amount: '\$19.99',
          emoji: AnimatedEmoji(AnimatedEmojis.alarmClock, size: 26),
          gradientColors: [
            Color(0xFF1E88E5),
            Color(0xFF1976D2),
            Color(0xFF1565C0),
          ],
          additionalInfo: '💰 Best value option',
        ),
      ],
    )
        .animate()
        .slideY(
          begin: 0.2,
          duration: 600.ms,
          curve: Curves.easeOutQuart,
        )
        .fadeIn(duration: 400.ms);
  }

  Widget _buildDateOptions() {
    final sevenDaysFromNow = DateTime.now().add(Duration(days: 7));
    final fifteenDaysFromNow = DateTime.now().add(Duration(days: 15));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildActionButton(
          onTap: () => _handleDateSelection(sevenDaysFromNow),
          title: '7 Days',
          subtitle: DateFormat('MMMM d, yyyy').format(sevenDaysFromNow),
          amount: '10% OFF',
          emoji: AnimatedEmoji(AnimatedEmojis.alarmClock, size: 26),
          gradientColors: [
            Color(0xFF9C27B0),
            Color(0xFF7B1FA2),
            Color(0xFF6A1B9A),
          ],
          additionalInfo: 'Early Repayment Discount',
          isHighlighted: true,
        ),
        SizedBox(height: 16),
        _buildActionButton(
          onTap: () => _handleDateSelection(fifteenDaysFromNow),
          title: '15 Days',
          subtitle: DateFormat('MMMM d, yyyy').format(fifteenDaysFromNow),
          amount: 'Standard',
          emoji: AnimatedEmoji(AnimatedEmojis.alarmClock, size: 26),
          gradientColors: [
            Color(0xFF1E88E5),
            Color(0xFF1976D2),
            Color(0xFF1565C0),
          ],
        ),
        SizedBox(height: 20),
        TextButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_rounded, size: 20),
          label: Text('Return to Home'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white.withOpacity(0.9),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    )
        .animate()
        .slideY(
          begin: 0.2,
          duration: 600.ms,
          curve: Curves.easeOutQuart,
        )
        .fadeIn(duration: 400.ms);
  }

  Widget _buildConfirmationOptions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleConfirmation(true),
            child: Text('Confirm'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.withOpacity(0.8),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleConfirmation(false),
            child: Text('Cancel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.8),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
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

  void _handleSpeedSelection(TransferSpeed speed) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSpeed = speed;
      _showQuickActions = false;
      _inputSectionController.reverse();
    });

    _addMessage(ChatMessage(
      text: speed == TransferSpeed.instant
          ? "I'd like to receive my funds instantly with the \$24.99 fee. ⚡️"
          : "I'll go with the standard transfer for \$19.99. 📅",
      isUser: true,
      timestamp: DateTime.now(),
    ));

    Future.delayed(Duration(milliseconds: 800), () {
      if (!mounted) return;
      _addMessage(ChatMessage(
        text: speed == TransferSpeed.instant
            ? "Perfect! Your \$200 advance will be available in your account within minutes. 🚀"
            : "Good choice! Your \$200 advance will be processed and arrive in 1-3 business days. ⏱️",
        isUser: false,
        timestamp: DateTime.now(),
      ));

      Future.delayed(Duration(milliseconds: 800), () {
        if (!mounted) return;
        _addMessage(ChatMessage(
          text:
              "Now, let's pick your repayment date. Choose 7 days for a 10% fee discount! 💫",
          isUser: false,
          timestamp: DateTime.now(),
          emoji: AnimatedEmoji(AnimatedEmojis.alarmClock, size: 24),
        ));

        Future.delayed(Duration(milliseconds: 2500), () {
          if (!mounted) return;
          setState(() {
            _conversationState = ConversationState.dateSelection;
          });

          _scrollToBottom();

          Future.delayed(Duration(milliseconds: 300), () {
            if (!mounted) return;
            setState(() {
              _showQuickActions = true;
              _inputSectionController.forward();
            });
          });
        });
      });
    });
  }

  void _handleDateSelection(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = date;
      _showQuickActions = false;
      _inputSectionController.reverse();
    });

    final isSevenDays = date.difference(DateTime.now()).inDays <= 7;
    final baseFee = _selectedSpeed == TransferSpeed.instant ? 24.99 : 19.99;
    final finalFee = isSevenDays ? baseFee * 0.9 : baseFee;

    _addMessage(ChatMessage(
      text:
          "I'll repay on ${DateFormat('MMMM d, yyyy').format(date)}. ${isSevenDays ? "That's with the 10% discount! 🎉" : ""} 📅",
      isUser: true,
      timestamp: DateTime.now(),
    ));

    Future.delayed(Duration(milliseconds: 800), () {
      if (!mounted) return;

      if (isSevenDays) {
        _addMessage(ChatMessage(
          text:
              "Excellent! With the early repayment discount, your fee is reduced to \$${finalFee.toStringAsFixed(2)}. You're saving \$${(baseFee * 0.1).toStringAsFixed(2)}! 🎉",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }

      Future.delayed(Duration(milliseconds: 800), () {
        if (!mounted) return;
        _showAdvanceSummary();

        Future.delayed(Duration(milliseconds: 1000), () {
          if (!mounted) return;
          setState(() {
            _conversationState = ConversationState.summary;
            _showQuickActions = true;
            _inputSectionController.forward();
          });
        });
      });
    });
  }

  void _handleConfirmation(bool confirmed) {
    if (confirmed) {
      setState(() {
        _isLoading = true;
      });
      _processAdvance();
    } else {
      _handleCancellation();
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

  void _showAdvanceSummary() {
    final baseFee = _selectedSpeed == TransferSpeed.instant ? 24.99 : 19.99;
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

      // Mark section breaks for user messages to create conversation chapters
      if (message.isUser) {
        _sectionBreaks.add(_messages.length - 1);
      }
    });

    // Handle section animations
    if (message.isUser) {
      _animatePreviousSection();
    } else {
      // For bot messages, ensure smooth scroll after render
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _animatePreviousSection() {
    if (_scrollController.hasClients) {
      final currentOffset = _scrollController.offset;
      _previousSectionOffset = currentOffset;

      // First phase: Quick scroll to make room for new content
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent +
            60, // Add extra space for visual comfort
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );

      // Second phase: Smooth upward animation of previous section
      Future.delayed(Duration(milliseconds: 150), () {
        if (!mounted) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent +
              120, // Additional space for section separation
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      });
    }
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
}

class BackgroundParticle {
  double x;
  double y;
  double dx;
  double dy;
  double size;
  double alpha;

  BackgroundParticle({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.size,
    required this.alpha,
  });

  void update() {
    x = (x + dx).clamp(0.0, 1.0);
    y = (y + dy).clamp(0.0, 1.0);

    if (x <= 0 || x >= 1) dx = -dx;
    if (y <= 0 || y >= 1) dy = -dy;
  }
}

class BackgroundPainter extends CustomPainter {
  final double gradientAngle;
  final List<BackgroundParticle> particles;
  final bool isDarkMode;
  final Offset? touchPosition;
  final double touchIntensity;

  BackgroundPainter({
    required this.gradientAngle,
    required this.particles,
    required this.isDarkMode,
    this.touchPosition,
    this.touchIntensity = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final gradient = LinearGradient(
      begin: Alignment(
        cos(gradientAngle),
        sin(gradientAngle),
      ),
      end: Alignment(
        cos(gradientAngle + pi),
        sin(gradientAngle + pi),
      ),
      colors: isDarkMode
          ? [
              const Color(0xFF1A237E),
              const Color(0xFF0D47A1),
              const Color(0xFF1565C0),
              const Color(0xFF1A237E),
            ]
          : [
              const Color(0xFF90CAF9),
              const Color(0xFF64B5F6),
              const Color(0xFF42A5F5),
              const Color(0xFF90CAF9),
            ],
      stops: [0.0, 0.3, 0.7, 1.0],
      tileMode: TileMode.mirror,
    ).createShader(Offset.zero & size);

    paint.shader = gradient;
    canvas.drawRect(Offset.zero & size, paint);

    for (final particle in particles) {
      paint.color = Colors.white.withOpacity(particle.alpha);
      canvas.drawCircle(
        Offset(
          particle.x * size.width,
          particle.y * size.height,
        ),
        particle.size,
        paint,
      );
      particle.update();
    }

    if (touchPosition != null && touchIntensity > 0) {
      final touchPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(touchIntensity),
            Colors.white.withOpacity(0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: touchPosition!,
            radius: 100,
          ),
        );

      canvas.drawCircle(
        touchPosition!,
        100,
        touchPaint,
      );
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) =>
      gradientAngle != oldDelegate.gradientAngle ||
      touchPosition != oldDelegate.touchPosition ||
      touchIntensity != oldDelegate.touchIntensity;
}
