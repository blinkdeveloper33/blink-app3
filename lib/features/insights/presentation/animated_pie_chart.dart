import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl;

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
