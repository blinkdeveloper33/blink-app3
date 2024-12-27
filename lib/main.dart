import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:blink_app/features/splash/presentation/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/services/storage_service.dart';
import 'package:blink_app/features/auth/presentation/login_screen.dart';
import 'package:blink_app/features/auth/presentation/sign_up_screen.dart';
import 'package:blink_app/features/home/presentation/home_screen.dart';
import 'package:blink_app/features/error/presentation/error_screen.dart';
import 'package:blink_app/features/insights/presentation/financial_insights_screen.dart';
import 'package:blink_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:blink_app/providers/financial_data_provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final storageService = StorageService();
  await storageService.init();
  final authService = AuthService(storageService: storageService);
  final themeProvider = ThemeProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        Provider<AuthService>(create: (_) => authService),
        Provider<StorageService>(create: (_) => storageService),
        ChangeNotifierProvider(
            create: (_) => FinancialDataProvider(authService)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Blink',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeProvider.themeMode,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('es', ''),
            ],
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/home': (context) => const HomeScreen(),
              '/insights': (context) => const FinancialInsightsScreen(),
            },
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (_) =>
                    ErrorScreen(message: "Route not found: ${settings.name}"),
              );
            },
          );
        },
      ),
    ),
  );
}
