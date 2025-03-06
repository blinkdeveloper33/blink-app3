import 'package:flutter/material.dart';
import '../../../domain/models/categories/transaction_category.dart';
import '../../../domain/models/categories/default_categories.dart';
import 'category_list_item.dart';

class CategorySearchDelegate extends SearchDelegate<TransactionCategory?> {
  final TransactionCategory? initialCategory;

  CategorySearchDelegate({
    this.initialCategory,
  });

  @override
  String get searchFieldLabel => 'Search categories...';

  @override
  TextStyle? get searchFieldStyle => const TextStyle(
        fontFamily: 'Onest',
        fontSize: 16,
      );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final normalizedQuery = query.toLowerCase();

    if (normalizedQuery.isEmpty) {
      return _buildInitialSuggestions(context);
    }

    final results = DefaultCategories.all.where((category) {
      // Search in name
      if (category.name.toLowerCase().contains(normalizedQuery)) {
        return true;
      }

      // Search in aliases
      if (category.aliases
          .any((alias) => alias.toLowerCase().contains(normalizedQuery))) {
        return true;
      }

      // If it's a subcategory, search in parent category name
      if (category.parentId != null) {
        final parent = DefaultCategories.all.firstWhere(
          (c) => c.id == category.parentId,
          orElse: () => category,
        );
        if (parent.name.toLowerCase().contains(normalizedQuery)) {
          return true;
        }
      }

      return false;
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: isDarkMode ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              'No categories found',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 16,
                fontFamily: 'Onest',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final category = results[index];
        return CategoryListItem(
          category: category,
          onTap: () => close(context, category),
          isSelected: initialCategory?.id == category.id,
        );
      },
    );
  }

  Widget _buildInitialSuggestions(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Main Categories',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 14,
                fontFamily: 'Onest',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final category = DefaultCategories.all
                  .where((c) => c.level == CategoryLevel.main)
                  .toList()[index];
              return CategoryListItem(
                category: category,
                onTap: () => close(context, category),
                isSelected: initialCategory?.id == category.id,
              );
            },
            childCount: DefaultCategories.all
                .where((c) => c.level == CategoryLevel.main)
                .length,
          ),
        ),
      ],
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return theme.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: isDarkMode ? Colors.white60 : Colors.black45,
          fontFamily: 'Onest',
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: theme.primaryColor,
      ),
    );
  }
}
