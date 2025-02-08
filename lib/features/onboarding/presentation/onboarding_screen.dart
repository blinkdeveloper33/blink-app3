import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:blink_app/features/auth/presentation/sign_up_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _backgroundAnimationController;
  late Animation<Color?> _backgroundColorAnimation;
  late AnimationController _cardAnimationController;
  late Animation<double> _cardAnimation;
  int _currentPage = 0;

  late List<OnboardingPage> _pages;

  @override
  void initState() {
    super.initState();

    try {
      _initPages();

      _backgroundAnimationController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _backgroundColorAnimation = ColorTween(
        begin: _pages[0].gradientStart,
        end: _pages[1].gradientStart,
      ).animate(CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.easeInOut,
      ));

      _cardAnimationController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _cardAnimation = CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOutCubic,
      );

      Future.microtask(() {
        if (mounted) {
          _cardAnimationController.forward();
        }
      });
    } catch (e) {
      debugPrint('Error initializing OnboardingScreen: $e');
    }
  }

  void _initPages() {
    _pages = [
      OnboardingPage(
        animation: 'assets/animations/instant_cash.json',
        title: 'Get a Blink Cash Advance',
        subtitle:
            'Get an instant \$200 cash advance when you need it most. Fast, transparent, and hassle-free with no credit check required.',
        gradientStart: const Color(0xFF1E3A8A),
        gradientEnd: const Color(0xFF2563EB),
        icon: Icons.attach_money,
      ),
      OnboardingPage(
        animation: 'assets/animations/money_management.json',
        title: 'Smart Financial Wellness',
        subtitle:
            'Take control of your finances with personalized insights, analytics, and responsible borrowing features. We help you make better financial decisions.',
        gradientStart: const Color(0xFF064E3B),
        gradientEnd: const Color(0xFF059669),
        icon: Icons.insert_chart,
      ),
      OnboardingPage(
        animation: 'assets/animations/transparency.json',
        title: 'Simple & Transparent',
        subtitle:
            'One flat fee, no hidden charges, no rollovers. Choose your repayment date within 31 days and we handle the rest.',
        gradientStart: const Color(0xFF312E81),
        gradientEnd: const Color(0xFF4F46E5),
        icon: Icons.visibility,
      ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    try {
      _pageController.dispose();
      _backgroundAnimationController.dispose();
      _cardAnimationController.dispose();
    } catch (e) {
      debugPrint('Error disposing OnboardingScreen controllers: $e');
    }
    super.dispose();
  }

  void _navigateToSignUp() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _onPageChanged(int page) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentPage = page;
    });
    _backgroundAnimationController.reset();
    _backgroundColorAnimation = ColorTween(
      begin: _pages[_currentPage].gradientStart,
      end: _pages[(_currentPage + 1) % _pages.length].gradientStart,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.easeInOut,
    ));
    _backgroundAnimationController.forward();
    _cardAnimationController.reset();
    _cardAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _backgroundColorAnimation,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundColorAnimation.value ??
                      _pages[_currentPage].gradientStart,
                  _pages[_currentPage].gradientEnd,
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Logo with enhanced size and positioning
                  Positioned(
                    top: 16,
                    left: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Hero(
                        tag: 'logo',
                        child: Image.asset(
                          'assets/images/blink_logo_white.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          itemCount: _pages.length,
                          itemBuilder: (context, index) {
                            return FadeTransition(
                              opacity: _cardAnimation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.2, 0.0),
                                  end: Offset.zero,
                                ).animate(_cardAnimation),
                                child:
                                    OnboardingPageWidget(page: _pages[index]),
                              ),
                            );
                          },
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _cardAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _cardAnimation.value,
                            child: child,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              // Progress Indicator
                              SizedBox(
                                width: double.infinity,
                                height: 4,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _pages.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width:
                                          (MediaQuery.of(context).size.width -
                                                      48) /
                                                  _pages.length -
                                              8,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: _currentPage == index
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Navigation Buttons
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (_currentPage > 0)
                                    TextButton(
                                      onPressed: () {
                                        _pageController.previousPage(
                                          duration:
                                              const Duration(milliseconds: 600),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                      ),
                                      child: Text(
                                        l10n.back,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox(width: 80),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed:
                                          _currentPage == _pages.length - 1
                                              ? _navigateToSignUp
                                              : () {
                                                  _pageController.nextPage(
                                                    duration: const Duration(
                                                        milliseconds: 600),
                                                    curve: Curves.easeInOut,
                                                  );
                                                },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor:
                                            _pages[_currentPage].gradientStart,
                                        backgroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        _currentPage == _pages.length - 1
                                            ? l10n.getStarted
                                            : l10n.next,
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Skip button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: TextButton(
                      onPressed: _navigateToSignUp,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        l10n.skip,
                        style: GoogleFonts.inter(
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
        );
      },
    );
  }
}

class OnboardingPage {
  final String animation;
  final String title;
  final String subtitle;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData icon;

  OnboardingPage({
    required this.animation,
    required this.title,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
    required this.icon,
  });

  OnboardingPage copyWith({
    String? title,
    String? subtitle,
  }) {
    return OnboardingPage(
      animation: this.animation,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      gradientStart: this.gradientStart,
      gradientEnd: this.gradientEnd,
      icon: this.icon,
    );
  }
}

class OnboardingPageWidget extends StatefulWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({
    super.key,
    required this.page,
  });

  @override
  State<OnboardingPageWidget> createState() => _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState extends State<OnboardingPageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Lottie.asset(
              widget.page.animation,
              width: 240,
              height: 240,
              fit: BoxFit.contain,
              controller: _lottieController,
              onLoaded: (composition) {
                _lottieController
                  ..duration = composition.duration
                  ..repeat();
              },
            ),
          ),
          const SizedBox(height: 48),
          Text(
            widget.page.title,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
              shadows: [
                Shadow(
                  blurRadius: 8,
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            widget.page.subtitle,
            style: GoogleFonts.inter(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
