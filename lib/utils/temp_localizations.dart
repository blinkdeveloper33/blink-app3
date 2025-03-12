import 'package:flutter/material.dart';

/// Temporary placeholder for AppLocalizations
/// This is used to allow the app to build while the localization system is being fixed
class AppLocalizations {
  const AppLocalizations();

  static const AppLocalizations instance = AppLocalizations();

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return instance;
  }

  // Add placeholder getters for any strings used in your app
  String get appName => 'Blink';
  String get welcome => 'Welcome';
  String get next => 'Next';
  String get cancel => 'Cancel';
  String get confirm => 'Confirm';
  String get login => 'Login';
  String get signup => 'Sign Up';
  String get emailAddress => 'Email Address';
  String get password => 'Password';
  String get forgotPassword => 'Forgot Password?';
  String get home => 'Home';
  String get profile => 'Profile';
  String get settings => 'Settings';
  String get language => 'Language';
  String get darkMode => 'Dark Mode';
  String get logout => 'Logout';
  String get error => 'Error';
  String get success => 'Success';
  String get retry => 'Retry';
  String get ok => 'OK';
  String get yes => 'Yes';
  String get no => 'No';

  // Added login screen translations
  String get welcomeBack => 'Welcome Back';
  String get loginToContinue => 'Login to continue';
  String get enterEmail => 'Enter your email';
  String get enterPassword => 'Enter your password';
  String get orContinueWith => 'Or continue with';

  // Added sign up screen translations
  String get welcomeToBlink => 'Welcome to Blink';
  String get signUpToContinue => 'Sign up to continue';

  // Added home screen translations
  String get last_known_balance => 'Last Known Balance';
  String updated_on(String date) => 'Updated on $date';
  String get recent_transactions => 'Recent Transactions';
  String get latest_financial_activities => 'Latest Financial Activities';
  String get view_all => 'View All';
  String get stories => 'Stories';
  String get stories_subtitle => 'Financial news and updates';
  String get cash_advance => 'Cash Advance';
  String get quick_funds => 'Quick Funds';

  // Added account screen translations
  String get account => 'Account';
  String get personalInformation => 'Personal Information';
  String get managePersonalDetails => 'Manage your personal details';
  String get security => 'Security';
  String get manageSecuritySettings => 'Manage your security settings';
  String get general => 'General';
  String get notifications => 'Notifications';
  String get configureNotifications => 'Configure your notifications';
  String get bankAccount => 'Bank Account';
  String get connectToGetStarted => 'Connect your bank account to get started';

  // Added account screen translations (missing strings)
  String get accountConnectionRequired => 'Account Connection Required';
  String get accountConnectionMessage =>
      'Connect your bank account to access all features';
  String get connectBankAccount => 'Connect Bank Account';
  String get availableBalance => 'Available Balance';
  String connectedOn(String date) => 'Connected on $date';
  String get helpAndSupport => 'Help & Support';
  String get getHelpWithAccount => 'Get help with your account';
  String get logOut => 'Log Out';
  String get signOutOfAccount => 'Sign out of your account';

  // Added app settings screen translations
  String get appSettings => 'App Settings';
  String get selectLanguage => 'Select Language';
  String get english => 'English';
  String get spanish => 'Spanish';
  String get toggleDarkMode => 'Toggle Dark Mode';

  // Added onboarding screen translations
  String get back => 'Back';
  String get getStarted => 'Get Started';
  String get skip => 'Skip';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return const AppLocalizations();
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
