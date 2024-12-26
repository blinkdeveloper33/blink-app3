import 'package:flutter/material.dart';

class TimeFrameSelector extends StatelessWidget {
  final String selectedTimeFrame;
  final Function(String) onChanged;
  final bool isDarkMode;

  const TimeFrameSelector({
    super.key,
    required this.selectedTimeFrame,
    required this.onChanged,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedTimeFrame,
          icon: Icon(
            Icons.arrow_drop_down,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          iconSize: 24,
          elevation: 16,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 14,
            fontFamily: 'Onest',
          ),
          dropdownColor: isDarkMode ? const Color(0xFF1C2A4D) : Colors.white,
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: <String>['YTD', 'QTD', 'MTD', 'WTD']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(_formatTimeFrameLabel(value)),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatTimeFrameLabel(String value) {
    switch (value) {
      case 'WTD':
        return 'Week to Date';
      case 'MTD':
        return 'Month to Date';
      case 'QTD':
        return 'Quarter to Date';
      case 'YTD':
        return 'Year to Date';
      default:
        return value;
    }
  }
}
