import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Instant Cash Access'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In en, this message translates to:
  /// **'Get BlinkAdvance cash advances from \$150 to \$300, no credit check required.'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Smart Money Management'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In en, this message translates to:
  /// **'Track spending, set budgets, and make informed financial decisions.'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Transparent & Fair'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In en, this message translates to:
  /// **'No hidden fees, automatic repayment on your chosen date.'**
  String get onboardingSubtitle3;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Welcome back message on login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// Login screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Log in to enter your Blink Account'**
  String get loginToContinue;

  /// Welcome message on signup screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Blink'**
  String get welcomeToBlink;

  /// Signup screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Are you new? Sign up to get Cash'**
  String get signUpToContinue;

  /// Email input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// Password input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// Google sign in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Apple sign in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// Divider text for social login
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// Forgot password button
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// Sign up tab/button text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Account screen title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// App Settings screen title
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// General settings section title
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// Language selection option
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Spanish language option
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// Personal Information section title
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// Personal Information section subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your personal details'**
  String get managePersonalDetails;

  /// Security section title
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Security section subtitle
  ///
  /// In en, this message translates to:
  /// **'Manage your security settings'**
  String get manageSecuritySettings;

  /// Notifications section title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Notifications section subtitle
  ///
  /// In en, this message translates to:
  /// **'Configure your notifications'**
  String get configureNotifications;

  /// Dark mode option
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Dark mode toggle description
  ///
  /// In en, this message translates to:
  /// **'Toggle dark mode appearance'**
  String get toggleDarkMode;

  /// Help and support option
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// Help and support description
  ///
  /// In en, this message translates to:
  /// **'Get help with your account'**
  String get getHelpWithAccount;

  /// Log out button text
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// Log out description
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutOfAccount;

  /// Bank account section title
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get bankAccount;

  /// Connect bank account button text
  ///
  /// In en, this message translates to:
  /// **'Connect Bank Account'**
  String get connectBankAccount;

  /// Connect bank account subtitle
  ///
  /// In en, this message translates to:
  /// **'Connect your account to get started'**
  String get connectToGetStarted;

  /// Account connection required title
  ///
  /// In en, this message translates to:
  /// **'Account connection required'**
  String get accountConnectionRequired;

  /// Account connection required message
  ///
  /// In en, this message translates to:
  /// **'To use Blink, you need to connect your bank account through Plaid. This allows us to securely access your financial data.'**
  String get accountConnectionMessage;

  /// Available balance label
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get availableBalance;

  /// Bank account connection date
  ///
  /// In en, this message translates to:
  /// **'Connected on {date}'**
  String connectedOn(String date);

  /// Settings section title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Account settings section title
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// Preferences section title
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// Morning greeting on home screen
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get greeting_morning;

  /// Afternoon greeting on home screen
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get greeting_afternoon;

  /// Evening greeting on home screen
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get greeting_evening;

  /// Available balance label
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get available_balance;

  /// Account number label
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get account_number;

  /// View details button text
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get view_details;

  /// Stories section title
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get stories;

  /// Stories section subtitle
  ///
  /// In en, this message translates to:
  /// **'Stay informed with latest updates'**
  String get stories_subtitle;

  /// View all button text
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get view_all;

  /// Loading account details message
  ///
  /// In en, this message translates to:
  /// **'Loading Account Details'**
  String get loading_account_details;

  /// Days text for countdown
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// Repay now button text
  ///
  /// In en, this message translates to:
  /// **'Repay Now'**
  String get repay_now;

  /// Send money button text
  ///
  /// In en, this message translates to:
  /// **'Send Money'**
  String get send_money;

  /// Request money button text
  ///
  /// In en, this message translates to:
  /// **'Request Money'**
  String get request_money;

  /// Recent transactions section title
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recent_transactions;

  /// No transactions message
  ///
  /// In en, this message translates to:
  /// **'No recent transactions'**
  String get no_transactions;

  /// See all transactions button text
  ///
  /// In en, this message translates to:
  /// **'See All Transactions'**
  String get see_all_transactions;

  /// Quick actions section title
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quick_actions;

  /// Favorites section title
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Label for last known balance
  ///
  /// In en, this message translates to:
  /// **'Last Known Balance'**
  String get last_known_balance;

  /// Updated date label
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updated_on(String date);

  /// Quick funds label
  ///
  /// In en, this message translates to:
  /// **'Quick Funds'**
  String get quick_funds;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Analyze action label
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyze;

  /// Subtitle for recent transactions section
  ///
  /// In en, this message translates to:
  /// **'Your latest financial activities'**
  String get latest_financial_activities;

  /// Title for cash advance section
  ///
  /// In en, this message translates to:
  /// **'Cash Advance'**
  String get cash_advance;

  /// Title for Blink Repay section
  ///
  /// In en, this message translates to:
  /// **'Blink Repay'**
  String get blink_repay;

  /// Title for Blink Insights section
  ///
  /// In en, this message translates to:
  /// **'Blink Insights'**
  String get blink_insights;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
