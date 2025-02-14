import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:blink_app/features/auth/presentation/sign_up_screen.dart';
import 'package:blink_app/features/auth/presentation/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Add listener for tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.lightImpact();
      }
    });

    // Initial haptic feedback when screen appears
    Future.microtask(() {
      HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Enhanced background with richer gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E40AF).withOpacity(0.95),
                  const Color(0xFF1E3A8A),
                  const Color(0xFF2563EB).withOpacity(0.95),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Enhanced top gradient for better text contrast
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 64),
                // Enhanced logo with refined glow
                Hero(
                  tag: 'logo',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF60A5FA).withOpacity(0.15),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/blink_logo_white.png',
                      height: 68,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Enhanced Tab Bar with improved contrast
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          indicator: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white.withOpacity(0.65),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            height: 1.3,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          unselectedLabelStyle: GoogleFonts.inter(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            height: 1.3,
                          ),
                          tabs: [
                            Tab(
                              height: 56,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Text('Sign Up'),
                              ),
                            ),
                            Tab(
                              height: 56,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Text('Log In'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Enhanced Tab View with improved transitions
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      SignUpScreen(showAppBar: false),
                      LoginScreen(showAppBar: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
