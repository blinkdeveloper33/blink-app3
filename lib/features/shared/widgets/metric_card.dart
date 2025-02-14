import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final double? trend;
  final bool? isPositiveTrend;
  final VoidCallback? onTap;

  const MetricCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    this.trend,
    this.isPositiveTrend,
    this.onTap,
  }) : super(key: key);

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;
  static const azureBlue = Color(0xFF0078D4);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) {
        if (widget.onTap != null) {
          setState(() => _isHovered = true);
          _controller.forward();
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.onTap != null) {
            setState(() => _isPressed = true);
          }
        },
        onTapUp: (_) {
          if (widget.onTap != null) {
            setState(() => _isPressed = false);
          }
        },
        onTapCancel: () {
          if (widget.onTap != null) {
            setState(() => _isPressed = false);
          }
        },
        onTap: () {
          if (widget.onTap != null) {
            HapticFeedback.mediumImpact();
            widget.onTap!();
          }
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Color.lerp(
                      Colors.white.withOpacity(0.08),
                      azureBlue.withOpacity(0.15),
                      (_isHovered || _isPressed) ? 0.5 : 0.0,
                    )
                  : Color.lerp(
                      Colors.white,
                      azureBlue.withOpacity(0.08),
                      (_isHovered || _isPressed) ? 0.5 : 0.0,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white
                        .withOpacity((_isHovered || _isPressed) ? 0.15 : 0.1)
                    : Colors.black
                        .withOpacity((_isHovered || _isPressed) ? 0.08 : 0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black
                          .withOpacity((_isHovered || _isPressed) ? 0.3 : 0.2)
                      : Colors.black.withOpacity(
                          (_isHovered || _isPressed) ? 0.08 : 0.05),
                  offset: Offset(0, (_isHovered || _isPressed) ? 8 : 4),
                  blurRadius: (_isHovered || _isPressed) ? 16 : 8,
                ),
              ],
            ),
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.black54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.2,
                                  fontFamily: 'Onest',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.trend != null &&
                                widget.isPositiveTrend != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (widget.isPositiveTrend!
                                            ? Colors.green
                                            : Colors.red)
                                        .withOpacity(isDarkMode ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.isPositiveTrend!
                                            ? Icons.trending_up_rounded
                                            : Icons.trending_down_rounded,
                                        color: widget.isPositiveTrend!
                                            ? Colors.green[400]
                                            : Colors.red[400],
                                        size: 14,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${(widget.trend! * 100).abs().toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: widget.isPositiveTrend!
                                              ? Colors.green[400]
                                              : Colors.red[400],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.2,
                                          fontFamily: 'Onest',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: Text(
                            widget.value,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              fontFamily: 'Onest',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.black45,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                              fontFamily: 'Onest',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
