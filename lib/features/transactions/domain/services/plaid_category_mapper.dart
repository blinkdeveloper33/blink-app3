import '../models/categories/transaction_category.dart';
import '../models/categories/default_categories.dart';

/// Service for mapping Plaid categories to internal categories
class PlaidCategoryMapper {
  /// Maps a Plaid category hierarchy to our internal category
  static TransactionCategory? mapFromPlaid(List<String> plaidHierarchy) {
    if (plaidHierarchy.isEmpty) return null;

    // Normalize the hierarchy for matching
    final normalizedHierarchy = plaidHierarchy
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Try to find a match in our default categories
    for (final category in DefaultCategories.all) {
      // Check if any of the category aliases match any level of the Plaid hierarchy
      final matches = category.aliases.any((alias) =>
          normalizedHierarchy.any((h) => h.contains(alias.toLowerCase())));

      if (matches) return category;
    }

    // If no match found, try to map based on the first level of hierarchy
    final topLevel = normalizedHierarchy.first;
    return _mapTopLevelPlaidCategory(topLevel);
  }

  /// Maps the top-level Plaid category to our internal category
  static TransactionCategory? _mapTopLevelPlaidCategory(String topLevel) {
    switch (topLevel) {
      case 'food and drink':
        return DefaultCategories.lifestyle.firstWhere((c) => c.id == 'dining');

      case 'transportation':
        return DefaultCategories.transportation
            .firstWhere((c) => c.id == 'transport');

      case 'payment':
      case 'transfer':
      case 'bank fees':
        return DefaultCategories.financial
            .firstWhere((c) => c.id == 'financial');

      case 'shops':
      case 'recreation':
        return DefaultCategories.lifestyle
            .firstWhere((c) => c.id == 'shopping');

      case 'travel':
        return DefaultCategories.lifestyle
            .firstWhere((c) => c.id == 'entertainment');

      case 'healthcare':
        return DefaultCategories.essential
            .firstWhere((c) => c.id == 'healthcare');

      case 'service':
        return DefaultCategories.essential
            .firstWhere((c) => c.id == 'home_services');

      default:
        return null;
    }
  }

  /// Suggests categories based on merchant name and transaction details
  static List<TransactionCategory> suggestCategories({
    required String merchantName,
    List<String> plaidCategories = const [],
    double? amount,
  }) {
    final suggestions = <TransactionCategory>{};
    final normalizedMerchant = merchantName.toLowerCase().trim();

    // First, try to map from Plaid categories if available
    if (plaidCategories.isNotEmpty) {
      final plaidCategory = mapFromPlaid(plaidCategories);
      if (plaidCategory != null) {
        suggestions.add(plaidCategory);
      }
    }

    // Then, try to match based on merchant name against our category aliases
    for (final category in DefaultCategories.all) {
      final matches = category.aliases.any(
        (alias) => normalizedMerchant.contains(alias.toLowerCase()),
      );

      if (matches) {
        suggestions.add(category);
      }
    }

    // If we have a parent category in suggestions, add its children
    final parentIds = suggestions
        .where((c) => c.level == CategoryLevel.main)
        .map((c) => c.id)
        .toList();

    if (parentIds.isNotEmpty) {
      suggestions.addAll(
        DefaultCategories.all.where((c) => parentIds.contains(c.parentId)),
      );
    }

    // Sort suggestions by level (main categories first, then subcategories)
    final sortedSuggestions = suggestions.toList()
      ..sort((a, b) {
        if (a.level == b.level) {
          return a.name.compareTo(b.name);
        }
        return a.level.index.compareTo(b.level.index);
      });

    return sortedSuggestions;
  }

  /// Maps a merchant name to likely categories based on common patterns
  static List<TransactionCategory> mapFromMerchant(String merchantName) {
    final normalized = merchantName.toLowerCase().trim();
    final suggestions = <TransactionCategory>{};

    // Common merchant patterns
    final patterns = {
      'groceries': [
        'grocery',
        'market',
        'food',
        'supermarket',
        'trader',
        'whole foods'
      ],
      'dining': [
        'restaurant',
        'cafe',
        'coffee',
        'bar',
        'grill',
        'kitchen',
        'pizzeria',
        'bistro',
        'diner'
      ],
      'transport': [
        'uber',
        'lyft',
        'taxi',
        'transit',
        'transport',
        'metro',
        'subway',
        'train',
        'bus'
      ],
      'shopping': [
        'store',
        'shop',
        'mall',
        'retail',
        'outlet',
        'boutique',
        'market'
      ],
      'healthcare': [
        'pharmacy',
        'medical',
        'doctor',
        'hospital',
        'clinic',
        'health',
        'dental',
        'healthcare'
      ],
      'entertainment': [
        'cinema',
        'movie',
        'theater',
        'entertainment',
        'game',
        'netflix',
        'spotify',
        'hulu'
      ],
      'utilities': [
        'utility',
        'electric',
        'water',
        'gas',
        'power',
        'energy',
        'internet',
        'phone',
        'mobile'
      ],
    };

    // Check each pattern against the merchant name
    patterns.forEach((categoryId, keywords) {
      if (keywords.any((k) => normalized.contains(k))) {
        // Find the matching category
        for (final category in DefaultCategories.all) {
          if (category.id == categoryId) {
            suggestions.add(category);
            // If it's a main category, add its subcategories
            if (category.level == CategoryLevel.main) {
              suggestions.addAll(
                DefaultCategories.all.where((c) => c.parentId == category.id),
              );
            }
            break;
          }
        }
      }
    });

    return suggestions.toList();
  }
}
