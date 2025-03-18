# Responsive Design Guide for Blink App

This guide explains the responsive design system implemented in the Blink app to ensure consistent layouts across different iPhone models.

## Device Categories

The responsive utilities classify devices into these categories:

- **Small**: iPhone SE, 5, etc. (width < 360px)
- **Medium**: iPhone 8, X, 11, 12/13 Mini (width < 390px)
- **Large**: iPhone 12, 13, 14 (width < 428px)
- **Extra Large**: iPhone 12/13/14 Pro Max, 15 Pro Max, 16 (width < 450px)
- **Max**: iPhone 16 Pro Max and potentially larger devices (width >= 450px)

## Using Responsive Utilities

To ensure your UI adapts properly to different screen sizes:

### 1. Import the Responsive Utils

```dart
import 'package:blink_app/core/utils/responsive_utils.dart' show ResponsiveUtils, DeviceType;
```

### 2. Apply Responsive Font Sizes

Convert fixed font sizes to responsive ones:

```dart
// Before
Text(
  'Your text',
  style: TextStyle(
    fontSize: 16,
    // other properties
  ),
)

// After
Text(
  'Your text',
  style: TextStyle(
    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
    // other properties
  ),
)
```

### 3. Apply Responsive Padding

```dart
// Before
padding: const EdgeInsets.all(16),

// After
padding: ResponsiveUtils.getResponsivePadding(
  context, 
  const EdgeInsets.all(16)
),
```

### 4. Scale UI Elements

```dart
// Before
borderRadius: BorderRadius.circular(20),

// After
borderRadius: BorderRadius.circular(20 * ResponsiveUtils.getElementSizeMultiplier(context)),
```

### 5. Adjust Spacing

```dart
// Before
const SizedBox(height: 16),

// After
SizedBox(height: 16 * ResponsiveUtils.getElementSizeMultiplier(context)),
```

## Device-Specific Adaptations

For more control over specific devices:

```dart
final deviceType = ResponsiveUtils.getDeviceType(context);
  
switch (deviceType) {
  case DeviceType.small:
    // iPhone SE specific layout
    return SmallLayout();
  case DeviceType.large:
    // iPhone 13/14 layout
    return LargeLayout();
  // etc.
}
```

## Best Practices

1. **Test on Multiple Devices**: Always test your UI on different device sizes, both in simulators and real devices.

2. **Check for Accessibility Settings**: Use `ResponsiveUtils.isUsingAccessibilityFeatures(context)` to detect if the user has enabled accessibility features.

3. **Handle Notches and Dynamic Island**: Use `ResponsiveUtils.hasNotch(context)` to adapt layouts for devices with notches.

4. **Consider Orientation**: Add orientation-specific layout adjustments where needed.

5. **Use LayoutBuilder**: For complex layouts, combine ResponsiveUtils with LayoutBuilder to create truly adaptive UIs.

## Troubleshooting Common Issues

- **Text Overflow**: If text is overflowing on smaller devices, ensure you're using responsive font sizes.
  
- **Layout Differences**: If layouts look different between simulator and real devices, check for device-specific settings and iOS version differences.

- **Flipping Cards and Animations**: For animated components like the Repayment card, adjust perspective values for different device sizes.

## Implementing New Features

When adding new UI components:

1. Always implement responsive layout from the start
2. Test on at least 3 device sizes (small, medium, and large)
3. Consider how the component will adapt to future iPhone models with larger screens 