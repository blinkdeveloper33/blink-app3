import 'package:flutter/material.dart';

/// Device types based on screen sizes
enum DeviceType {
  small, // iPhone SE, 5, etc.
  medium, // iPhone 8, X, 11, 12/13 Mini
  large, // iPhone 12, 13, 14
  extraLarge, // iPhone 12/13/14 Pro Max, 15 Pro Max, 16, 16 Pro
  max // iPhone 16 Pro Max and potentially larger
}

/// Utility class to handle responsive layouts across different device sizes
class ResponsiveUtils {
  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 360) return DeviceType.small;
    if (width < 390) return DeviceType.medium;
    if (width < 428) return DeviceType.large;
    if (width < 450) return DeviceType.extraLarge;
    return DeviceType.max;
  }

  /// Get multiplier for adjusting font sizes
  static double getFontSizeMultiplier(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.small:
        return 0.85;
      case DeviceType.medium:
        return 0.92;
      case DeviceType.large:
        return 1.0;
      case DeviceType.extraLarge:
        return 1.05;
      case DeviceType.max:
        return 1.1;
    }
  }

  /// Get padding multiplier for different devices
  static double getPaddingMultiplier(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.small:
        return 0.8;
      case DeviceType.medium:
        return 0.9;
      case DeviceType.large:
        return 1.0;
      case DeviceType.extraLarge:
        return 1.1;
      case DeviceType.max:
        return 1.2;
    }
  }

  /// Get element size multiplier for UI elements
  static double getElementSizeMultiplier(BuildContext context) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.small:
        return 0.85;
      case DeviceType.medium:
        return 0.95;
      case DeviceType.large:
        return 1.0;
      case DeviceType.extraLarge:
        return 1.05;
      case DeviceType.max:
        return 1.1;
    }
  }

  /// Return responsive font size based on base size and device
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    return baseSize * getFontSizeMultiplier(context);
  }

  /// Return responsive padding based on base padding and device
  static EdgeInsets getResponsivePadding(
      BuildContext context, EdgeInsets basePadding) {
    final multiplier = getPaddingMultiplier(context);

    return EdgeInsets.fromLTRB(
      basePadding.left * multiplier,
      basePadding.top * multiplier,
      basePadding.right * multiplier,
      basePadding.bottom * multiplier,
    );
  }

  /// Check if the device has notch or dynamic island
  static bool hasNotch(BuildContext context) {
    // This is a basic check - in real implementation, you might want to add
    // a more sophisticated check (possibly using package:device_info)
    final padding = MediaQuery.of(context).viewPadding;
    return padding.top > 20;
  }

  /// Get the safe area top padding adjusted for content
  static double getSafeAreaTopPadding(BuildContext context) {
    return MediaQuery.of(context).viewPadding.top;
  }

  /// Check if the device is using accessibility features
  static bool isUsingAccessibilityFeatures(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // Check if text scaling is beyond normal range
    final textScale = mediaQuery.textScaler.scale(1.0);
    return textScale > 1.1 || textScale < 0.9;
  }
}
