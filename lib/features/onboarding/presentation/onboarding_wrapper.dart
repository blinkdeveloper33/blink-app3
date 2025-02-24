import 'package:flutter/material.dart';
import 'package:blink_app/config/feature_flags.dart';
import 'package:blink_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:blink_app/features/onboarding/presentation/modern_onboarding_screen.dart';

class OnboardingWrapper extends StatelessWidget {
  const OnboardingWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureFlags.useModernOnboarding
        ? const ModernOnboardingScreen()
        : const OnboardingScreen();
  }
}
