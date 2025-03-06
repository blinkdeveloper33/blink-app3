import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/transaction_detail.dart';
import '../../domain/models/categories/transaction_category.dart';
import 'category_selector/category_selector_sheet.dart';

class TransactionDetailsSheet extends StatelessWidget {
  final Transaction transaction;
  final TransactionDetail details;
  final bool isDarkMode;
  final Function(TransactionCategory)? onCategoryChanged;

  const TransactionDetailsSheet({
    Key? key,
    required this.transaction,
    required this.details,
    required this.isDarkMode,
    this.onCategoryChanged,
  }) : super(key: key);

  void _showCategorySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => CategorySelectorSheet(
          initialCategory: details.category != null
              ? TransactionCategory.fromJson(details.category!)
              : null,
          onCategorySelected: (category) {
            Navigator.pop(context);
            onCategoryChanged?.call(category);
          },
          // You can add these once you have the data
          // recentCategories: recentCategories,
          // suggestedCategories: suggestedCategories,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A2942) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailsSection(context),
                  const SizedBox(height: 24),
                  _buildMetadataSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');

    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                transaction.merchantName ?? 'Unknown Merchant',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 24,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                currencyFormatter.format(transaction.amount),
                style: TextStyle(
                  color: transaction.isOutflow
                      ? Colors.red[400]
                      : Colors.green[400],
                  fontSize: 32,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Transaction Details'),
        const SizedBox(height: 16),
        _buildDetailRow('Date', DateFormat('MMMM d, y').format(details.date)),
        InkWell(
          onTap: onCategoryChanged != null
              ? () => _showCategorySelector(context)
              : null,
          child: _buildDetailRow(
            'Category',
            details.category?['name'] ?? 'Uncategorized',
            showArrow: onCategoryChanged != null,
          ),
        ),
        if (details.metadata?['description'] != null)
          _buildDetailRow('Description', details.metadata!['description']),
        if (details.metadata?['pending'] == true)
          _buildDetailRow('Status', 'Pending'),
      ],
    );
  }

  Widget _buildMetadataSection() {
    if (details.metadata == null || details.metadata!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Additional Information'),
        const SizedBox(height: 16),
        ...details.metadata!.entries
            .where((entry) =>
                entry.value != null &&
                !['description', 'pending'].contains(entry.key))
            .map((entry) => _buildDetailRow(
                  entry.key
                      .split('_')
                      .map((word) => word.capitalize())
                      .join(' '),
                  entry.value.toString(),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
        fontSize: 18,
        fontFamily: 'Onest',
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool showArrow = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 14,
                fontFamily: 'Onest',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 14,
                fontFamily: 'Onest',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (showArrow)
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDarkMode ? Colors.white60 : Colors.black45,
            ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
