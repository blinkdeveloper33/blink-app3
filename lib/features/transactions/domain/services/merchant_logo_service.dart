import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:blink_app/features/transactions/domain/services/category_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:blink_app/services/api_config.dart';
import 'package:blink_app/features/transactions/domain/models/transaction.dart';

class MerchantLogoService {
  // Keep brandfetch client ID for potential fallback scenarios
  static const String _brandfetchClientId = "1id12_wkWpgV3pKnxQI";
  static final Logger _logger = Logger();

  // Set of merchants that have already failed to prevent repeated attempts
  static final Set<String> _failedMerchants = {};

  // Cache for logo URLs to avoid redundant API calls
  static final Map<String, String> _logoCache = {};

  // Absolute endpoint URL from the new documentation
  static const String _merchantLogosEndpoint =
      "https://blinkbackendproduction-production.up.railway.app/api/merchant-logos";

  // Map of common merchant names to their domains - keep for local fallback
  static final Map<String, String> _knownMerchants = {
    'mcdonalds': 'mcdonalds.com',
    'starbucks': 'starbucks.com',
    'walmart': 'walmart.com',
    'target': 'target.com',
    'amazon': 'amazon.com',
    'uber': 'uber.com',
    'lyft': 'lyft.com',
    'netflix': 'netflix.com',
    'apple': 'apple.com',
    'chase': 'chase.com',
    'bank of america': 'bankofamerica.com',
    'wells fargo': 'wellsfargo.com',
    'citibank': 'citi.com',
    'citi': 'citi.com',
    'costco': 'costco.com',
    'home depot': 'homedepot.com',
    'lowes': 'lowes.com',
    'chevron': 'chevron.com',
    'shell': 'shell.com',
    'exxon': 'exxon.com',
    'safeway': 'safeway.com',
    'kroger': 'kroger.com',
    'verizon': 'verizon.com',
    'att': 'att.com',
    'tmobile': 't-mobile.com',
    't-mobile': 't-mobile.com',
    'spotify': 'spotify.com',
    'doordash': 'doordash.com',
    'grubhub': 'grubhub.com',
    'instacart': 'instacart.com',
    'postmates': 'postmates.com',
    'airbnb': 'airbnb.com',
    'marriott': 'marriott.com',
    'hilton': 'hilton.com',
    'delta': 'delta.com',
    'american airlines': 'aa.com',
    'southwest': 'southwest.com',
    'united': 'united.com',
  };

  // Keep domain guessing logic for fallback scenarios
  static String? _guessDomainFromMerchant(String merchantName) {
    if (merchantName.isEmpty) return null;

    // Normalize the merchant name
    String normalized = merchantName.toLowerCase().trim();
    _logger.d(
        'Trying to find domain for merchant: "$merchantName" (normalized: "$normalized")');

    // 1. Check direct matches in known merchants
    if (_knownMerchants.containsKey(normalized)) {
      String domain = _knownMerchants[normalized]!;
      _logger.d('Found exact match in known merchants: $domain');
      return domain;
    }

    // 2. Check partial matches
    for (var entry in _knownMerchants.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        _logger.d(
            'Found partial match: merchant "$normalized" matched with "${entry.key}" → ${entry.value}');
        return entry.value;
      }
    }

    // 3. If it has a '.com' or similar, it might already be a domain
    if (normalized.contains('.com') ||
        normalized.contains('.org') ||
        normalized.contains('.net')) {
      // Remove spaces if any
      String domain = normalized.replaceAll(' ', '');
      _logger.d('Merchant name appears to be a domain already: $domain');
      return domain;
    }

    // 4. Best guess - remove spaces and special chars, add .com
    String cleaned = normalized
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special chars
        .replaceAll(' ', '') // Remove spaces
        .trim();

    if (cleaned.length > 2) {
      // Ensure it's not too short
      String domain = '$cleaned.com';
      _logger.d('Created best-guess domain: $domain');
      return domain;
    }

    _logger.d('Could not derive domain from merchant: $merchantName');
    return null;
  }

  // Get the logo URL from backend API
  static Future<String> getLogoUrlFromBackend({
    required String merchantName,
    String type = 'icon',
    int width = 80,
    int height = 80,
    bool isDarkMode = false,
  }) async {
    try {
      // Check if this merchant has failed before
      if (_failedMerchants.contains(merchantName)) {
        _logger.d('Skipping previously failed merchant: $merchantName');
        return '';
      }

      // Create cache key
      final cacheKey = '$merchantName-$type-$width-$height-$isDarkMode';

      // Check if we have this logo URL cached
      if (_logoCache.containsKey(cacheKey)) {
        _logger.d('Using cached logo URL for: $merchantName');
        return _logoCache[cacheKey]!;
      }

      // Build the backend API URL with query parameters
      final uri = Uri.parse(_merchantLogosEndpoint).replace(queryParameters: {
        'merchantName': merchantName,
        'type': type,
        'width': width.toString(),
        'height': height.toString(),
        'isDarkMode': isDarkMode.toString(),
      });

      _logger.d('Fetching logo from backend: $uri');

      // Make the HTTP request
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _logger.w('Backend request timed out for merchant: $merchantName');
          return http.Response('Timeout', 408);
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final logoUrl = data['logoUrl'] as String?;

        if (logoUrl != null && logoUrl.isNotEmpty) {
          _logger.i('Got logo URL from backend for $merchantName: $logoUrl');
          // Cache the result
          _logoCache[cacheKey] = logoUrl;
          return logoUrl;
        } else {
          _logger
              .w('Backend returned empty logo URL for merchant: $merchantName');
          _failedMerchants.add(merchantName);
          return '';
        }
      } else {
        _logger.w(
            'Backend returned error ${response.statusCode} for merchant: $merchantName');
        _failedMerchants.add(merchantName);
        return '';
      }
    } catch (e) {
      _logger.e('Error getting logo URL from backend: $e');
      _failedMerchants.add(merchantName);
      return '';
    }
  }

  // Legacy fallback method to get Brandfetch URL directly
  static String getBrandfetchUrl({
    required String merchantName,
    String type = 'icon',
    int width = 80,
    int height = 80,
    bool isDarkMode = false,
  }) {
    try {
      // Try to get domain
      String? domain = _guessDomainFromMerchant(merchantName);

      if (domain == null) {
        _logger.d('Could not determine domain for merchant: $merchantName');
        return '';
      }

      // Check if this domain has failed before
      if (_failedMerchants.contains(merchantName)) {
        _logger.d('Skipping previously failed domain: $merchantName');
        return '';
      }

      // Request the opposite theme for better visibility
      // In dark mode app -> request light logos (visible on dark background)
      // In light mode app -> request dark logos (visible on light background)
      String theme = isDarkMode ? "light" : "dark";

      // Use lettermark as fallback for a clean consistent fallback
      String fallback = "lettermark";

      // Construct URL with the full parameters
      String url =
          'https://cdn.brandfetch.io/$domain/$type/theme/$theme/fallback/$fallback/w/$width/h/$height?c=$_brandfetchClientId';

      _logger.i('Generated Brandfetch URL for $merchantName ($domain): $url');
      return url;
    } catch (e) {
      _logger.e('Error generating Brandfetch URL: $e');
      return '';
    }
  }

  // Mark a merchant as failed to avoid future attempts
  static void markDomainAsFailed(String merchantName) {
    _failedMerchants.add(merchantName);
    _logger.d('Marked merchant as failed: $merchantName');
  }

  // Check if we should attempt to show logo for this merchant
  static bool shouldAttemptLogo(String? merchantName) {
    if (merchantName == null ||
        merchantName.isEmpty ||
        merchantName == 'Unknown Merchant') {
      return false;
    }

    return !_failedMerchants.contains(merchantName);
  }

  // Preload logos for a list of transactions
  static Future<void> preloadLogos(
      List<Transaction> transactions, bool isDarkMode) async {
    if (transactions.isEmpty) return;

    _logger.d('Preloading logos for ${transactions.length} transactions');

    // Extract unique merchant names that we should attempt to load
    final merchantsToLoad = <String>{};
    for (final transaction in transactions) {
      if (transaction.merchantName != null &&
          shouldAttemptLogo(transaction.merchantName)) {
        merchantsToLoad.add(transaction.merchantName!);
      }
    }

    if (merchantsToLoad.isEmpty) {
      _logger.d('No merchant logos to preload');
      return;
    }

    _logger.d('Found ${merchantsToLoad.length} unique merchants to preload');

    // Using Future.wait with a limit of 5 concurrent requests
    final batchSize = 5;
    for (var i = 0; i < merchantsToLoad.length; i += batchSize) {
      final end = (i + batchSize < merchantsToLoad.length)
          ? i + batchSize
          : merchantsToLoad.length;

      final batch = merchantsToLoad.toList().sublist(i, end);

      await Future.wait(batch.map((merchantName) => getLogoUrlFromBackend(
            merchantName: merchantName,
            isDarkMode: isDarkMode,
          ).then((url) {
            if (url.isNotEmpty) {
              _logger.d('Preloaded logo for $merchantName');
            }
            return url;
          }).catchError((e) {
            _logger.w('Error preloading logo for $merchantName: $e');
            return '';
          })));
    }

    _logger.d('Completed preloading merchant logos');
  }

  // Clear logo cache - can be called when theme changes or after a certain time period
  static void clearLogoCache() {
    _logoCache.clear();
    _logger.d('Cleared logo URL cache');
  }
}
