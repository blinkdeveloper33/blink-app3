# Quick Actions Components

This directory contains components for the quick action cards displayed on the home screen and other parts of the application.

## Architecture

The quick action components follow a modular approach with the following structure:

### Base Components

- `quick_action_card.dart`: Contains the base abstract classes for quick action cards
  - `QuickActionCard`: Base widget class that all quick action cards should extend
  - `QuickActionCardState`: Base state class that provides common functionality
  - `QuickActionCardStyle`: Utility class with styling methods for consistent appearance

### Specific Implementations

Each specific quick action card is implemented in its respective feature directory:

- **Insights Card**: `lib/features/insights/presentation/widgets/insights_quick_action_card.dart`
- **Blink Advance Card**: `lib/features/home/presentation/widgets/blink_advance_card.dart`
- **Blink Repay Card**: `lib/features/repayment/presentation/widgets/blink_repay_card.dart`

## Usage

To create a new quick action card:

1. Extend the `QuickActionCard` class
2. Implement a state class that extends `QuickActionCardState`
3. Override the `onCardTap` method to define the card's behavior
4. Use `QuickActionCardStyle` utilities for consistent styling

Example:

```dart
class MyQuickActionCard extends QuickActionCard {
  const MyQuickActionCard({
    Key? key,
    required bool isDarkMode,
    Function(haptics.HapticsType)? onHapticFeedback,
  }) : super(
          key: key,
          isDarkMode: isDarkMode,
          onHapticFeedback: onHapticFeedback,
        );

  @override
  State<MyQuickActionCard> createState() => _MyQuickActionCardState();
}

class _MyQuickActionCardState extends QuickActionCardState<MyQuickActionCard> {
  @override
  void onCardTap(BuildContext context) {
    // Define what happens when the card is tapped
  }

  @override
  Widget build(BuildContext context) {
    // Build the card UI
  }
}
```

## Benefits of Modularization

- **Consistency**: All quick action cards share common behavior and styling
- **Maintainability**: Changes to behavior or styling can be made in a single place
- **Reusability**: Common code is shared between implementations
- **Testability**: Components can be tested in isolation 