import 'package:intl/intl.dart';

final _currencyFormatter = NumberFormat.currency(
  symbol: '\$',
  decimalDigits: 2,
);

String formatCurrency(double value) {
  return _currencyFormatter.format(value);
}
