import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/services/biometric_service.dart';
import 'package:blink_app/features/onboarding/presentation/onboarding_wrapper.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:blink_app/providers/profile_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isInitialized = false;

  // List of onboarding images to preload
  final List<String> _onboardingImages = [
    'assets/images/onboarding/pexels-mizunokozuki-13431763.jpg',
    'assets/images/onboarding/pexels-timmossholder-3105409.jpg',
    'assets/images/onboarding/pexels-shvetsa-6631412.jpg',
  ];

  @override
  void initState() {
    super.initState();

    try {
      _mainController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ),
      );

      _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
        ),
      );

      Future.microtask(() {
        if (mounted) {
          _mainController.forward();
        }
      });
    } catch (e) {
      debugPrint('Error initializing SplashScreen: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only run initialization once
    if (!_isInitialized) {
      _isInitialized = true;
      _initializeApp();
    }
  }

  Future<void> _preloadOnboardingImages() async {
    try {
      final List<Future<void>> imagePreloadFutures = [];
      final List<ImageStreamListener> listeners = [];

      // Create image instances and preload them
      for (final imagePath in _onboardingImages) {
        final image = Image.asset(
          imagePath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          gaplessPlayback: true,
        );

        // First, precache the image
        imagePreloadFutures.add(
          precacheImage(image.image, context).then((_) {
            debugPrint('Started preloading onboarding image: $imagePath');
          }).catchError((error) {
            debugPrint('Error preloading onboarding image $imagePath: $error');
          }),
        );

        // Then ensure the image is fully loaded by listening to the image stream
        final completer = Completer<void>();
        final ImageStream stream =
            image.image.resolve(const ImageConfiguration());
        final listener = ImageStreamListener(
          (ImageInfo info, bool synchronousCall) {
            debugPrint('Image fully loaded: $imagePath');
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
          onError: (dynamic exception, StackTrace? stackTrace) {
            debugPrint('Error fully loading image $imagePath: $exception');
            if (!completer.isCompleted) {
              completer.complete(); // Complete anyway to avoid hanging
            }
          },
        );

        stream.addListener(listener);
        listeners.add(listener);
        imagePreloadFutures.add(completer.future);
      }

      // Wait for all images to be fully loaded
      await Future.wait(imagePreloadFutures);

      // Clean up listeners
      for (var i = 0; i < _onboardingImages.length; i++) {
        final image = Image.asset(_onboardingImages[i]).image;
        final stream = image.resolve(const ImageConfiguration());
        stream.removeListener(listeners[i]);
      }

      if (mounted) {
        debugPrint('All onboarding images are fully loaded and rendered');
      }
    } catch (e) {
      debugPrint('Error in preloading onboarding images: $e');
      if (mounted) {
        // Continue even if there's an error
      }
    }
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;

    // Access providers after the widget is fully built
    final authService = Provider.of<AuthService>(context, listen: false);
    final biometricService =
        Provider.of<BiometricService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    // Start preloading images immediately
    final preloadFuture = _preloadOnboardingImages();
    final timerFuture = Future.delayed(const Duration(milliseconds: 3000));

    try {
      // Try to load user profile picture in parallel if we have a user ID
      final userId = storageService.getUserId();
      if (userId != null) {
        debugPrint('Loading profile picture for user $userId');
        // Schedule profile picture loading on the next frame to avoid build conflicts
        Future.microtask(() {
          if (mounted) {
            profileProvider.loadProfilePicture(userId).catchError((e) {
              // Just log the error, don't interrupt the app startup
              debugPrint('Error loading profile picture: $e');
            });
          }
        });
      }

      await Future.wait([timerFuture, preloadFuture]);
      debugPrint(
          'Splash screen minimum duration and image preloading completed');
    } catch (e) {
      debugPrint('Error during splash screen initialization: $e');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;

    if (authService.currentUser == null) {
      debugPrint('Splash screen - Current user is null');
      debugPrint('Splash screen - Always showing onboarding on restart');
      _navigateToOnboarding();
      return;
    }

    final bool isBiometricEnabled = await biometricService.isBiometricEnabled();
    final bool hasTimedOut = await biometricService.hasSessionTimedOut();

    if (!mounted) return;

    if (isBiometricEnabled && hasTimedOut) {
      try {
        // Show Face ID prompt with native UI
        final bool authenticated = await biometricService.authenticate();
        if (!mounted) return;

        if (authenticated) {
          // Authentication successful, go to home
          await biometricService.updateLastActiveTime();
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // Authentication failed or cancelled, go to login
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (e) {
        // Handle any authentication errors
        debugPrint('Authentication error: $e');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } else {
      // No biometric needed or timeout hasn't occurred, go to home
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _navigateToOnboarding() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    try {
      _mainController.dispose();
    } catch (e) {
      debugPrint('Error disposing SplashScreen controller: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Center(
          child: AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Hero(
              tag: 'logo',
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  double maxSize = constraints.maxWidth < constraints.maxHeight
                      ? constraints.maxWidth
                      : constraints.maxHeight;
                  return Image.asset(
                    'assets/images/blink_logo_white.png',
                    width: maxSize * 0.22,
                    height: maxSize * 0.22,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
