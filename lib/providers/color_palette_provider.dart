import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ColorPaletteProvider extends ChangeNotifier {
  // Default gradient colors to use when no profile image or extraction fails
  Color _startColor = const Color(0xFF1A237E); // Indigo
  Color _endColor = const Color(0xFF0D47A1); // Blue

  // Whether colors have been extracted from an image
  bool _hasCustomColors = false;

  // Store the generated palette for potential use of other colors
  PaletteGenerator? _lastPalette;

  // Cache the image URL to avoid re-analyzing the same image
  String? _lastAnalyzedImageUrl;

  // Getters
  Color get startColor => _startColor;
  Color get endColor => _endColor;
  bool get hasCustomColors => _hasCustomColors;
  PaletteGenerator? get lastPalette => _lastPalette;

  // A good middle color for three-stop gradients
  Color get middleColor => _hasCustomColors
      ? Color.lerp(_startColor, _endColor, 0.5)!.withOpacity(0.95)
      : const Color(0xFF0D47A1).withOpacity(0.95);

  // Reset to default colors
  void resetToDefaultColors() {
    _startColor = const Color(0xFF1A237E);
    _endColor = const Color(0xFF0D47A1);
    _hasCustomColors = false;
    _lastPalette = null;
    notifyListeners();
  }

  // Extract colors from a profile image URL
  Future<bool> extractColorsFromProfileImage(String? imageUrl) async {
    // Skip if URL is null or empty or if it's the same as last analyzed image
    if (imageUrl == null ||
        imageUrl.isEmpty ||
        imageUrl == _lastAnalyzedImageUrl) {
      return _hasCustomColors;
    }

    try {
      // Create an ImageProvider from the URL
      final imageProvider = NetworkImage(imageUrl);

      // Generate the palette from the image
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(200, 200), // Reduced size for faster processing
        maximumColorCount: 8, // Get a reasonable number of colors
      );

      // Store the palette for later use
      _lastPalette = paletteGenerator;
      _lastAnalyzedImageUrl = imageUrl;

      // Extract colors intelligently
      _extractAndApplyColors(paletteGenerator);

      return true;
    } catch (e) {
      debugPrint('Error extracting colors from profile image: $e');
      // Keep current colors or reset to defaults based on whether we have custom colors
      if (!_hasCustomColors) {
        resetToDefaultColors();
      }
      return false;
    }
  }

  // Extract and apply the colors from the palette generator
  void _extractAndApplyColors(PaletteGenerator paletteGenerator) {
    // Try to get vibrant colors first as they work best for gradients
    final vibrantColor = paletteGenerator.vibrantColor?.color;
    final darkVibrantColor = paletteGenerator.darkVibrantColor?.color;
    final lightVibrantColor = paletteGenerator.lightVibrantColor?.color;

    // Fallback to dominant colors if vibrant aren't available
    final dominantColor = paletteGenerator.dominantColor?.color;
    final darkDominantColor =
        _findDarkestColor(paletteGenerator.colors.toList());
    final lightDominantColor =
        _findLightestColor(paletteGenerator.colors.toList());

    // Choose the best colors for start and end
    Color? chosenStartColor;
    Color? chosenEndColor;

    // Prefer darker colors for the start (top) of the gradient
    if (darkVibrantColor != null) {
      chosenStartColor = darkVibrantColor;
    } else if (darkDominantColor != null) {
      chosenStartColor = darkDominantColor;
    } else if (dominantColor != null) {
      chosenStartColor = _adjustColorBrightness(dominantColor, -0.3); // Darken
    }

    // Prefer vibrant or lighter colors for the end of the gradient
    if (vibrantColor != null) {
      chosenEndColor = vibrantColor;
    } else if (lightVibrantColor != null) {
      chosenEndColor = lightVibrantColor;
    } else if (lightDominantColor != null) {
      chosenEndColor = lightDominantColor;
    } else if (dominantColor != null) {
      chosenEndColor = _adjustColorBrightness(dominantColor, 0.2); // Lighten
    }

    // Apply the colors if available
    if (chosenStartColor != null && chosenEndColor != null) {
      // Ensure the start color is darker for visual appeal
      final startHSL = HSLColor.fromColor(chosenStartColor);
      final endHSL = HSLColor.fromColor(chosenEndColor);

      // If end color is darker than start, swap them
      if (endHSL.lightness < startHSL.lightness) {
        final temp = chosenStartColor;
        chosenStartColor = chosenEndColor;
        chosenEndColor = temp;
      }

      // Adjust colors to work better in a gradient and ensure text readability
      _startColor = _ensureColorContrast(chosenStartColor);
      _endColor = _ensureColorContrast(chosenEndColor);
      _hasCustomColors = true;
      notifyListeners();
    } else if (dominantColor != null) {
      // If we only have one color, create a gradient from it
      _startColor =
          _ensureColorContrast(_adjustColorBrightness(dominantColor, -0.3));
      _endColor =
          _ensureColorContrast(_adjustColorBrightness(dominantColor, 0.3));
      _hasCustomColors = true;
      notifyListeners();
    } else {
      resetToDefaultColors();
    }
  }

  // Helper method to find the darkest color in a set
  Color? _findDarkestColor(List<Color> colors) {
    if (colors.isEmpty) return null;

    Color darkest = colors.first;
    double darkestLuminance = darkest.computeLuminance();

    for (final color in colors) {
      final luminance = color.computeLuminance();
      if (luminance < darkestLuminance) {
        darkest = color;
        darkestLuminance = luminance;
      }
    }

    return darkest;
  }

  // Helper method to find the lightest color in a set
  Color? _findLightestColor(List<Color> colors) {
    if (colors.isEmpty) return null;

    Color lightest = colors.first;
    double lightestLuminance = lightest.computeLuminance();

    for (final color in colors) {
      final luminance = color.computeLuminance();
      if (luminance > lightestLuminance) {
        lightest = color;
        lightestLuminance = luminance;
      }
    }

    return lightest;
  }

  // Helper method to adjust brightness of a color
  Color _adjustColorBrightness(Color color, double factor) {
    assert(factor >= -1.0 && factor <= 1.0);

    final hsl = HSLColor.fromColor(color);
    final adjustedLightness = (hsl.lightness + factor).clamp(0.0, 1.0);

    return hsl.withLightness(adjustedLightness).toColor();
  }

  // Helper method to ensure colors have enough contrast for text
  Color _ensureColorContrast(Color color) {
    const whiteTextLuminanceThreshold = 0.5;

    final luminance = color.computeLuminance();

    // If the color is too light for white text, darken it
    if (luminance > whiteTextLuminanceThreshold) {
      return _adjustColorBrightness(color, -0.3);
    }

    return color;
  }

  // Create a gradient based on the current colors and dark mode setting
  LinearGradient createGradient(bool isDarkMode) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.3, 0.7, 1.0],
      colors: [
        _startColor, // Custom or default color at top
        middleColor,
        isDarkMode
            ? const Color(0xFF121212).withOpacity(0.98)
            : const Color(0xFFF8F9FA).withOpacity(0.98),
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      ],
    );
  }
}
