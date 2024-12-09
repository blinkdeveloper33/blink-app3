import 'package:flutter/material.dart';

class AmountSlider extends StatefulWidget {
  final Function(int) onChanged;
  final List<int> amounts;

  const AmountSlider({
    Key? key,
    required this.onChanged,
    required this.amounts,
  }) : super(key: key);

  @override
  _AmountSliderState createState() => _AmountSliderState();
}

class _AmountSliderState extends State<AmountSlider> {
  int _currentAmount = 0;

  @override
  void initState() {
    super.initState();
    _currentAmount = widget.amounts[0];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '\$${_currentAmount.toString()}',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.3),
            thumbColor: Theme.of(context).primaryColor,
            overlayColor: Theme.of(context).primaryColor.withOpacity(0.4),
            valueIndicatorColor: Theme.of(context).primaryColor,
            valueIndicatorTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
          ),
          child: Slider(
            min: widget.amounts.first.toDouble(),
            max: widget.amounts.last.toDouble(),
            divisions: widget.amounts.length - 1,
            value: _currentAmount.toDouble(),
            label: '\$${_currentAmount.toString()}',
            onChanged: (double value) {
              setState(() {
                _currentAmount = value.round();
              });
              widget.onChanged(_currentAmount);
            },
          ),
        ),
      ],
    );
  }
}
