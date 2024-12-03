// lib/features/onboarding/presentation/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:myapp/features/auth/presentation/sign_up_screen.dart'; // Correct package import

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLastPage = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      image: 'assets/images/OBJECTS.svg',
      title: 'Cash When You\nNeed It Most',
      subtitle:
          'Blink gives you instant access to cash advances with just a few taps, no credit needed.',
    ),
    OnboardingPage(
      image: 'assets/images/OBJECTS-2.svg',
      title: 'Smarter Financial\nManagement',
      subtitle:
          'Stay on top of your spending and income patterns to make smarter money decisions.',
    ),
    OnboardingPage(
      image: 'assets/images/OBJECTS-1.svg',
      title: 'Total Control, Total\nTransparency',
      subtitle:
          'Blink is built on transparency. Pay only a flat fee for your advance—no interest, no tips, no subscriptions.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToSignUp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignUpScreen(),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061535),
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _isLastPage = index == _pages.length - 1;
                });
              },
              itemBuilder: (context, index) {
                return OnboardingPageWidget(page: _pages[index]);
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Image.asset(
                'assets/images/blink_logo.png',
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: _navigateToSignUp,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Onest',
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: const WormEffect(
                        dotColor: Colors.white24,
                        activeDotColor: Colors.white,
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 8,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isLastPage) {
                            _navigateToSignUp();
                          } else {
                            _pageController.nextPage(
                              duration:
                                  const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isLastPage ? 'Get Started' : 'Continue',
                          style: const TextStyle(
                            fontFamily: 'Onest',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String image;
  final String title;
  final String subtitle;

  OnboardingPage({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({
    super.key, // Using super parameter
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    24, 24, 24, 100), // Increased bottom padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 1),
                    Container(
                      width: double.infinity,
                      height: constraints.maxHeight * 0.4,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.0, 0.5),
                          radius: 0.8,
                          colors: [
                            const Color(0xFF0A2355).withOpacity(0.9),
                            const Color(0xFF061535),
                          ],
                          stops: const [0.0, 0.9],
                        ),
                      ),
                      child: SvgPicture.asset(
                        page.image,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Spacer(flex: 1),
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Onest',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      page.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Onest',
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
