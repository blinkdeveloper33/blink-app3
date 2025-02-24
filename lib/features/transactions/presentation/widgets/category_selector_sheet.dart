import 'package:flutter/material.dart';
import 'package:blink_app/features/transactions/domain/models/transaction_category.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;

class CategorySelectorSheet extends StatefulWidget {
  final TransactionCategory? initialCategory;
  final Function(TransactionCategory) onCategorySelected;

  const CategorySelectorSheet({
    Key? key,
    this.initialCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CategorySelectorSheet> createState() => _CategorySelectorSheetState();
}

class _CategorySelectorSheetState extends State<CategorySelectorSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  TransactionCategory? _selectedCategory;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleCategoryTap(TransactionCategory category) {
    haptics.Haptics.vibrate(haptics.HapticsType.light);
    setState(() {
      _selectedCategory = category;
    });
    // Animate the selection
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF141B2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.white38 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'Select Category',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Onest',
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    haptics.Haptics.vibrate(haptics.HapticsType.light);
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.close,
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Categories grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: TransactionCategory.defaultCategories.length,
              itemBuilder: (context, index) {
                final category = TransactionCategory.defaultCategories[index];
                final isSelected = _selectedCategory?.id == category.id;

                return AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isSelected ? _scaleAnimation.value : 1.0,
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onTap: () => _handleCategoryTap(category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? category.color
                                .withOpacity(_isDarkMode ? 0.3 : 0.2)
                            : (_isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected ? category.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: category.color
                                  .withOpacity(_isDarkMode ? 0.2 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              category.icon,
                              color: category.color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 12,
                              fontFamily: 'Onest',
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      haptics.Haptics.vibrate(haptics.HapticsType.light);
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedCategory != null
                        ? () {
                            haptics.Haptics.vibrate(haptics.HapticsType.medium);
                            widget.onCategorySelected(_selectedCategory!);
                            Navigator.of(context).pop();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedCategory?.color ?? Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
