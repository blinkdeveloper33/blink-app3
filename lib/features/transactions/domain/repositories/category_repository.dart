import '../models/categories/transaction_category.dart';
import '../models/categories/category_rule.dart';
import '../models/categories/smart_tag.dart';

/// Repository interface for managing transaction categories
abstract class CategoryRepository {
  /// Get all categories
  Future<List<TransactionCategory>> getAllCategories();

  /// Get category by ID
  Future<TransactionCategory?> getCategoryById(String id);

  /// Create a new category
  Future<TransactionCategory> createCategory(TransactionCategory category);

  /// Update an existing category
  Future<TransactionCategory> updateCategory(TransactionCategory category);

  /// Delete a category
  Future<void> deleteCategory(String id);

  /// Get all category rules
  Future<List<CategoryRule>> getAllRules();

  /// Get rule by ID
  Future<CategoryRule?> getRuleById(String id);

  /// Create a new rule
  Future<CategoryRule> createRule(CategoryRule rule);

  /// Update an existing rule
  Future<CategoryRule> updateRule(CategoryRule rule);

  /// Delete a rule
  Future<void> deleteRule(String id);

  /// Get all smart tags
  Future<List<SmartTag>> getAllTags();

  /// Get tag by ID
  Future<SmartTag?> getTagById(String id);

  /// Create a new tag
  Future<SmartTag> createTag(SmartTag tag);

  /// Update an existing tag
  Future<SmartTag> updateTag(SmartTag tag);

  /// Delete a tag
  Future<void> deleteTag(String id);

  /// Get categories by parent ID
  Future<List<TransactionCategory>> getCategoriesByParentId(String parentId);

  /// Get rules by category ID
  Future<List<CategoryRule>> getRulesByCategoryId(String categoryId);

  /// Get tags by type
  Future<List<SmartTag>> getTagsByType(TagType type);

  /// Get recently used categories
  Future<List<TransactionCategory>> getRecentCategories({int limit = 5});

  /// Get frequently used categories
  Future<List<TransactionCategory>> getFrequentCategories({int limit = 5});

  /// Suggest categories for a transaction based on its details
  Future<List<TransactionCategory>> suggestCategories({
    required String merchantName,
    required double amount,
    List<String> description = const [],
  });

  /// Get matching rules for a transaction
  Future<List<CategoryRule>> getMatchingRules({
    required String merchantName,
    required double amount,
    List<String> description = const [],
  });

  /// Update category usage statistics
  Future<void> updateCategoryUsage(String categoryId);

  /// Update rule match statistics
  Future<void> updateRuleMatch(String ruleId);

  /// Update tag usage statistics
  Future<void> updateTagUsage(String tagId);

  /// Import categories from Plaid
  Future<void> importPlaidCategories(
      List<Map<String, dynamic>> plaidCategories);

  /// Export categories to JSON
  Future<Map<String, dynamic>> exportCategories();

  /// Import categories from JSON
  Future<void> importCategories(Map<String, dynamic> data);
}
