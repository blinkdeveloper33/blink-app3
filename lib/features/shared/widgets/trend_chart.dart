import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TrendChart extends StatefulWidget {
  final String title;
  final List<FlSpot> data;
  final String Function(double) yAxisFormatter;
  final String Function(double) xAxisFormatter;

  const TrendChart({
    Key? key,
    required this.title,
    required this.data,
    required this.yAxisFormatter,
    required this.xAxisFormatter,
  }) : super(key: key);

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _touchedIndex;
  static const azureBlue = Color(0xFF0078D4);
  static const lightAzure = Color(0xFF50B0F0);

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    final minY = widget.data.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = widget.data.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final yInterval = maxY == minY ? 1.0 : (maxY - minY) / 4;

    return Card(
      elevation: 4,
      shadowColor: azureBlue.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: azureBlue,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.info_outline, color: azureBlue),
                    onPressed: () => _showChartInfo(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: constraints.maxHeight - 60,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 4,
                        tooltipBorder: BorderSide(
                          color: azureBlue.withOpacity(0.2),
                          width: 1,
                        ),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            return LineTooltipItem(
                              widget.yAxisFormatter(touchedSpot.y),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '\n${widget.xAxisFormatter(touchedSpot.x)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                      handleBuiltInTouches: true,
                      touchCallback: (event, response) {
                        if (response?.lineBarSpots != null &&
                            response!.lineBarSpots!.isNotEmpty) {
                          setState(() {
                            _touchedIndex = response.lineBarSpots![0].spotIndex;
                          });
                        } else {
                          setState(() {
                            _touchedIndex = null;
                          });
                        }
                      },
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (value) {
                        if (value == 0) {
                          return FlLine(
                            color: azureBlue.withOpacity(0.3),
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        }
                        return FlLine(
                          color: azureBlue.withOpacity(0.1),
                          strokeWidth: 0.5,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) {
                              return Text(
                                widget.yAxisFormatter(value),
                                style: TextStyle(
                                  color: azureBlue.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value % 2 == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  widget.xAxisFormatter(value),
                                  style: TextStyle(
                                    color: azureBlue.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: widget.data,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: azureBlue,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            final isTouched = index == _touchedIndex;
                            return FlDotCirclePainter(
                              radius: isTouched ? 6 : 4,
                              color: isTouched ? azureBlue : lightAzure,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              azureBlue.withOpacity(0.3),
                              azureBlue.withOpacity(0.05),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          cutOffY: 0,
                          applyCutOffY: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _showChartInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: azureBlue.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: azureBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'About Cash Flow Trends',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'This chart shows your net cash flow over time:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  context,
                  '• Rising line indicates positive cash flow',
                  Icons.trending_up,
                  Colors.green[700]!,
                ),
                const SizedBox(height: 8),
                _buildInfoItem(
                  context,
                  '• Falling line shows negative cash flow',
                  Icons.trending_down,
                  Colors.red[700]!,
                ),
                const SizedBox(height: 8),
                _buildInfoItem(
                  context,
                  '• Tap points to see exact values',
                  Icons.touch_app,
                  azureBlue,
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor: azureBlue.withOpacity(0.1),
                    ),
                    child: Text(
                      'Got it',
                      style: TextStyle(
                        color: azureBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 4,
      shadowColor: azureBlue.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: azureBlue,
                  ),
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.show_chart,
              size: 48,
              color: azureBlue.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No data available for this period',
              style: TextStyle(
                color: azureBlue.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
