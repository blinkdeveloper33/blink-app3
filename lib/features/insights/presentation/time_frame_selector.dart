import 'package:flutter/material.dart';

class TimeFrameSelector extends StatelessWidget {
  final String selectedTimeFrame;
  final Function(String) onChanged;

  const TimeFrameSelector({
    Key? key,
    required this.selectedTimeFrame,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedTimeFrame,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
          iconSize: 24,
          elevation: 16,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontFamily: 'Onest'),
          dropdownColor: const Color(0xFF1C2A4D),
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
