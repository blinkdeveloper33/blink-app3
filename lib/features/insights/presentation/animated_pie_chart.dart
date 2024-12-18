import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl;

class PieChartSectionData {
  final Color color;
  final double value;
  final String title;
  final double radius;
  final TextStyle titleStyle;

  const PieChartSectionData({
    required this.color,
    required this.value,
    required this.title,
    this.radius = 100,
    this.titleStyle = const TextStyle(color: Colors.white, fontSize: 16),
  });

  PieChartSectionData copyWith({
    Color? color,
    double? value,
    String? title,
    double? radius,
    TextStyle? titleStyle,
  }) {
    return PieChartSectionData(
      color: color ?? this.color,
      value: value ?? this.value,
      title: title ?? this.title,
      radius: radius ?? this.radius,
      titleStyle: titleStyle ?? this.titleStyle,
    );
  }
}

class AnimatedPieChart extends StatelessWidget {
  final List<fl.PieChartSectionData> sections;
  final AnimationController animationController;

  const AnimatedPieChart({
    super.key,
    required this.sections,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return fl.PieChart(
          fl.PieChartData(
            sections: sections.map((section) {
              return fl.PieChartSectionData(
                color: section.color,
                value: section.value * animationController.value,
                title: section.title,
                radius: section.radius * animationController.value,
                titleStyle: section.titleStyle,
              );
            }).toList(),
            sectionsSpace: 0,
            centerSpaceRadius: 40,
            startDegreeOffset: -90,
          ),
        );
      },
    );
  }
}
