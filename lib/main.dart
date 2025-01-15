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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blink',
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).currentTheme,
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
