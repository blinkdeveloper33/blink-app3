import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:blink_app/services/auth_service.dart'
    show AuthService, TransferSpeed;
import 'package:intl/intl.dart';
import 'package:blink_app/features/home/presentation/home_screen.dart';
import 'dart:math' show pi, sin, cos, Random;
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
  final int numberOfParticles = 50;

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
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: ParticlePainter(
                particles: particles,
                animation: _controller,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0E6BA8).withOpacity(0.8),
                      Color(0xFF1A237E).withOpacity(0.6),
                    ],
                    stops: [
                      0.0,
                      _controller.value,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
  });

  factory Particle.random() {
    final random = Random();
    return Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      speed: random.nextDouble() * 0.2 + 0.1,
      theta: random.nextDouble() * 2 * pi,
      radius: random.nextDouble() * 2 + 1,
      color: Colors.white.withOpacity(random.nextDouble() * 0.2),
      opacity: random.nextDouble() * 0.5,
      velocityX: (random.nextDouble() - 0.5) * 0.02,
      velocityY: (random.nextDouble() - 0.5) * 0.02,
    );
  }

  void update(double animation) {
    x += velocityX;
    y += velocityY;
    opacity += (random.nextDouble() - 0.5) * 0.01;
    opacity = opacity.clamp(0.1, 0.5);

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
      paint.color = Colors.white.withOpacity(particle.opacity);

      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity * 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.radius * 2);

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius * 2,
        glowPaint,
      );

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.radius,
        paint,
      );
    }
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
  late Animation<double> _blurAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              margin: EdgeInsets.fromLTRB(
                widget.isUser ? 64 : 0,
                4,
                widget.isUser ? 0 : 64,
                4,
              ),
              child: Row(
                mainAxisAlignment: widget.isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(0.05)
                        ..rotateY(widget.isUser ? -0.05 : 0.05),
                      alignment: widget.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (widget.isUser ? Colors.blue : Colors.white)
                                      .withOpacity(0.08),
                              offset: Offset(0, 4),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                            BoxShadow(
                              color:
                                  (widget.isUser ? Colors.blue : Colors.white)
                                      .withOpacity(0.05),
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: _blurAnimation.value,
                              sigmaY: _blurAnimation.value,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: widget.isUser
                                      ? [
                                          Colors.blue.withOpacity(0.95),
                                          Colors.blue.withOpacity(0.75),
                                        ]
                                      : [
                                          Color(0xFF42A5F5).withOpacity(0.25),
                                          Color(0xFF1976D2).withOpacity(0.15),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: widget.isUser
                                      ? Colors.white.withOpacity(0.2)
                                      : Color(0xFF90CAF9).withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.message.text,
                                          style: TextStyle(
                                            color: widget.isUser
                                                ? Colors.white
                                                : Colors.white
                                                    .withOpacity(0.95),
                                            fontSize: 16,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                      if (widget.emoji != null) ...[
                                        const SizedBox(width: 8),
                                        widget.emoji!,
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('HH:mm')
                                        .format(widget.timestamp),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.isUser) ...[
                    const SizedBox(width: 8),
                    _buildAvatar(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    if (!widget.isUser) return const SizedBox(width: 32);

    return Consumer<ProfileProvider>(
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
                Colors.grey[300]!,
                Colors.grey[400]!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
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
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: Colors.grey[600],
                    size: 20,
                  ),
          ),
        );
      },
    )
        .animate(target: widget.isAnimating ? 1 : 0)
        .shake(duration: 400.ms, rotation: 0.1)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
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
  final List<int> _amountOptions = [300, 250, 200, 175, 150, 125, 100];
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
                        padding:
                            EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
    Future.delayed(Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _conversationState = ConversationState.initial;
      });

      _addMessage(ChatMessage(
        text: 'Hi $_userName!',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.wave, size: 24),
      ));

      Future.delayed(Duration(milliseconds: 800), () {
        if (!mounted) return;
        _addMessage(ChatMessage(
          text: 'How much would you like to borrow today?',
          isUser: false,
          timestamp: DateTime.now(),
          emoji: AnimatedEmoji(AnimatedEmojis.moneyWithWings, size: 24),
        ));

        Future.delayed(Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _conversationState = ConversationState.amountSelection;
            _showQuickActions = true;
            _inputSectionController.forward();
          });
        });
      });
    });
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: List.generate(3, (index) {
                return Container(
                  margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
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

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_conversationState == ConversationState.amountSelection)
              _buildAmountOptions(),
            if (_conversationState == ConversationState.speedSelection)
              _buildSpeedOptions(),
            if (_conversationState == ConversationState.dateSelection)
              _buildDateOptions(),
            if (_conversationState == ConversationState.summary)
              _buildConfirmationOptions(),
          ],
        ),
      ),
    );
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
      _animatingMessageIndex = _messages.length - 1;
    });
    _scrollToBottom();
  }

  Widget _buildAmountOptions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ..._amountOptions.map((amount) {
          return MouseRegion(
            onEnter: (_) => HapticFeedback.lightImpact(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleAmountSelection(amount.toString()),
                  borderRadius: BorderRadius.circular(24),
                  splashColor: Colors.white.withOpacity(0.1),
                  highlightColor: Colors.white.withOpacity(0.2),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.withOpacity(0.8),
                          Colors.blue.shade600.withOpacity(0.9),
                          Colors.blue.shade800.withOpacity(0.8),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        Text(
                          amount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    duration: 200.ms,
                    curve: Curves.easeOut,
                    begin: Offset(0.95, 0.95),
                    end: Offset(1, 1),
                  )
                  .fadeIn(duration: 200.ms, curve: Curves.easeOut),
            ),
          );
        }).toList(),
        // Info Button
        MouseRegion(
          onEnter: (_) => HapticFeedback.lightImpact(),
          child: Container(
            width: 108, // Match amount button width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      title: Text(
                        'Blink Advance Information',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: Text(
                        'Blink Advance allows you to access funds before your next paycheck. The amount you can borrow depends on your account history and available balance.',
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Got it'),
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.white.withOpacity(0.2),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange.withOpacity(0.8),
                        Colors.orange.shade600.withOpacity(0.9),
                        Colors.deepOrange.shade700.withOpacity(0.8),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .scale(
                  duration: 200.ms,
                  curve: Curves.easeOut,
                  begin: Offset(0.95, 0.95),
                  end: Offset(1, 1),
                )
                .fadeIn(duration: 200.ms, curve: Curves.easeOut),
          ),
        ),
        // Cancel Button
        MouseRegion(
          onEnter: (_) => HapticFeedback.lightImpact(),
          child: Container(
            width: 108, // Match amount button width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(24),
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.white.withOpacity(0.2),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.withOpacity(0.8),
                        Colors.red.shade600.withOpacity(0.9),
                        Colors.red.shade800.withOpacity(0.8),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .scale(
                  duration: 200.ms,
                  curve: Curves.easeOut,
                  begin: Offset(0.95, 0.95),
                  end: Offset(1, 1),
                )
                .fadeIn(duration: 200.ms, curve: Curves.easeOut),
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

  Widget _buildSpeedOptions() {
    return Row(
      children: [
        Expanded(
          child: MouseRegion(
            onEnter: (_) => HapticFeedback.lightImpact(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleSpeedSelection(TransferSpeed.instant),
                  borderRadius: BorderRadius.circular(24),
                  splashColor: Colors.white.withOpacity(0.1),
                  highlightColor: Colors.white.withOpacity(0.2),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.purple.withOpacity(0.8),
                          Colors.purple.shade600.withOpacity(0.9),
                          Colors.deepPurple.shade700.withOpacity(0.8),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedEmoji(AnimatedEmojis.electricity, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Instant',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '\$8.99',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'In minutes',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    duration: 200.ms,
                    curve: Curves.easeOut,
                    begin: Offset(0.95, 0.95),
                    end: Offset(1, 1),
                  )
                  .fadeIn(duration: 200.ms, curve: Curves.easeOut),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: MouseRegion(
            onEnter: (_) => HapticFeedback.lightImpact(),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleSpeedSelection(TransferSpeed.standard),
                  borderRadius: BorderRadius.circular(24),
                  splashColor: Colors.white.withOpacity(0.1),
                  highlightColor: Colors.white.withOpacity(0.2),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.withOpacity(0.8),
                          Colors.blue.shade600.withOpacity(0.9),
                          Colors.blue.shade800.withOpacity(0.8),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedEmoji(AnimatedEmojis.alarmClock, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Standard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '\$3.99',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '1-3 business days',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    duration: 200.ms,
                    curve: Curves.easeOut,
                    begin: Offset(0.95, 0.95),
                    end: Offset(1, 1),
                  )
                  .fadeIn(duration: 200.ms, curve: Curves.easeOut),
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

  Widget _buildDateOptions() {
    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => HapticFeedback.lightImpact(),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showDatePicker,
                borderRadius: BorderRadius.circular(24),
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.white.withOpacity(0.2),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.withOpacity(0.8),
                        Colors.purple.shade600.withOpacity(0.9),
                        Colors.deepPurple.shade700.withOpacity(0.8),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedEmoji(AnimatedEmojis.alarmClock, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Choose Repayment Date',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Select a date within 30 days',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
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
                begin: Offset(0.95, 0.95),
                end: Offset(1, 1),
              )
              .fadeIn(duration: 200.ms, curve: Curves.easeOut),
        ),
        SizedBox(height: 12),
        MouseRegion(
          onEnter: (_) => HapticFeedback.lightImpact(),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(24),
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.2),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white.withOpacity(0.9),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Return to Home',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
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

  void _handleAmountSelection(String amount) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAmount = amount;
      _showQuickActions = false;
      _inputSectionController.reverse();
    });

    _addMessage(ChatMessage(
      text: 'I need \$$amount',
      isUser: true,
      timestamp: DateTime.now(),
    ));

    Future.delayed(Duration(milliseconds: 800), () {
      if (!mounted) return;
      _addMessage(ChatMessage(
        text: 'When do you need these funds?',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.sparkles, size: 24),
      ));

      Future.delayed(Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _conversationState = ConversationState.speedSelection;
          _showQuickActions = true;
          _inputSectionController.forward();
        });
      });
    });
  }

  void _handleSpeedSelection(TransferSpeed speed) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSpeed = speed;
      _showQuickActions = false;
      _inputSectionController.reverse();
    });

    _addMessage(ChatMessage(
      text: 'I prefer the ${speed.toString().split('.').last} transfer option.',
      isUser: true,
      timestamp: DateTime.now(),
    ));

    Future.delayed(Duration(milliseconds: 800), () {
      if (!mounted) return;
      _addMessage(ChatMessage(
        text: speed == TransferSpeed.instant
            ? 'Your money will arrive in minutes!'
            : 'Your money will arrive in 1-2 business days.',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: speed == TransferSpeed.instant
            ? AnimatedEmoji(AnimatedEmojis.electricity, size: 24)
            : AnimatedEmoji(AnimatedEmojis.alarmClock, size: 24),
      ));

      Future.delayed(Duration(milliseconds: 800), () {
        if (!mounted) return;
        _addMessage(ChatMessage(
          text: 'When would you like to repay this advance?',
          isUser: false,
          timestamp: DateTime.now(),
          emoji: AnimatedEmoji(AnimatedEmojis.alarmClock, size: 24),
        ));

        Future.delayed(Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _conversationState = ConversationState.dateSelection;
            _showQuickActions = true;
            _inputSectionController.forward();
          });
        });
      });
    });
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now().add(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
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
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = date;
      _showQuickActions = false;
      _inputSectionController.reverse();
    });

    _addMessage(ChatMessage(
      text: 'I\'ll repay on ${DateFormat('MMMM d, yyyy').format(date)}',
      isUser: true,
      timestamp: DateTime.now(),
    ));

    Future.delayed(Duration(milliseconds: 800), () {
      if (!mounted) return;
      _showAdvanceSummary();

      Future.delayed(Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _conversationState = ConversationState.summary;
          _showQuickActions = true;
          _inputSectionController.forward();
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
      text: 'I want to cancel this advance request.',
      isUser: true,
      timestamp: DateTime.now(),
    ));

    Future.delayed(Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _addMessage(ChatMessage(
        text: 'No problem! Let me know if you need anything else.',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.wave, size: 24),
      ));

      Future.delayed(Duration(milliseconds: 1500), () {
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    });
  }

  Future<void> _processAdvance() async {
    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      if (!mounted) return;

      _addMessage(ChatMessage(
        text: 'Your advance has been processed successfully!',
        isUser: false,
        timestamp: DateTime.now(),
        emoji: AnimatedEmoji(AnimatedEmojis.partyPopper, size: 24),
      ));

      Future.delayed(Duration(milliseconds: 1500), () {
        if (!mounted) return;
        Navigator.of(context).pop();
      });
    } catch (e) {
      if (!mounted) return;

      _addMessage(ChatMessage(
        text:
            'Sorry, there was an error processing your advance. Please try again.',
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
    final fee = _selectedSpeed == TransferSpeed.instant ? 8.99 : 3.99;

    _addMessage(ChatMessage(
      text: '''Here's your advance summary:
      
Amount: \$$_selectedAmount
Transfer: ${_selectedSpeed == TransferSpeed.instant ? 'Instant' : 'Standard'}
Fee: \$${fee.toStringAsFixed(2)}
Repayment: ${DateFormat('MMMM d, yyyy').format(_selectedDate!)}

Would you like to proceed?''',
      isUser: false,
      timestamp: DateTime.now(),
      emoji: AnimatedEmoji(AnimatedEmojis.moneyWithWings, size: 24),
    ));
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

    // Draw dynamic gradient background with seamless transition
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
    );

    paint.shader = gradient.createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    // Draw particles
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

    // Draw touch effect
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
