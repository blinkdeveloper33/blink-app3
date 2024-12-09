import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/features/splash/presentation/splash_screen.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/services/storage_service.dart';
import 'package:myapp/features/auth/presentation/login_screen.dart';
import 'package:myapp/features/home/presentation/home_screen.dart';

Future<void> main() async {
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
    // Optionally, handle the error, e.g., show a fallback screen or exit
  }

  // Initialize StorageService (Singleton)
  final storageService = StorageService();
  try {
    await storageService.init();
    logger.i('StorageService initialized successfully.');
  } catch (e, stackTrace) {
    logger.e('Error initializing StorageService: $e',
        error: e, stackTrace: stackTrace);
    // Optionally, handle the error, e.g., show a fallback screen or exit
  }

  // Initialize AuthService
  final authService = AuthService(storageService: storageService);
  try {
    await authService.init();
    logger.i('AuthService initialized successfully.');
  } catch (e, stackTrace) {
    logger.e('Error initializing AuthService: $e',
        error: e, stackTrace: stackTrace);
    // Optionally, handle the error
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
        // Add other providers here if needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Builds the application's theme.
  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF061535),
      fontFamily: 'Onest',
      // Define other theme properties as needed
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blink',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const SplashScreen(),
      // Define routes if needed
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(
              userName: '',
              bankAccountId: '',
            ),
        // Add other routes here
      },
    );
  }
}
