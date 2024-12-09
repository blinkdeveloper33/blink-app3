import 'package:flutter/material.dart';

class BlinkyAvatar extends StatelessWidget {
  final double size;

  const BlinkyAvatar({
    super.key,
    this.size = 32,
    required bool isAnimating,
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
