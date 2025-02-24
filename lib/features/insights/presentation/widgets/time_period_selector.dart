import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:blink_app/models/time_period.dart';

class TimePeriodSelector extends StatefulWidget {
  final TimePeriod selectedPeriod;
  final Function(TimePeriod) onPeriodChanged;
  final bool isDarkMode;

  const TimePeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.isDarkMode,
  });

  @override
  State<TimePeriodSelector> createState() => _TimePeriodSelectorState();
}

class _TimePeriodSelectorState extends State<TimePeriodSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  bool _isExpanded = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );
    _rotateAnimation =
        Tween<double>(begin: 0, end: 0.5).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _showOverlay();
        _controller.forward();
      } else {
        _hideOverlay();
        _controller.reverse();
      }
    });
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _hideOverlay();
    const azureBlue = Color(0xFF0078D4);

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleExpanded,
              behavior: HitTestBehavior.translucent,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 8,
            right: 20,
            width: 200,
            child: Material(
              color: Colors.transparent,
              child: FadeTransition(
                opacity: _expandAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.1),
                    end: Offset.zero,
                  ).animate(_expandAnimation),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? const Color(0xFF2A2A2A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        ...TimePeriod.values.map((period) {
                          final isSelected = period == widget.selectedPeriod;
                          return InkWell(
                            onTap: () {
                              widget.onPeriodChanged(period);
                              _toggleExpanded();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? azureBlue.withOpacity(0.1)
                                          : widget.isDarkMode
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      period.icon,
                                      size: 16,
                                      color: isSelected
                                          ? azureBlue
                                          : widget.isDarkMode
                                              ? Colors.white54
                                              : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      period.label,
                                      style: TextStyle(
                                        color: isSelected
                                            ? azureBlue
                                            : widget.isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        fontFamily: 'Onest',
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: azureBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: azureBlue,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    const azureBlue = Color(0xFF0078D4);

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleExpanded,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : azureBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  widget.selectedPeriod.icon,
                  size: 16,
                  color: widget.isDarkMode ? Colors.white : azureBlue,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.selectedPeriod.label,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Onest',
                ),
              ),
              const SizedBox(width: 4),
              RotationTransition(
                turns: _rotateAnimation,
                child: Icon(
                  Icons.expand_more_rounded,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
