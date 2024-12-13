import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:blink_app/features/auth/presentation/sign_up_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    _initPages();
    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _backgroundColorAnimation = ColorTween(
      begin: _pages[0].gradientStart,
      end: _pages[1].gradientStart,
    ).animate(_backgroundAnimationController);

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    );

    _cardAnimationController.forward();
  }

  void _initPages() {
    _pages = [
      OnboardingPage(
        animation: 'assets/animations/instant_cash.json',
        image: 'assets/images/OBJECTS.svg',
        title: 'Instant Cash Access',
        subtitle:
            'Get BlinkAdvance cash advances from \$150 to \$300, no credit check required.',
        gradientStart: Color(0xFF1E88E5),
        gradientEnd: Color(0xFF64B5F6),
        icon: Icons.attach_money,
      ),
      OnboardingPage(
        animation: 'assets/animations/money_management.json',
        image: 'assets/images/OBJECTS-2.svg',
        title: 'Smart Money Management',
        subtitle:
            'Track spending, set budgets, and make informed financial decisions.',
        gradientStart: Color(0xFF43A047),
        gradientEnd: Color(0xFF81C784),
        icon: Icons.insert_chart,
      ),
      OnboardingPage(
        animation: 'assets/animations/transparency.json',
        image: 'assets/images/OBJECTS-1.svg',
        title: 'Transparent & Fair',
        subtitle: 'No hidden fees, automatic repayment on your chosen date.',
        gradientStart: Color(0xFF5E35B1),
        gradientEnd: Color(0xFF9575CD),
        icon: Icons.visibility,
      ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _updatePagesWithLocalizations(l10n);
  }

  void _updatePagesWithLocalizations(AppLocalizations l10n) {
    _pages[0] = _pages[0].copyWith(
      title: l10n.onboardingTitle1,
      subtitle: l10n.onboardingSubtitle1,
    );
    _pages[1] = _pages[1].copyWith(
      title: l10n.onboardingTitle2,
      subtitle: l10n.onboardingSubtitle2,
    );
    _pages[2] = _pages[2].copyWith(
      title: l10n.onboardingTitle3,
      subtitle: l10n.onboardingSubtitle3,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundAnimationController.dispose();
    _cardAnimationController.dispose();
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
    ).animate(_backgroundAnimationController);
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
                  Positioned(
                    top: 16,
                    left: 16,
                    child: SvgPicture.asset(
                      'assets/images/blink_logo1.svg',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
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
                                  begin: const Offset(0.25, 0.0),
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
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 4),
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (_currentPage > 0)
                                    TextButton(
                                      onPressed: () {
                                        _pageController.previousPage(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                      ),
                                      child: Text(
                                        l10n.back,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    )
                                  else
                                    SizedBox(width: 80),
                                  ElevatedButton(
                                    onPressed: _currentPage == _pages.length - 1
                                        ? _navigateToSignUp
                                        : () {
                                            _pageController.nextPage(
                                              duration: const Duration(
                                                  milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor:
                                          _pages[_currentPage].gradientStart,
                                      backgroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      elevation: 2,
                                    ),
                                    child: Text(
                                      _currentPage == _pages.length - 1
                                          ? l10n.getStarted
                                          : l10n.next,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
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
                  Positioned(
                    top: 16,
                    right: 16,
                    child: TextButton(
                      onPressed: _navigateToSignUp,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        l10n.skip,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
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
  final String image;
  final String title;
  final String subtitle;
  final Color gradientStart;
  final Color gradientEnd;
  final IconData icon;

  OnboardingPage({
    required this.animation,
    required this.image,
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
      image: this.image,
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: Lottie.asset(
              widget.page.animation,
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              controller: _lottieController,
              onLoaded: (composition) {
                _lottieController
                  ..duration = composition.duration
                  ..repeat();
              },
            ),
          ),
          SizedBox(height: 40),
          Text(
            widget.page.title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.1),
                  offset: Offset(1, 1),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            widget.page.subtitle,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
