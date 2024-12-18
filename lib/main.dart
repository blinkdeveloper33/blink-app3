import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:blink_app/features/splash/presentation/splash_screen.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:blink_app/features/auth/presentation/login_screen.dart';
import 'package:blink_app/features/home/presentation/home_screen.dart';
import 'package:blink_app/features/error/presentation/error_screen.dart';
import 'package:blink_app/features/insights/presentation/financial_insights_screen.dart';
import 'package:blink_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:blink_app/providers/financial_data_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = Logger();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    if (dotenv.env['APP_ENV'] == 'development') {
      logger.i('Environment variables loaded: ${dotenv.env}');
    }
    logger.i('BACKEND_URL: ${dotenv.env['BACKEND_URL']}');
  } catch (e, stackTrace) {
    logger.e("Error loading .env file: $e", error: e, stackTrace: stackTrace);
    runApp(ErrorScreen(message: "Failed to load environment variables"));
    return;
  }

  // Initialize StorageService (Singleton)
  final storageService = StorageService();
  try {
    await storageService.init();
    logger.i('StorageService initialized successfully.');
  } catch (e, stackTrace) {
    logger.e('Error initializing StorageService: $e',
        error: e, stackTrace: stackTrace);
    runApp(ErrorScreen(message: "Failed to initialize storage service"));
    return;
  }

  // Initialize AuthService
  final authService = AuthService(storageService: storageService);
  try {
    await authService.init();
    logger.i('AuthService initialized successfully.');
  } catch (e, stackTrace) {
    logger.e('Error initializing AuthService: $e',
        error: e, stackTrace: stackTrace);
    runApp(ErrorScreen(message: "Failed to initialize authentication service"));
    return;
  }

  // Set system UI overlays
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF061535),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
            create: (context) => FinancialDataProvider(authService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Blink',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('es', ''), // Spanish
      ],
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');
        final path = uri.path;

        switch (path) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const OnboardingScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/insights':
            return MaterialPageRoute(
              builder: (_) => const FinancialInsightsScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => ErrorScreen(message: "Route not found: $path"),
            );
        }
      },
    );
  }
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Onest',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontFamily: 'Onest'),
        bodyMedium: TextStyle(fontFamily: 'Onest'),
        titleLarge: TextStyle(fontFamily: 'Onest'),
        titleMedium: TextStyle(fontFamily: 'Onest'),
        titleSmall: TextStyle(fontFamily: 'Onest'),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF061535),
      fontFamily: 'Onest',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontFamily: 'Onest'),
        bodyMedium: TextStyle(fontFamily: 'Onest'),
        titleLarge: TextStyle(fontFamily: 'Onest'),
        titleMedium: TextStyle(fontFamily: 'Onest'),
        titleSmall: TextStyle(fontFamily: 'Onest'),
      ),
    );
  }
}
