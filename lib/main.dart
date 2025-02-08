import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:blink_app/services/supabase_storage_service.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:blink_app/providers/financial_data_provider.dart';
import 'package:blink_app/providers/profile_provider.dart';
import 'package:blink_app/providers/recurring_expenses_provider.dart';
import 'package:blink_app/features/auth/presentation/login_screen.dart';
import 'package:blink_app/features/splash/presentation/splash_screen.dart';
import 'package:blink_app/features/auth/presentation/sign_up_screen.dart';
import 'package:blink_app/features/home/presentation/home_screen.dart';
import 'package:blink_app/features/error/presentation/error_screen.dart';
import 'package:blink_app/features/insights/presentation/financial_insights_screen.dart';
import 'package:blink_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:blink_app/features/insights/presentation/recurring_expenses_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blink_app/services/biometric_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Debug environment variables
  print('API_URL: ${dotenv.env['API_URL']}');
  print('BACKEND_URL: ${dotenv.env['BACKEND_URL']}');
  print('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');

  // Initialize Supabase with deep linking configuration
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
    storageOptions: const StorageClientOptions(
      retryAttempts: 3,
    ),
    debug: true,
  );

  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  final authService = AuthService(storageService);
  final biometricService = BiometricService();
  await authService.init();

  final supabaseStorageService =
      SupabaseStorageService(Supabase.instance.client);

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => authService),
        Provider<StorageService>(create: (_) => storageService),
        Provider<SupabaseStorageService>(create: (_) => supabaseStorageService),
        Provider<BiometricService>(create: (_) => biometricService),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(
            create: (_) => FinancialDataProvider(authService)),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
            create: (_) => RecurringExpensesProvider(authService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _updateSystemUIOverlayStyle(bool isDarkMode) {
    SystemChrome.setSystemUIOverlayStyle(
      isDarkMode
          ? const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarIconBrightness: Brightness.light,
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            )
          : const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarIconBrightness: Brightness.dark,
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    _updateSystemUIOverlayStyle(isDarkMode);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final biometricService =
        Provider.of<BiometricService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    switch (state) {
      case AppLifecycleState.paused:
        // App goes to background
        biometricService.updateLastActiveTime();
        break;
      case AppLifecycleState.resumed:
        // App comes to foreground
        _handleAppResume(biometricService, authService);
        break;
      default:
        break;
    }
  }

  Future<void> _handleAppResume(
      BiometricService biometricService, AuthService authService) async {
    if (authService.currentUser != null) {
      final bool hasTimedOut = await biometricService.hasSessionTimedOut();
      final bool isBiometricEnabled =
          await biometricService.isBiometricEnabled();

      if (hasTimedOut && isBiometricEnabled) {
        final bool authenticated = await biometricService.authenticate();
        if (!authenticated) {
          // Navigate to login screen if authentication fails
          if (mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blink',
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).currentTheme.copyWith(
            platform: TargetPlatform.android,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.android: ZoomPageTransitionsBuilder(),
              },
            ),
          ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/insights': (context) => const FinancialInsightsScreen(),
        '/recurring-expenses': (context) => const RecurringExpensesScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const ErrorScreen(
            message: 'Page not found',
          ),
        );
      },
    );
  }
}
