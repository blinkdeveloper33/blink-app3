import 'dart:math' show pi, sin, cos, Random, sqrt, pow, min;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:blink_app/services/auth_service.dart'
    show AuthService, TransferSpeed;
import 'package:intl/intl.dart';
import 'package:blink_app/features/home/presentation/home_screen.dart';
import 'package:blink_app/widgets/confetti_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:blink_app/widgets/typing_indicator.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:blink_app/providers/profile_provider.dart' show ProfileProvider;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:blink_app/config/api_config.dart';

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

enum RepaymentDate { sevenDays, fourteenDays }

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
                                  ? const Color(0xFF1E3A8A).withOpacity(0.3)
                                  : Colors.black.withOpacity(0.2),
                              blurRadius: 16,
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
                                    ? const Color(0xFF1E3A8A).withOpacity(0.98)
                                    : Colors.white.withOpacity(0.99),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: widget.isUser
                                      ? Colors.white.withOpacity(0.15)
                                      : const Color(0xFF1E3A8A)
                                          .withOpacity(0.1),
                                  width: 1,
                                ),
                                gradient: widget.isUser
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF2563EB)
                                              .withOpacity(0.95),
                                          const Color(0xFF1E3A8A)
                                              .withOpacity(0.95),
                                        ],
                                      )
                                    : null,
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
                                        child: _buildEnhancedMessageText(
                                            widget.message.text, widget.isUser),
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

  Widget _buildEnhancedMessageText(String text, bool isUser) {
    // Define regex patterns to find currency amounts and product names
    final currencyPattern = RegExp(r'\$\d+(\.\d{2})?');
    final productNamePattern = RegExp(r'(InstantBlink|StandardBlink)');
    final datePattern = RegExp(
        r'(January|February|March|April|May|June|July|August|September|October|November|December)\s\d{1,2},\s\d{4}');

    // If no special formatting needed, return basic text
    if (!text.contains('\$') &&
        !text.contains('Blink') &&
        !productNamePattern.hasMatch(text)) {
      return Text(
        text,
        style: TextStyle(
          fontFamily: 'Onest',
          color: isUser ? Colors.white : const Color(0xFF1E3A8A),
          fontSize: 16,
          height: 1.5,
          letterSpacing: 0.3,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // For summary sections with newlines, use RichText with TextSpans
    List<TextSpan> spans = [];

    // Split by newlines to handle multiline text
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // Check for different types of special content in the line
      if (line.contains('Summary:')) {
        // Handle summary heading
        spans.add(TextSpan(
          text: line,
          style: TextStyle(
            fontFamily: 'Onest',
            color: isUser ? Colors.white : const Color(0xFF1E3A8A),
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ));
      } else if (line.startsWith('•')) {
        // Handle bullet points
        String bulletText = line;

        // Check for amount in bullet point
        final amountMatch = currencyPattern.firstMatch(bulletText);
        if (amountMatch != null) {
          String amount = amountMatch.group(0)!;
          int startIndex = bulletText.indexOf(amount);
          int endIndex = startIndex + amount.length;

          spans.add(TextSpan(
            children: [
              TextSpan(
                text: bulletText.substring(0, startIndex),
                style: TextStyle(
                  fontFamily: 'Onest',
                  color: isUser ? Colors.white : const Color(0xFF1E3A8A),
                  fontSize: 16,
                  height: 1.5,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: amount,
                style: TextStyle(
                  fontFamily: 'Onest',
                  color: isUser ? Colors.white : const Color(0xFF0066CC),
                  fontSize: 17,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              TextSpan(
                text: bulletText.substring(endIndex),
                style: TextStyle(
                  fontFamily: 'Onest',
                  color: isUser ? Colors.white : const Color(0xFF1E3A8A),
                  fontSize: 16,
                  height: 1.5,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ));
        } else {
          spans.add(TextSpan(
            text: bulletText,
            style: TextStyle(
              fontFamily: 'Onest',
              color: isUser ? Colors.white : const Color(0xFF1E3A8A),
              fontSize: 16,
              height: 1.5,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w500,
            ),
          ));
        }
      } else if (line.contains("Here's your advance summary:")) {
        // Handle summary title
        spans.add(TextSpan(
          text: line,
          style: TextStyle(
            fontFamily: 'Onest',
            color: isUser ? Colors.white : const Color(0xFF1E3A8A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            height: 1.5,
          ),
        ));
      } else if (line.contains('💰') ||
          line.contains('⚡️') ||
          line.contains('💵') ||
          line.contains('📅') ||
          line.contains('💸')) {
        // Handle icon + amount lines
        String currentLine = line;

        // Format currency and product names
        final amountMatches = currencyPattern.allMatches(currentLine).toList();
        final productMatches =
            productNamePattern.allMatches(currentLine).toList();
        final dateMatches = datePattern.allMatches(currentLine).toList();

        List<Map<String, dynamic>> formatRanges = [];

        // Add currency ranges
        for (var match in amountMatches) {
          formatRanges.add({
            'start': match.start,
            'end': match.end,
            'text': match.group(0),
            'type': 'currency'
          });
        }

        // Add product name ranges
        for (var match in productMatches) {
          formatRanges.add({
            'start': match.start,
            'end': match.end,
            'text': match.group(0),
            'type': 'product'
          });
        }

        // Add date ranges
        for (var match in dateMatches) {
          formatRanges.add({
            'start': match.start,
            'end': match.end,
            'text': match.group(0),
            'type': 'date'
          });
        }

        // Sort by start position
        formatRanges.sort((a, b) => a['start'].compareTo(b['start']));

        if (formatRanges.isEmpty) {
          // No special formatting needed
          spans.add(TextSpan(
            text: currentLine,
            style: TextStyle(
              fontFamily: 'Onest',
              color: isUser ? Colors.white : const Color(0xFF1E3A8A),
              fontSize: 16,
              height: 1.5,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w600,
            ),
          ));
        } else {
          // Need special formatting for parts of this line
          List<TextSpan> lineSpans = [];
          int lastIndex = 0;

          for (var range in formatRanges) {
            // Add text before this special range
            if (range['start'] > lastIndex) {
              lineSpans.add(TextSpan(
                text: currentLine.substring(lastIndex, range['start']),
                style: TextStyle(
                  fontFamily: 'Onest',
                  color: isUser ? Colors.white : const Color(0xFF1E3A8A),
                  fontSize: 16,
                  height: 1.5,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w600,
                ),
              ));
            }

            // Add the special text with its formatting
            TextStyle specialStyle;
            switch (range['type']) {
              case 'currency':
                specialStyle = TextStyle(
                  fontFamily: 'Onest',
                  color: isUser ? Colors.white : const Color(0xFF0066CC),
                  fontSize: 18,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                );
                break;
              case 'product':
                specialStyle = TextStyle(
                  fontFamily: 'Onest',
                  color: isUser ? Colors.white : const Color(0xFF5E35B1),
                  fontSize: 17,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                );
                break;
              case 'date':
                specialStyle = TextStyle(
                  fontFamily: 'Onest',
                  color: isUser ? Colors.white : const Color(0xFF00796B),
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                );
                break;
              default:
                specialStyle = TextStyle(
                  fontFamily: 'Onest',
                  color: isUser ? Colors.white : const Color(0xFF1E3A8A),
                  fontSize: 16,
                  height: 1.5,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w600,
                );
            }

            lineSpans.add(TextSpan(
              text: range['text'],
              style: specialStyle,
            ));

            lastIndex = range['end'];
          }

          // Add text after the last special range
          if (lastIndex < currentLine.length) {
            lineSpans.add(TextSpan(
              text: currentLine.substring(lastIndex),
              style: TextStyle(
                fontFamily: 'Onest',
                color: isUser ? Colors.white : const Color(0xFF1E3A8A),
                fontSize: 16,
                height: 1.5,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w600,
              ),
            ));
          }

          spans.add(TextSpan(children: lineSpans));
        }
      } else if (currencyPattern.hasMatch(line) ||
          productNamePattern.hasMatch(line)) {
        // Handle lines with currency or product names
        String currentLine = line;

        // Format currency and product names
        final amountMatches = currencyPattern.allMatches(currentLine).toList();
        final productMatches =
            productNamePattern.allMatches(currentLine).toList();

        List<Map<String, dynamic>> formatRanges = [];

        // Add currency ranges
        for (var match in amountMatches) {
          formatRanges.add({
            'start': match.start,
            'end': match.end,
            'text': match.group(0),
            'type': 'currency'
          });
        }

        // Add product name ranges
        for (var match in productMatches) {
          formatRanges.add({
            'start': match.start,
            'end': match.end,
            'text': match.group(0),
            'type': 'product'
          });
        }

        // Sort by start position
        formatRanges.sort((a, b) => a['start'].compareTo(b['start']));

        if (formatRanges.isEmpty) {
          // No special formatting needed
          spans.add(TextSpan(
            text: currentLine,
            style: TextStyle(
              fontFamily: 'Onest',
              color: isUser ? Colors.white : const Color(0xFF1E3A8A),
              fontSize: 16,
              height: 1.5,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w600,
            ),
          ));
        } else {
          // Need special formatting for parts of this line
          List<TextSpan> lineSpans = [];
          int lastIndex = 0;

          for (var range in formatRanges) {
            // Add text before this special range
            if (range['start'] > lastIndex) {
              lineSpans.add(TextSpan(
                text: currentLine.substring(lastIndex, range['start']),
                style: TextStyle(
                  fontFamily: 'Onest',
                  color: isUser ? Colors.white : const Color(0xFF1E3A8A),
                  fontSize: 16,
                  height: 1.5,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w600,
                ),
              ));
            }

            // Add the special text with its formatting
            TextStyle specialStyle;
            if (range['type'] == 'currency') {
              specialStyle = TextStyle(
                fontFamily: 'Onest',
                color: isUser
                    ? Colors.white.withOpacity(1.0)
                    : const Color(0xFF0066CC),
                fontSize: 17,
                height: 1.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              );
            } else {
              specialStyle = TextStyle(
                fontFamily: 'Onest',
                color: isUser
                    ? Colors.white.withOpacity(1.0)
                    : const Color(0xFF5E35B1),
                fontSize: 17,
                height: 1.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              );
            }

            lineSpans.add(TextSpan(
              text: range['text'],
              style: specialStyle,
            ));

            lastIndex = range['end'];
          }

          // Add text after the last special range
          if (lastIndex < currentLine.length) {
            lineSpans.add(TextSpan(
              text: currentLine.substring(lastIndex),
              style: TextStyle(
                fontFamily: 'Onest',
                color: isUser ? Colors.white : const Color(0xFF1E3A8A),
                fontSize: 16,
                height: 1.5,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w600,
              ),
            ));
          }

          spans.add(TextSpan(children: lineSpans));
        }
      } else {
        // Regular text line
        spans.add(TextSpan(
          text: line,
          style: TextStyle(
            fontFamily: 'Onest',
            color: isUser ? Colors.white : const Color(0xFF1E3A8A),
            fontSize: 16,
            height: 1.5,
            letterSpacing: 0.3,
            fontWeight: FontWeight.w600,
          ),
        ));
      }

      // Add newline between lines, except for the last line
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildUserAvatar() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          // Only access the profilePictureUrl property
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
  final String? userName;

  const BlinkAdvanceScreen({
    super.key,
    required this.bankAccountId,
    this.userName,
  });

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
  String _userName = 'User';
  final double _advanceAmount = 200.0;
  late Animation<Offset> _inputSectionAnimation;
  String? _bankAccountId;
  String? _bankAccountName;
  bool _isLoadingBankAccount = false;
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
  bool _showExtraPadding = false;
  double _extraPaddingHeight = 600.0;
  bool _hideAllPreviousMessages = false;
  int? _visibleUserMessageIndex;

  @override
  void initState() {
    super.initState();
    _initializeControllers();

    // Initialize bank account ID from constructor
    _bankAccountId = widget.bankAccountId;

    // Only load from API if no bank account ID was provided
    if (_bankAccountId == null || _bankAccountId!.isEmpty) {
      _loadBankAccountDetails();
    } else {
      // If we have a bank account ID, still verify it's valid
      _loadBankAccountDetails().then((_) {
        // If loading fails, the error will be shown to the user
        // If it succeeds, we'll have the latest account details
      });
    }

    // Use the userName passed from the splash screen if available
    if (widget.userName != null && widget.userName!.isNotEmpty) {
      setState(() {
        _userName = widget.userName!;
        debugPrint('Using name from splash screen: $_userName');
      });
      _addInitialMessage();
    } else {
      // Fall back to loading from storage if userName wasn't passed
      _loadUserName().then((_) {
        _addInitialMessage();
      });
    }
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
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
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
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Image.network(
                    Uri.encodeFull(
                        'https://fcmptjhsrbsbuwuctlsr.supabase.co/storage/v1/object/public/assets//BLINK-03-removebg-preview 2.png'),
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
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
    // This method is only called as a fallback if userName wasn't passed from splash screen
    debugPrint('Falling back to loading name from storage');

    // Only use StorageService to get the user's first name
    final storageService = Provider.of<StorageService>(context, listen: false);

    try {
      // Get first name directly from storage
      final storedName = storageService.getFirstName();
      debugPrint('Retrieved first name from storage: $storedName');

      if (!mounted) return;

      // Update state with name or default
      setState(() {
        _userName =
            (storedName != null && storedName.isNotEmpty) ? storedName : 'User';
        debugPrint('Set user name to: $_userName');
      });
    } catch (e) {
      debugPrint('Error retrieving user name: $e');

      if (!mounted) return;

      // Set default name in case of error
      setState(() {
        _userName = 'User';
        debugPrint('Set default user name due to error');
      });
    }
  }

  void _addInitialMessage() {
    // Log the current username to verify it's correct
    debugPrint('Adding initial message with username: $_userName');

    // Initial delay before starting the conversation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _conversationState = ConversationState.initial;
      });

      // First message - Welcome with up-to-date username
      final currentUserName = _userName.isEmpty ? 'User' : _userName;
      debugPrint('Displaying welcome message with name: $currentUserName');

      _addMessage(ChatMessage(
        text: 'Welcome back, $currentUserName! 👋',
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
              'Are you looking for some extra bucks? You can get a \$200 Advance right now!',
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
            text:
                'Tell us, $currentUserName! How quickly would you like to receive your cash?',
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
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(3, (index) {
                    return Container(
                      margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedBottomSheet() {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = _conversationState ==
            ConversationState.dateSelection
        ? screenHeight * 0.2 * 1.2 * 1.2 // 1.2 times higher for date selection
        : screenHeight * 0.2 * 1.2; // normal height for other states

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
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: _isBottomSheetCollapsed ? 60 : bottomSheetHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.18),
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.06),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.25),
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
                            _buildSheetTitle(_getBottomSheetTitle()),
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

  Widget _buildSheetTitle(String title) {
    // Removed the gradient colors and ShaderMask
    // Now using simple white text for all headers
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        fontFamily: 'Onest',
        height: 1.2,
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
        final baseFee = _selectedSpeed == TransferSpeed.instant ? 25.00 : 20.00;
        final discountedFee = baseFee * 0.9; // 10% discount
        return Row(
          children: [
            Expanded(
              child: _buildCompactActionButton(
                onTap: () => _handleDateSelection(RepaymentDate.sevenDays),
                title: '7 Days',
                subtitle: '10% Fee Discount',
                amount: '\$${discountedFee.toStringAsFixed(2)}',
                originalAmount: '\$${baseFee.toStringAsFixed(2)}',
                emoji: AnimatedEmoji(AnimatedEmojis.moneyWithWings, size: 22),
                gradientColors: [
                  Color(0xFF43A047),
                  Color(0xFF2E7D32),
                ],
                isHighlighted: true,
                showDiscount: true,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildCompactActionButton(
                onTap: () => _handleDateSelection(RepaymentDate.fourteenDays),
                title: '14 Days',
                subtitle: 'More flexibility',
                amount: '\$${baseFee.toStringAsFixed(2)}',
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
    String? originalAmount,
    required AnimatedEmoji emoji,
    required List<Color> gradientColors,
    bool isHighlighted = false,
    bool showDiscount = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(isHighlighted ? 0.4 : 0.2),
            blurRadius: 15,
            offset: Offset(0, 4),
            spreadRadius: isHighlighted ? 0 : -2,
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
                color: Colors.white.withOpacity(isHighlighted ? 0.4 : 0.15),
                width: isHighlighted ? 1.5 : 1,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ),
                  ],
                ),
                if (amount.isNotEmpty) ...[
                  SizedBox(height: 8),
                  if (showDiscount && originalAmount != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          originalAmount,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Onest',
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.white.withOpacity(0.7),
                            decorationThickness: 2,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(left: 8),
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-10%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Onest',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                  ],
                  Text(
                    amount,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: showDiscount ? 22 : 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontFamily: 'Onest',
                    ),
                  ),
                ],
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Onest',
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    );
  }

  void _handleSpeedSelection(TransferSpeed speed) {
    // Enhanced haptic feedback for selection
    HapticFeedback.selectionClick();
    HapticFeedback.lightImpact();

    setState(() {
      _selectedSpeed = speed;
      _showQuickActions = false;
      _inputSectionController.reverse();
    });

    // Add user message immediately
    _addMessage(ChatMessage(
      text: speed == TransferSpeed.instant
          ? "I'd like to receive my funds instantly for a \$25 fee."
          : "I'll go with the Standard Transfer for a \$20 fee. 📅",
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // Save the index of this user message
    final int currentUserMessageIndex = _messages.length - 1;

    // Wait for user message to be visible
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;

      // Add extra padding to allow full scrolling off-screen
      setState(() {
        _showExtraPadding = true;
      });

      // Small delay to ensure layout completes
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted) return;

        // Animate entire chat upward to make it disappear
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );

        // First assistant response after chat moves up
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;

          // Hide previous messages except the user's last response
          setState(() {
            _hideAllPreviousMessages = true;
            _visibleUserMessageIndex = currentUserMessageIndex;
            _showExtraPadding = false;
          });

          _addMessage(ChatMessage(
            text: speed == TransferSpeed.instant
                ? "Perfect! Your \$200 Blink Advance will be available in your account within minutes.🚀"
                : "Good choice! Your \$200 Blink Advance will be processed and arrive in 1-3 business days.⏱️",
            isUser: false,
            timestamp: DateTime.now(),
          ));

          // Enhance typing animation and timing
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (!mounted) return;
            _addMessage(ChatMessage(
              text:
                  "Now, let's pick your repayment date. Choose 7 day range for a 10% fee discount!",
              isUser: false,
              timestamp: DateTime.now(),
              emoji: AnimatedEmoji(AnimatedEmojis.alarmClock, size: 24),
            ));

            // Show date selection options with enhanced animation
            Future.delayed(const Duration(milliseconds: 2000), () {
              if (!mounted) return;

              // Add subtle haptic feedback when showing options
              HapticFeedback.selectionClick();

              setState(() {
                _conversationState = ConversationState.dateSelection;
                _showQuickActions = true;
              });

              // Animate bottom sheet appearance
              _inputSectionController.forward();
            });
          });
        });
      });
    });
  }

  void _handleDateSelection(RepaymentDate date) {
    // Enhanced haptic feedback for selection
    HapticFeedback.selectionClick();
    HapticFeedback.lightImpact();

    setState(() {
      _selectedDate = DateTime.now()
          .add(Duration(days: date == RepaymentDate.sevenDays ? 7 : 14));
      _showQuickActions = false;
      _inputSectionController.reverse();
    });

    // Add user message immediately
    _addMessage(ChatMessage(
      text: date == RepaymentDate.sevenDays
          ? "I'll repay in 7 days and save 10% on fees! 💰"
          : "I'll take 14 days for more flexibility with repayment. 📅",
      isUser: true,
      timestamp: DateTime.now(),
    ));

    // Save the index of this user message
    final int currentUserMessageIndex = _messages.length - 1;

    // Wait for user message to be visible
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;

      // Add extra padding to allow full scrolling off-screen
      setState(() {
        _showExtraPadding = true;
      });

      // Small delay to ensure layout completes
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted) return;

        // Animate entire chat upward to make it disappear
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );

        // First assistant response after chat moves up
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;

          // Hide previous messages except the user's last response
          setState(() {
            _hideAllPreviousMessages = true;
            _visibleUserMessageIndex = currentUserMessageIndex;
            _showExtraPadding = false;
          });

          _addMessage(ChatMessage(
            text: date == RepaymentDate.sevenDays
                ? "Great choice! You'll save money with the 7-day repayment. 🎯"
                : "Perfect! You'll have more time to manage your repayment. ⏳",
            isUser: false,
            timestamp: DateTime.now(),
          ));

          // Enhance timing for summary
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (!mounted) return;
            _showAdvanceSummary();

            // Show confirmation options with enhanced animation
            Future.delayed(const Duration(milliseconds: 2000), () {
              if (!mounted) return;

              // Add subtle haptic feedback when showing options
              HapticFeedback.selectionClick();

              setState(() {
                _conversationState = ConversationState.summary;
                _showQuickActions = true;
              });

              // Animate bottom sheet appearance
              _inputSectionController.forward();
            });
          });
        });
      });
    });
  }

  Future<void> _loadBankAccountDetails() async {
    try {
      setState(() {
        _isLoadingBankAccount = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);

      // Use the verified Plaid items endpoint
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/plaid/items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await authService.getToken()}',
        },
      );

      print('Plaid items response status: ${response.statusCode}');
      print('Plaid items response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['items'] is List && data['items'].isNotEmpty) {
          final primaryItem = data['items'][0];
          final accountId = primaryItem['id'];
          final accountName =
              primaryItem['institutionName'] ?? 'Linked Bank Account';

          setState(() {
            _bankAccountId = accountId;
            _bankAccountName = accountName;
          });

          print('Loaded bank account ID: $_bankAccountId');
          print('Loaded bank account name: $_bankAccountName');
        } else {
          throw Exception('No usable Plaid items found.');
        }
      } else {
        throw Exception('Failed to load Plaid items.');
      }
    } catch (e) {
      print('Error loading bank account details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load bank account: ${e.toString().replaceAll('Exception: ', '')}',
            style: const TextStyle(
              fontFamily: 'Onest',
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              // Add mounted check before accessing context
              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );

      _addMessage(ChatMessage(
        text:
            "We encountered an issue processing your advance. Please try again or contact support if the problem persists.\n\nError: ${e.toString().replaceAll('Exception: ', '')}",
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

    // Use consistent logic with _processAdvance
    final isSevenDayRepayment = _selectedDate != null &&
        (_selectedDate!.difference(DateTime.now()).inDays <= 8);

    final feeDiscount = isSevenDayRepayment ? 0.1 : 0.0;
    final discountAmount =
        baseFee * feeDiscount; // Calculate exact discount amount
    final finalFee = baseFee * (1 - feeDiscount);
    final totalRepayment = _advanceAmount + finalFee;
    final blinkType = _selectedSpeed == TransferSpeed.instant
        ? "InstantBlink"
        : "StandardBlink";
    final discountText =
        isSevenDayRepayment ? " (with 10% discount applied)" : "";

    // Updated: Use 14 days instead of 15 for consistency with API
    final repaymentDays = isSevenDayRepayment ? 7 : 14;

    _addMessage(ChatMessage(
      text: """Here's your advance summary:

💰 Advance Amount: \$${_advanceAmount.toStringAsFixed(2)}
⚡️ Transfer Type: $blinkType
${isSevenDayRepayment ? "💯 Discount: \$${discountAmount.toStringAsFixed(2)} (10% off)\n" : ""}💵 Fee: \$${finalFee.toStringAsFixed(2)}$discountText
📅 Repayment Date: ${DateFormat('MMMM d, yyyy').format(_selectedDate!)} ($repaymentDays days)
💸 Total to Repay: \$${totalRepayment.toStringAsFixed(2)}

Ready to proceed with your $blinkType advance?""",
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
          padding: EdgeInsets.only(
            top: 24,
            bottom: _showExtraPadding ? _extraPaddingHeight : 150,
            left: 16,
            right: 16,
          ),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final message = _messages[index];
            final isAnimating = _animatingMessageIndex == index;

            // Add spacing between groups of messages
            final needsExtraSpace = index > 0 &&
                _messages[index].isUser != _messages[index - 1].isUser;
            final topPadding = needsExtraSpace ? 16.0 : 4.0;

            // When hiding previous messages, still show the user's response message at the top
            if (_hideAllPreviousMessages) {
              if (index == _visibleUserMessageIndex ||
                  index >= _messages.length - 2) {
                // No animations to prevent reappearing
                return Padding(
                  padding: EdgeInsets.only(top: topPadding),
                  child: CustomChatBubble(
                    message: message,
                    isUser: message.isUser,
                    timestamp: message.timestamp,
                    isAnimating: isAnimating,
                  ),
                );
              } else {
                return SizedBox.shrink(); // Hide other messages
              }
            }

            // Normal display for messages when not hiding
            return Padding(
              padding: EdgeInsets.only(top: topPadding),
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
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E40AF).withOpacity(0.98),
            const Color(0xFF1E3A8A).withOpacity(0.98),
            const Color(0xFF2563EB).withOpacity(0.98),
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
              ? 420.0 // Increased padding for the taller date selection sheet
              : _conversationState == ConversationState.speedSelection
                  ? 380.0 // Adequate padding for speed selection
                  : 380.0) // Same padding for confirmation sheet
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
      _showAchAuthorizationDialog();
    } else {
      _handleCancellation();
    }
  }

  Future<void> _showAchAuthorizationDialog() async {
    // Calculate fee and total amount
    final baseFee = _selectedSpeed == TransferSpeed.instant ? 25.00 : 20.00;
    final isSevenDayRepayment = _selectedDate != null &&
        (_selectedDate!.difference(DateTime.now()).inDays <= 8);
    final feeDiscount = isSevenDayRepayment ? 0.1 : 0.0;
    final finalFee = baseFee * (1 - feeDiscount);
    final totalRepayment = _advanceAmount + finalFee;

    // Format date for display
    final repaymentDateFormatted =
        DateFormat('MMMM d, yyyy').format(_selectedDate!);

    // Get last 4 digits of account number
    final accountLast4 = _bankAccountName != null
        ? "from $_bankAccountName"
        : "from your linked bank account";

    // Show the dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.98),
                      Colors.white.withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1E88E5),
                            const Color(0xFF1565C0),
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ACH Authorization',
                                  style: TextStyle(
                                    fontFamily: 'Onest',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Required by U.S. Banking Regulations',
                                  style: TextStyle(
                                    fontFamily: 'Onest',
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'Onest',
                                fontSize: 16,
                                height: 1.6,
                                color: const Color(0xFF1E3A8A),
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      'By tapping "I Authorize", I authorize Blink to initiate a ',
                                ),
                                TextSpan(
                                  text: 'one-time electronic debit (ACH) ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: 'of ',
                                ),
                                TextSpan(
                                  text:
                                      '\$${totalRepayment.toStringAsFixed(2)} ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: '$accountLast4 on ',
                                ),
                                TextSpan(
                                  text: '$repaymentDateFormatted.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24),

                          // Transaction details section
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F9FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFD0E2FF),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Transaction Details',
                                  style: TextStyle(
                                    fontFamily: 'Onest',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E3A8A),
                                  ),
                                ),
                                SizedBox(height: 12),
                                _buildDetailRow('Advance Amount',
                                    '\$${_advanceAmount.toStringAsFixed(2)}'),
                                _buildDetailRow('Service Fee',
                                    '\$${finalFee.toStringAsFixed(2)}'),
                                Divider(
                                    height: 20, color: const Color(0xFFD0E2FF)),
                                _buildDetailRow(
                                  'Total Repayment',
                                  '\$${totalRepayment.toStringAsFixed(2)}',
                                  isBold: true,
                                ),
                                _buildDetailRow(
                                  'Repayment Date',
                                  repaymentDateFormatted,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          // Revocation language
                          Text(
                            'You may revoke this authorization by contacting Blink customer support at support@blinkapp.com at least 3 business days before the scheduled debit date.',
                            style: TextStyle(
                              fontFamily: 'Onest',
                              fontSize: 14,
                              color: const Color(0xFF1E3A8A).withOpacity(0.7),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                Navigator.of(context).pop(false);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontFamily: 'Onest',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      const Color(0xFF1E3A8A).withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                Navigator.of(context).pop(true);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'I Authorize',
                                style: TextStyle(
                                  fontFamily: 'Onest',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // Process or cancel based on user's choice
    if (result == true) {
      // Log the authorization
      _logAchAuthorization();

      // Process the advance
      _processAdvance();
    } else {
      // Handle cancellation
      _addMessage(ChatMessage(
        text:
            "I need to review the ACH authorization details before proceeding.",
        isUser: true,
        timestamp: DateTime.now(),
      ));

      Future.delayed(Duration(milliseconds: 1500), () {
        if (!mounted) return;
        _addMessage(ChatMessage(
          text:
              "No problem! Take your time to review the details. You can always restart the process when you're ready.",
          isUser: false,
          timestamp: DateTime.now(),
          emoji: AnimatedEmoji(AnimatedEmojis.thinkingFace, size: 24),
        ));
      });
    }
  }

  // Helper method to build detail rows in the transaction details section
  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Onest',
              fontSize: 14,
              color: const Color(0xFF1E3A8A).withOpacity(0.8),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Onest',
              fontSize: 14,
              color: const Color(0xFF1E3A8A),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Log the ACH authorization for compliance purposes
  void _logAchAuthorization() {
    final baseFee = _selectedSpeed == TransferSpeed.instant ? 25.00 : 20.00;
    final isSevenDayRepayment = _selectedDate != null &&
        (_selectedDate!.difference(DateTime.now()).inDays <= 8);
    final feeDiscount = isSevenDayRepayment ? 0.1 : 0.0;
    final finalFee = baseFee * (1 - feeDiscount);
    final totalRepayment = _advanceAmount + finalFee;

    // This would typically make an API call to log the authorization
    // For now, we'll just print the details
    print('ACH AUTHORIZATION RECORD:');
    print('User: $_userName');
    print('Authorization Time: ${DateTime.now()}');
    print('Amount: \$${totalRepayment.toStringAsFixed(2)}');
    print('Repayment Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}');
    print('Bank Account ID: $_bankAccountId');
    print(
        'Transfer Speed: ${_selectedSpeed == TransferSpeed.instant ? "Instant" : "Standard"}');

    // In a real implementation, you would send this data to your backend
    // to store in your database for compliance purposes
  }

  Future<void> _processAdvance() async {
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _showQuickActions = false;
      _inputSectionController.reverse();
    });

    _addMessage(ChatMessage(
      text: "Please process my Blink Advance!",
      isUser: true,
      timestamp: DateTime.now(),
    ));

    try {
      // First, verify that we have the bank account ID
      if (_bankAccountId == null || _bankAccountId!.isEmpty) {
        throw Exception(
            'No bank account connected. Please link your bank account first.');
      }

      // Get auth token for the API request
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Authentication error. Please log in again.');
      }

      // Calculate actual repayment date from selected date
      final repaymentDate =
          _selectedDate ?? DateTime.now().add(Duration(days: 14));
      final repaymentDateStr = DateFormat('yyyy-MM-dd').format(repaymentDate);

      // Determine transfer speed
      final transferSpeed =
          _selectedSpeed == TransferSpeed.instant ? 'instant' : 'standard';

      // Make API request to create advance
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/cash-advance/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'principal_amount': _advanceAmount,
          'plaid_item_id': _bankAccountId,
          'velocity_type':
              _selectedSpeed == TransferSpeed.instant ? 'instant' : 'standard',
          'repayment_term_days': _selectedDate != null &&
                  (_selectedDate!.difference(DateTime.now()).inDays <= 8)
              ? 7
              : 14,
        }),
      );

      print('Advance API response status: ${response.statusCode}');
      print('Advance API response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Show success message
        _addMessage(ChatMessage(
          text:
              "Great news! Your advance is being processed and funds will be on their way soon. 🎉",
          isUser: false,
          timestamp: DateTime.now(),
          emoji: AnimatedEmoji(AnimatedEmojis.partyPopper, size: 24),
        ));

        // Add short delay before showing next message
        await Future.delayed(Duration(milliseconds: 2000));
        if (!mounted) return;

        // Show confirmation details
        final speedText = _selectedSpeed == TransferSpeed.instant
            ? "Your funds should arrive in your account within minutes."
            : "Your funds should arrive in your account within 1-3 business days.";

        _addMessage(ChatMessage(
          text:
              "We've approved your \$${_advanceAmount.toStringAsFixed(2)} Blink Advance! $speedText",
          isUser: false,
          timestamp: DateTime.now(),
        ));

        // Add short delay before transitioning
        await Future.delayed(Duration(milliseconds: 2500));
        if (!mounted) return;

        // Show confetti animation
        if (_confettiKey.currentContext != null) {
          _confettiController.forward(from: 0.0);
        }

        // Change to completed state
        setState(() {
          _conversationState = ConversationState.completed;
        });

        // Show final message with home button option
        await Future.delayed(Duration(milliseconds: 3000));
        if (!mounted) return;

        _addMessage(ChatMessage(
          text:
              "Your advance has been successfully processed! You're all set. Check your bank account for the deposit and mark your calendar for repayment on ${DateFormat('MMMM d').format(_selectedDate!)}.",
          isUser: false,
          timestamp: DateTime.now(),
          emoji: AnimatedEmoji(AnimatedEmojis.checkMark, size: 24),
        ));

        // Show home button after final message
        await Future.delayed(Duration(milliseconds: 2000));
        if (!mounted) return;

        // Navigate back to home screen after short delay
        Future.delayed(Duration(seconds: 3), () {
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false);
        });
      } else {
        // Handle error response
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Something went wrong. Please try again.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error processing advance: $e');

      if (!mounted) return;

      // Show error in SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to process advance: ${e.toString().replaceAll('Exception: ', '')}',
            style: const TextStyle(
              fontFamily: 'Onest',
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );

      // Show error message in chat
      _addMessage(ChatMessage(
        text:
            "We encountered an issue processing your advance. Please try again or contact support if the problem persists.\n\nError: ${e.toString().replaceAll('Exception: ', '')}",
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
}
