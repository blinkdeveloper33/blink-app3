import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/categories/transaction_category.dart';
import '../../../domain/models/categories/default_categories.dart';
import 'category_grid_item.dart';
import 'category_list_item.dart';
import 'category_search_delegate.dart';

class CategorySelectorSheet extends StatefulWidget {
  final TransactionCategory? initialCategory;
  final Function(TransactionCategory) onCategorySelected;
  final List<TransactionCategory>? recentCategories;
  final List<TransactionCategory>? suggestedCategories;

  const CategorySelectorSheet({
    Key? key,
    this.initialCategory,
    required this.onCategorySelected,
    this.recentCategories,
    this.suggestedCategories,
  }) : super(key: key);

  @override
  State<CategorySelectorSheet> createState() => _CategorySelectorSheetState();
}

class _CategorySelectorSheetState extends State<CategorySelectorSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  List<TransactionCategory> _filteredCategories = [];
  TransactionCategory? _selectedMainCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filteredCategories = DefaultCategories.all;

    // If initial category is provided and it's a subcategory,
    // select its parent category
    if (widget.initialCategory?.parentId != null) {
      _selectedMainCategory = DefaultCategories.all.firstWhere(
        (category) => category.id == widget.initialCategory!.parentId,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredCategories = DefaultCategories.all;
      } else {
        _filteredCategories = DefaultCategories.all.where((category) {
          return category.name.toLowerCase().contains(_searchQuery) ||
              category.aliases
                  .any((alias) => alias.toLowerCase().contains(_searchQuery));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A2942) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, isDarkMode),
          if (widget.recentCategories != null &&
              widget.recentCategories!.isNotEmpty)
            _buildRecentCategories(isDarkMode),
          if (widget.suggestedCategories != null &&
              widget.suggestedCategories!.isNotEmpty)
            _buildSuggestedCategories(isDarkMode),
          _buildSearchBar(isDarkMode),
          Expanded(
            child: _isSearching
                ? _buildSearchResults(isDarkMode)
                : _buildCategoryTabs(isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
          child: Row(
            children: [
              Text(
                'Select Category',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontFamily: 'Onest',
        ),
        decoration: InputDecoration(
          hintText: 'Search categories...',
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.white60 : Colors.black45,
            fontFamily: 'Onest',
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDarkMode ? Colors.white60 : Colors.black45,
          ),
          filled: true,
          fillColor: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCategories(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Recent',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 14,
              fontFamily: 'Onest',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: widget.recentCategories!.length,
            itemBuilder: (context, index) {
              final category = widget.recentCategories![index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CategoryGridItem(
                  category: category,
                  onTap: () => widget.onCategorySelected(category),
                  isSelected: widget.initialCategory?.id == category.id,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedCategories(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Suggested',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 14,
              fontFamily: 'Onest',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: widget.suggestedCategories!.length,
            itemBuilder: (context, index) {
              final category = widget.suggestedCategories![index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CategoryGridItem(
                  category: category,
                  onTap: () => widget.onCategorySelected(category),
                  isSelected: widget.initialCategory?.id == category.id,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(bool isDarkMode) {
    if (_searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_filteredCategories.isEmpty) {
      return Center(
        child: Text(
          'No categories found',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 16,
            fontFamily: 'Onest',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        final category = _filteredCategories[index];
        return CategoryListItem(
          category: category,
          onTap: () => widget.onCategorySelected(category),
          isSelected: widget.initialCategory?.id == category.id,
        );
      },
    );
  }

  Widget _buildCategoryTabs(bool isDarkMode) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: isDarkMode ? Colors.white : Colors.black87,
          unselectedLabelColor: isDarkMode ? Colors.white60 : Colors.black45,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Grid'),
            Tab(text: 'List'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGridView(isDarkMode),
              _buildListView(isDarkMode),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridView(bool isDarkMode) {
    final mainCategories = DefaultCategories.all
        .where((category) => category.level == CategoryLevel.main)
        .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: mainCategories.length,
      itemBuilder: (context, index) {
        final category = mainCategories[index];
        return CategoryGridItem(
          category: category,
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedMainCategory = category);
            _showSubcategories(category);
          },
          isSelected: _selectedMainCategory?.id == category.id,
        );
      },
    );
  }

  Widget _buildListView(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: DefaultCategories.all.length,
      itemBuilder: (context, index) {
        final category = DefaultCategories.all[index];
        return CategoryListItem(
          category: category,
          onTap: () {
            if (category.level == CategoryLevel.main) {
              setState(() => _selectedMainCategory = category);
              _showSubcategories(category);
            } else {
              widget.onCategorySelected(category);
            }
          },
          isSelected: widget.initialCategory?.id == category.id,
        );
      },
    );
  }

  void _showSubcategories(TransactionCategory mainCategory) {
    final subcategories = DefaultCategories.all
        .where((category) => category.parentId == mainCategory.id)
        .toList();

    if (subcategories.isEmpty) {
      widget.onCategorySelected(mainCategory);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.75,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  mainCategory.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Onest',
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: subcategories.length,
                  itemBuilder: (context, index) {
                    final category = subcategories[index];
                    return CategoryListItem(
                      category: category,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onCategorySelected(category);
                      },
                      isSelected: widget.initialCategory?.id == category.id,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
