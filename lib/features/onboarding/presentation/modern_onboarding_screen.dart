import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blink_app/features/auth/presentation/auth_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'dart:math' as math;

class ModernOnboardingScreen extends StatefulWidget {
  const ModernOnboardingScreen({super.key});

  @override
  State<ModernOnboardingScreen> createState() => _ModernOnboardingScreenState();
}

class _ModernOnboardingScreenState extends State<ModernOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late AnimationController _scrollIndicatorController;
  late Animation<double> _titleAnimation;
  late Animation<double> _subtitleAnimation;
  late Animation<double> _bulletContainerAnimation;
  List<Animation<double>> _bulletAnimations = [];
  bool _isInitialLoad = true;

  // Track if we're currently animating a page transition
  bool _isPageTransitioning = false;

  // Add image loading state tracking
  final Map<String, bool> _imageLoadingState = {};

  int _currentPage = 0;
  final Map<String, Image> _cachedImages = {};

  late Animation<double> _scrollIndicatorAnimation;
  bool _hasUserInteracted = false;

  final List<ModernOnboardingPage> _pages = [
    ModernOnboardingPage(
      image: 'assets/images/onboarding/pexels-mizunokozuki-13431763.jpg',
      title: 'INSTANT\nCASH',
      subtitle: '',
      showEmoji: true,
      bullets: [
        BulletPoint(
          header: 'Get up to \$200 instantly',
          description: 'No credit checks, no waiting',
        ),
        BulletPoint(
          header: 'Simple, flat fee',
          description: 'No interest, no rollovers, no surprises',
        ),
        BulletPoint(
          header: 'Quick approval',
          description: 'Connect your bank and get a decision in seconds',
        ),
        BulletPoint(
          header: 'No impact on credit score',
          description: 'Blink is not a loan',
        ),
      ],
      overlayColor: const Color(0xFF1E3A8A).withOpacity(0.35),
    ),
    ModernOnboardingPage(
      image: 'assets/images/onboarding/pexels-timmossholder-3105409.jpg',
      title: 'FLEXIBLE\nREPAYMENT',
      subtitle: '',
      showEmoji: true,
      emojiType: 'alarmClock',
      bullets: [
        BulletPoint(
          header: 'Pick your repayment date',
          description: '7 or 15 days',
        ),
        BulletPoint(
          header: 'Save 10% on fees',
          description: 'When repaying in 7 days',
        ),
        BulletPoint(
          header: 'No penalties or hidden fees',
          description: 'Just a simple, flat charge',
        ),
        BulletPoint(
          header: 'Automatic repayment',
          description: 'Hassle-free, stress-free',
        ),
      ],
      overlayColor: const Color(0xFF1E3A8A).withOpacity(0.35),
    ),
    ModernOnboardingPage(
      image: 'assets/images/onboarding/pexels-shvetsa-6631412.jpg',
      title: 'BANK-LEVEL\nSECURITY',
      subtitle: '',
      showEmoji: true,
      emojiType: 'sunglasses-face',
      bullets: [
        BulletPoint(
          header: 'Bank-level security',
          description: 'Powered by Plaid Encryption',
        ),
        BulletPoint(
          header: 'No hidden penalties',
          description: 'Only safe, responsible advances',
        ),
        BulletPoint(
          header: 'Balance check before repayment',
          description: 'Ensuring no overdrafts',
        ),
        BulletPoint(
          header: 'Your data stays private',
          description: 'Blink never stores your login credentials',
        ),
      ],
      overlayColor: const Color(0xFF1E3A8A).withOpacity(0.35),
    ),
  ];

  void _finishOnboarding() async {
    // First haptic feedback
    HapticFeedback.mediumImpact();

    // Trigger animations to fade out content
    setState(() => _isPageTransitioning = true);
    _animationController.reverse();

    // Delayed second haptic for premium feel
    await Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });

    final storageService = Provider.of<StorageService>(context, listen: false);
    await storageService.setBool('has_shown_onboarding', true);

    if (!mounted) return;

    // Navigate with custom page route for smooth transition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        reverseTransitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Stack(
            children: [
              // Background gradient similar to splash screen
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E40AF),
                      const Color(0xFF1E3A8A),
                      const Color(0xFF2563EB),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Subtle pattern overlay
              Opacity(
                opacity: 0.03,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image:
                          const AssetImage('assets/images/noise_pattern.png'),
                      repeat: ImageRepeat.repeat,
                      filterQuality: FilterQuality.high,
                      opacity: 0.2,
                    ),
                  ),
                ),
              ),
              // Fade the auth screen in
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: const AuthScreen(),
              ),
            ],
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    _initializeAnimations();
    _initializeImages();

    _scrollIndicatorAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
    );

    _scrollIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Start the initial animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isInitialLoad = false);
        _animationController.forward();
      }
    });
  }

  void _initializeImages() {
    for (var page in _pages) {
      _imageLoadingState[page.image] = false;
      _cachedImages[page.image] = Image.asset(
        page.image,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame != null) {
            Future.microtask(() {
              if (mounted) {
                setState(() => _imageLoadingState[page.image] = true);
              }
            });
          }
          return child;
        },
      );

      // Start preloading
      _cachedImages[page.image]!
          .image
          .resolve(const ImageConfiguration())
          .addListener(
        ImageStreamListener((info, synchronousCall) {
          if (mounted) {
            setState(() => _imageLoadingState[page.image] = true);
          }
        }),
      );
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _titleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
    );

    _subtitleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
    );

    _bulletContainerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
    );

    _bulletAnimations = List.generate(4, (index) {
      return CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          0.4 + (index * 0.08),
          0.65 + (index * 0.08),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  void _handlePageTransitionStart() {
    HapticFeedback.lightImpact(); // Light feedback when starting swipe
    setState(() => _isPageTransitioning = true);
    _animationController.reset();
  }

  void _handlePageTransitionEnd() {
    if (mounted) {
      if (_currentPage == _pages.length - 1) {
        HapticFeedback.mediumImpact(); // Stronger feedback on last page
        Future.delayed(const Duration(milliseconds: 100), () {
          HapticFeedback.lightImpact(); // Double pattern for success
        });
      } else {
        HapticFeedback.selectionClick(); // Normal feedback for other pages
      }

      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() => _isPageTransitioning = false);
          _animationController.forward();
        }
      });
    }
  }

  void _resetAndPlayAnimation() {
    _handlePageTransitionStart();
    // Shorter delay for snappier response
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _handlePageTransitionEnd();
      }
    });
  }

  @override
  void dispose() {
    // Reset to default when leaving the screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ));
    _animationController.dispose();
    _pageController.dispose();
    _cachedImages.clear();
    _scrollIndicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C1A),
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                if (notification.dragDetails != null) {
                  if (!_hasUserInteracted) {
                    setState(() => _hasUserInteracted = true);
                  }
                  if (!_isPageTransitioning) {
                    setState(() => _isPageTransitioning = true);
                  }
                }
              } else if (notification is ScrollEndNotification) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    setState(() => _isPageTransitioning = false);
                  }
                });
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  _isPageTransitioning = true;
                });
                HapticFeedback.selectionClick();
                _resetAndPlayAnimation();
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _isPageTransitioning ? 0.0 : 1.0,
                  child: ClipRect(
                    child: _buildPage(_pages[index]),
                  ),
                );
              },
              pageSnapping: true,
              allowImplicitScrolling: false,
              padEnds: false,
              physics: const ClampingScrollPhysics(),
            ),
          ),
          // Top gradient overlay for better visibility
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          // Logo
          Positioned(
            top: 48,
            left: 24,
            child: Hero(
              tag: 'logo',
              child: Image.asset(
                'assets/images/blink_logo_white.png',
                width: 53,
                height: 53,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Error loading logo: $error');
                  return const SizedBox(
                    width: 53,
                    height: 53,
                  );
                },
              ),
            ),
          ),
          // Skip button with container
          Positioned(
            top: 48,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed: _finishOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
          ),
          // Bottom navigation and progress
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        width: 32,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              l10n.back,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _currentPage == _pages.length - 1
                              ? _finishOnboarding
                              : () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeInOut,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E3A8A),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
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
          _buildScrollIndicator(),
        ],
      ),
    );
  }

  Widget _buildPage(ModernOnboardingPage page) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image with enhanced loading
        RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1E1F2E),
                      const Color(0xFF0A0C1A),
                    ],
                  ),
                ),
              ),
              if (!_isInitialLoad)
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final double imageProgress = CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
                    ).value;

                    final double scale = 1.0 + (0.03 * (1.0 - imageProgress));
                    final double opacity =
                        _imageLoadingState[page.image] == true
                            ? Curves.easeIn.transform(imageProgress)
                            : 0.0;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Shimmer loading effect
                        if (_imageLoadingState[page.image] != true)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF1E1F2E),
                                  const Color(0xFF0A0C1A),
                                  const Color(0xFF1E1F2E),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        // Actual image with fade and scale
                        Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity * 0.85,
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: _cachedImages[page.image]!.image,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.high,
                                  isAntiAlias: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              // Enhanced gradient overlay with animated opacity
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final double overlayProgress = CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
                  ).value;

                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0A0C1A)
                              .withOpacity(0.95 - (0.15 * overlayProgress)),
                          const Color(0xFF0A0C1A)
                              .withOpacity(0.8 - (0.3 * overlayProgress)),
                          const Color(0xFF0A0C1A)
                              .withOpacity(0.7 - (0.4 * overlayProgress)),
                          const Color(0xFF0A0C1A)
                              .withOpacity(0.95 - (0.05 * overlayProgress)),
                        ],
                        stops: const [0.0, 0.3, 0.5, 0.8],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // Content with transition handling
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isPageTransitioning ? 0.0 : 1.0,
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title with animation
                      FadeTransition(
                        opacity: _titleAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(_titleAnimation),
                          child: Column(
                            children: [
                              // Modern split text animation
                              SizedBox(
                                width: MediaQuery.of(context).size.width - 48,
                                child: Column(
                                  children: page.title
                                      .split('\n')
                                      .map((line) => Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Wrap(
                                                alignment: WrapAlignment.center,
                                                children: line
                                                    .split('')
                                                    .asMap()
                                                    .entries
                                                    .map((entry) {
                                                  final int idx = entry.key;
                                                  final String char =
                                                      entry.value;
                                                  return AnimatedBuilder(
                                                    animation: _titleAnimation,
                                                    builder: (context, child) {
                                                      final double delay =
                                                          idx * 0.05;
                                                      final double opacity =
                                                          math.max(
                                                        0.0,
                                                        math.min(
                                                            1.0,
                                                            (_titleAnimation
                                                                        .value -
                                                                    delay) *
                                                                3),
                                                      );
                                                      final double yOffset =
                                                          (1 - opacity) * 15;
                                                      return Transform
                                                          .translate(
                                                        offset:
                                                            Offset(0, yOffset),
                                                        child: Opacity(
                                                          opacity: opacity,
                                                          child:
                                                              TweenAnimationBuilder<
                                                                  double>(
                                                            tween: Tween(
                                                                begin: 0.0,
                                                                end: 1.0),
                                                            duration:
                                                                const Duration(
                                                                    milliseconds:
                                                                        800),
                                                            curve:
                                                                Curves.easeOut,
                                                            builder: (context,
                                                                shadowValue,
                                                                child) {
                                                              return Text(
                                                                char,
                                                                style:
                                                                    GoogleFonts
                                                                        .outfit(
                                                                  fontSize: 36,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  letterSpacing:
                                                                      -0.5,
                                                                  color: Colors
                                                                      .white,
                                                                  height: 1.2,
                                                                  shadows: [
                                                                    Shadow(
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(0.3 *
                                                                              shadowValue),
                                                                      blurRadius:
                                                                          20 *
                                                                              shadowValue,
                                                                      offset: Offset(
                                                                          0,
                                                                          8 * shadowValue),
                                                                    ),
                                                                    Shadow(
                                                                      color: const Color(
                                                                              0xFF60A5FA)
                                                                          .withOpacity(0.2 *
                                                                              shadowValue),
                                                                      blurRadius:
                                                                          30 *
                                                                              shadowValue,
                                                                      offset: Offset(
                                                                          0,
                                                                          4 * shadowValue),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                }).toList(),
                                              ),
                                              if (page.showEmoji &&
                                                  (line == 'CASH' ||
                                                      line == 'REPAYMENT' ||
                                                      line == 'SECURITY'))
                                                FadeTransition(
                                                  opacity: _titleAnimation,
                                                  child: SlideTransition(
                                                    position: Tween<Offset>(
                                                      begin:
                                                          const Offset(0.5, 0),
                                                      end: Offset.zero,
                                                    ).animate(CurvedAnimation(
                                                      parent:
                                                          _animationController,
                                                      curve: const Interval(
                                                          0.3, 0.7,
                                                          curve: Curves
                                                              .easeOutBack),
                                                    )),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8.0),
                                                      child: AnimatedEmoji(
                                                        page.emojiType ==
                                                                'alarmClock'
                                                            ? AnimatedEmojis
                                                                .alarmClock
                                                            : page.emojiType ==
                                                                    'sunglasses-face'
                                                                ? AnimatedEmojis
                                                                    .sunglassesFace
                                                                : AnimatedEmojis
                                                                    .moneyFace,
                                                        size: 40,
                                                        repeat: true,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ))
                                      .toList(),
                                ),
                              ),
                              // Animated accent bar
                              AnimatedBuilder(
                                animation: _titleAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scaleX: _titleAnimation.value,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 16),
                                      height: 3,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF60A5FA),
                                            const Color(0xFF3B82F6),
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(1.5),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Bullets container with animation
                      FadeTransition(
                        opacity: _bulletContainerAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(_bulletContainerAnimation),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: List.generate(
                                page.bullets.length,
                                (index) => FadeTransition(
                                  opacity: _bulletAnimations[index],
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.2, 0),
                                      end: Offset.zero,
                                    ).animate(_bulletAnimations[index]),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    top: 8),
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.white
                                                          .withOpacity(0.3),
                                                      blurRadius: 4,
                                                      spreadRadius: 1,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: RichText(
                                                  text: TextSpan(
                                                    children:
                                                        _buildStyledBulletText(
                                                      page.bullets[index]
                                                          .header,
                                                    ),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 18,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      height: 1.3,
                                                      letterSpacing: 0.3,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black
                                                              .withOpacity(0.3),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 18),
                                            child: Text(
                                              page.bullets[index].description,
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                height: 1.4,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.2,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    blurRadius: 3,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<InlineSpan> _buildStyledBulletText(String text) {
    if (!text.contains('\$200')) return [TextSpan(text: text)];

    final parts = text.split('\$200');
    return [
      TextSpan(text: parts[0]),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF60A5FA),
                Color(0xFF3B82F6),
              ],
            ).createShader(bounds),
            child: Text(
              '\$200',
              style: GoogleFonts.inter(
                fontSize: 22, // Larger font size
                fontWeight: FontWeight.w800, // Bolder weight
                color: Colors.white,
                height: 1.1,
                letterSpacing: -0.5,
                shadows: [
                  const Shadow(
                    color: Color(0xFF60A5FA),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      TextSpan(text: parts[1]),
    ];
  }

  Widget _buildScrollIndicator() {
    if (_hasUserInteracted) return const SizedBox.shrink();

    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.45,
      right: 20,
      child: FadeTransition(
        opacity: _scrollIndicatorAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.2, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _scrollIndicatorAnimation,
            curve: Curves.easeOutCubic,
          )),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _scrollIndicatorController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    3 * math.sin(_scrollIndicatorController.value * math.pi),
                    0,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.95),
                    size: 18,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ModernOnboardingPage {
  final String image;
  final String title;
  final String subtitle;
  final List<BulletPoint> bullets;
  final Color overlayColor;
  final bool showEmoji;
  final String? emojiType;

  const ModernOnboardingPage({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.overlayColor,
    this.showEmoji = false,
    this.emojiType = 'moneyFace',
  });
}

class BulletPoint {
  final String header;
  final String description;

  const BulletPoint({
    required this.header,
    required this.description,
  });
}
