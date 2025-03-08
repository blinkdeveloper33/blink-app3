import 'package:flutter/material.dart';

/// A service that provides utilities for transaction category formatting,
/// color coding, and icon selection.
class CategoryService {
  /// Returns a formatted display category name based on the full category path.
  /// Handles special cases and simplifies complex category names.
  static String formatDisplayCategory(String? category) {
    if (category == null || category.isEmpty) {
      return 'Uncategorized';
    }

    // Special cases for specific categories
    if (category.contains('Airlines and Aviation Services')) {
      return 'Airlines';
    } else if (category.contains('Supermarkets and Groceries')) {
      return 'Groceries';
    } else if (category.contains('Department Stores')) {
      return 'Stores';
    } else if (category.contains('Movies and Theatres')) {
      return 'Movies';
    } else if (category.contains('Professional Services')) {
      return 'Services';
    } else if (category.contains('Telecommunication Services')) {
      return 'Services';
    } else if (category.contains('Streaming Services')) {
      return 'Streaming';
    } else if (category.contains('Gyms and Fitness Centers')) {
      return 'Gym';
    }

    // For all other categories, get the last part of the string
    final parts = category.split(',');
    final lastPart = parts.last.trim();
    return lastPart;
  }

  /// Returns an appropriate color for the given category, with variations based on
  /// dark mode status. Handles both main categories and subcategories with enhanced
  /// visual distinctiveness.
  static Color getCategoryColor(String? category, bool isDarkMode) {
    if (category == null || category.isEmpty) {
      return isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    }

    // Check main category first with distinctive colors
    if (category.contains('Food and Drink')) {
      return Colors.orange[500]!; // Warmer orange
    } else if (category.contains('Auto and Transport')) {
      return Colors.blue[600]!; // Deeper blue
    } else if (category.contains('Travel')) {
      return Colors.purple[500]!; // Rich purple
    } else if (category.contains('Shops')) {
      return Colors.teal[500]!; // Vibrant teal
    } else if (category.contains('Recreation')) {
      return Colors.green[500]!; // Medium green
    } else if (category.contains('Entertainment')) {
      return Colors.deepPurple[400]!; // Deep purple
    } else if (category.contains('Service')) {
      return Colors.amber[600]!; // Amber gold
    } else if (category.contains('Transfer')) {
      return Colors.indigo[500]!; // Strong indigo
    }

    // Then check subcategories with more specific and varied colors
    if (category.contains('Groceries') || category.contains('Supermarkets')) {
      return Colors.green[600]!; // Distinct from general Shopping
    } else if (category.contains('Restaurants')) {
      return Colors.deepOrange[400]!; // Warm restaurant color
    } else if (category.contains('Fast Food')) {
      return Colors.orange[600]!; // Distinct from regular Restaurants
    } else if (category.contains('Coffee')) {
      return Colors.brown[600]!; // Rich coffee brown
    } else if (category.contains('Gas')) {
      return Colors.red[500]!; // Bright red for gas
    } else if (category.contains('Airlines') || category.contains('Aviation')) {
      return Colors.lightBlue[600]!; // Sky blue
    } else if (category.contains('Lodging')) {
      return Colors.purple[400]!; // Softer purple
    } else if (category.contains('Taxi')) {
      return Colors.amber[500]!; // Taxi yellow
    } else if (category.contains('Stores') || category.contains('Department')) {
      return Colors.cyan[600]!; // Strong cyan
    } else if (category.contains('Digital') || category.contains('Purchase')) {
      return Colors.blue[500]!; // Medium blue
    } else if (category.contains('Improvement')) {
      return Colors.brown[500]!; // Woodwork brown
    } else if (category.contains('Pharmacy') ||
        category.contains('Pharmacies')) {
      return Colors.redAccent[700]!; // Medical red
    } else if (category.contains('Streaming')) {
      return Colors.deepPurple[600]!; // Rich purple for entertainment
    } else if (category.contains('Movies') || category.contains('Theatres')) {
      return Colors.pinkAccent[700]!; // Vibrant pink
    } else if (category.contains('Gym') || category.contains('Fitness')) {
      return Colors.lightGreen[700]!; // Strong green
    } else if (category.contains('Insurance')) {
      return Colors.blueGrey[600]!; // Professional blue-grey
    } else if (category.contains('Pet')) {
      return Colors.amber[700]!; // Warm amber
    } else if (category.contains('Professional') ||
        category.contains('Telecommunication')) {
      return Colors.indigo[600]!; // Professional indigo
    }

    // Default color
    return isDarkMode ? Colors.teal[300]! : Colors.teal[800]!;
  }

  /// Returns an appropriate icon for the given category with enhanced specificity.
  /// Handles both main categories and subcategories with more distinctive icons.
  static IconData getCategoryIcon(String? category) {
    if (category == null || category.isEmpty) {
      return Icons.category;
    }

    // Check main category first with improved icons
    if (category.contains('Food and Drink')) {
      return Icons.restaurant;
    } else if (category.contains('Auto and Transport')) {
      return Icons.directions_car;
    } else if (category.contains('Travel')) {
      return Icons.flight;
    } else if (category.contains('Shops')) {
      return Icons.shopping_bag;
    } else if (category.contains('Recreation')) {
      return Icons.sports_basketball;
    } else if (category.contains('Entertainment')) {
      return Icons.movie_creation;
    } else if (category.contains('Service')) {
      return Icons.miscellaneous_services;
    } else if (category.contains('Transfer')) {
      return Icons.swap_horiz;
    }

    // Then check subcategories with more specific icons - using the exact same icons as in home_screen.dart
    if (category.contains('Groceries') || category.contains('Supermarkets')) {
      return Icons.shopping_basket; // Grocery basket
    } else if (category.contains('Restaurants')) {
      return Icons.restaurant_menu; // Restaurant menu
    } else if (category.contains('Fast Food')) {
      return Icons.fastfood; // Fast food
    } else if (category.contains('Coffee')) {
      return Icons.coffee; // Coffee cup
    } else if (category.contains('Gas')) {
      return Icons.local_gas_station; // Gas pump
    } else if (category.contains('Airlines') || category.contains('Aviation')) {
      return Icons.flight_takeoff; // Airplane taking off
    } else if (category.contains('Lodging')) {
      return Icons.hotel; // Hotel
    } else if (category.contains('Taxi')) {
      return Icons.local_taxi; // Taxi cab
    } else if (category.contains('Stores') || category.contains('Department')) {
      return Icons.store; // Store building
    } else if (category.contains('Digital') || category.contains('Purchase')) {
      return Icons.shopping_bag; // Shopping bag
    } else if (category.contains('Improvement')) {
      return Icons.home_repair_service; // Home improvement
    } else if (category.contains('Pharmacy') ||
        category.contains('Pharmacies')) {
      return Icons.local_pharmacy; // Pharmacy
    } else if (category.contains('Streaming')) {
      return Icons.stream; // Streaming
    } else if (category.contains('Movies') || category.contains('Theatres')) {
      return Icons.theaters; // Movie theater
    } else if (category.contains('Gym') || category.contains('Fitness')) {
      return Icons.fitness_center; // Dumbbell
    } else if (category.contains('Insurance')) {
      return Icons.security; // Security shield
    } else if (category.contains('Pet')) {
      return Icons.pets; // Pet paw
    } else if (category.contains('Professional') ||
        category.contains('Telecommunication')) {
      return Icons.business_center; // Business briefcase
    }

    // Default icon
    return Icons.category;
  }

  /// Builds a widget for displaying a category icon with styling
  /// consistent throughout the app.
  static Widget buildEnhancedCategoryIcon(String? category, bool isDarkMode) {
    final categoryColor = getCategoryColor(category, isDarkMode);
    final categoryIcon = getCategoryIcon(category);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            categoryColor,
            categoryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: categoryColor, // Solid color for better visibility
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          categoryIcon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  /// Formats a payment method string for display (e.g. "credit_card" becomes "Credit Card")
  static String formatPaymentMethod(String? method) {
    if (method == null) return 'Unknown';

    // Format payment method string
    final parts = method.split('_');
    return parts
        .map((part) => part.isNotEmpty
            ? '${part[0].toUpperCase()}${part.substring(1)}'
            : '')
        .join(' ');
  }

  /// Formats an account number to show only the last 4 digits (e.g. "1234567890123456" becomes "•••• 3456")
  static String formatAccountNumber(String accountNumber) {
    // Format account number to show only last 4 digits
    if (accountNumber.length <= 4) return accountNumber;

    final lastFour = accountNumber.substring(accountNumber.length - 4);
    return '•••• $lastFour';
  }
}
