import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';

class AnimatedProgressIndicator extends StatelessWidget {
  final double progress;
  final double size;

  const AnimatedProgressIndicator({
    super.key,
    required this.progress,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          FAProgressBar(
            currentValue: progress * 100,
            size: size,
            animatedDuration: const Duration(milliseconds: 300),
            direction: Axis.vertical,
            verticalDirection: VerticalDirection.up,
            backgroundColor: Colors.grey[300]!,
            progressColor: const Color(0xFF2196F3),
            changeColorValue: 100,
            changeProgressColor: const Color(0xFF1565C0),
            maxValue: 100,
            displayText: '%',
            formatValueFixed: 0,
            borderRadius: BorderRadius.circular(size / 2),
          ),
          Center(
            child: Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
