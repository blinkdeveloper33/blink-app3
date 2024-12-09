import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    particles = List.generate(20, (index) => Particle());
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
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(particles, _controller.value),
              child: Container(),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double speed;
  late double theta;
  late double radius;

  Particle() {
    restart();
  }

  void restart() {
    x = Random().nextDouble();
    y = Random().nextDouble();
    speed = 0.2 + Random().nextDouble() * 0.2;
    theta = Random().nextDouble() * 2 * pi;
    radius = 1 + Random().nextDouble() * 3;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      var progress = (particle.speed * animationValue) % 1.0;
      var x = particle.x + progress * cos(particle.theta);
      var y = particle.y + progress * sin(particle.theta);

      x = (x + 1) % 1.0;
      y = (y + 1) % 1.0;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.radius,
        paint,
      );

      if (progress > 0.995) {
        particle.restart();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
