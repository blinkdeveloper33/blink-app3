import 'package:flutter/material.dart';
import '../../../domain/models/categories/transaction_category.dart';
import '../../../domain/models/categories/default_categories.dart';

class CategoryListItem extends StatelessWidget {
  final TransactionCategory category;
  final VoidCallback onTap;
  final bool isSelected;

  const CategoryListItem({
    Key? key,
    required this.category,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? category.color.withOpacity(isDarkMode ? 0.2 : 0.1)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(isDarkMode ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (category.parentId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _getParentCategoryName(category.parentId!),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white60 : Colors.black45,
                          fontSize: 12,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: category.color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getParentCategoryName(String parentId) {
    final parent = DefaultCategories.all.firstWhere(
      (category) => category.id == parentId,
      orElse: () => TransactionCategory(
        id: '',
        name: 'Unknown',
        level: CategoryLevel.main,
        type: CategoryType.other,
        color: Colors.grey,
        icon: Icons.help_outline,
        createdAt: DateTime.now(),
      ),
    );
    return parent.name;
  }
}
