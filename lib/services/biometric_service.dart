import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastActiveTimeKey = 'last_active_time';
  static const int _sessionTimeoutMinutes = 15;

  Future<bool> isBiometricsAvailable() async {
    try {
      _logger.d('Checking biometrics availability...');

      if (!Platform.isIOS && !Platform.isAndroid) {
        _logger.w('Platform not supported for biometrics');
        return false;
      }

      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      _logger.d(
          'Can authenticate with biometrics: $canAuthenticateWithBiometrics');
      _logger.d('Device supports biometrics: $canAuthenticate');

      if (!canAuthenticate) {
        _logger.w('Device cannot authenticate with biometrics');
        return false;
      }

      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();

      _logger.d('Available biometrics: $availableBiometrics');

      if (Platform.isIOS) {
        final bool hasFaceId = availableBiometrics.contains(BiometricType.face);
        _logger.d('iOS device has Face ID: $hasFaceId');
        return hasFaceId;
      } else if (Platform.isAndroid) {
        final bool hasBiometrics = availableBiometrics.isNotEmpty;
        _logger.d('Android device has biometrics: $hasBiometrics');
        return hasBiometrics;
      }

      return false;
    } on PlatformException catch (e) {
      _logger.e(
          'PlatformException checking biometric availability: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _logger.e('Unexpected error checking biometric availability: $e');
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      if (!await isBiometricsAvailable() && enabled) {
        throw PlatformException(
          code: 'NO_BIOMETRICS',
          message: 'Biometric authentication is not available on this device',
        );
      }

      await _secureStorage.write(
          key: _biometricEnabledKey, value: enabled.toString());
      if (enabled) {
        await updateLastActiveTime();
      }
    } catch (e) {
      _logger.e('Error setting biometric enabled: $e');
      rethrow;
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      if (!await isBiometricsAvailable()) {
        return false;
      }
      final String? enabled =
          await _secureStorage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      _logger.e('Error checking if biometric is enabled: $e');
      return false;
    }
  }

  Future<void> updateLastActiveTime() async {
    try {
      await _secureStorage.write(
        key: _lastActiveTimeKey,
        value: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      _logger.e('Error updating last active time: $e');
      // Don't rethrow this error as it's not critical
    }
  }

  Future<bool> hasSessionTimedOut() async {
    try {
      if (!await isBiometricEnabled()) {
        return false;
      }

      final String? lastActiveTimeStr =
          await _secureStorage.read(key: _lastActiveTimeKey);
      if (lastActiveTimeStr == null) return true;

      final DateTime lastActiveTime = DateTime.parse(lastActiveTimeStr);
      final Duration difference = DateTime.now().difference(lastActiveTime);
      return difference.inMinutes >= _sessionTimeoutMinutes;
    } catch (e) {
      _logger.e('Error checking session timeout: $e');
      return true;
    }
  }

  Future<bool> authenticate() async {
    try {
      _logger.d('Starting biometric authentication...');

      if (!await isBiometricsAvailable()) {
        _logger.w('Biometrics not available');
        return false;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: Platform.isIOS
            ? 'Use Face ID to authenticate'
            : 'Please authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      _logger.d('Authentication result: $didAuthenticate');

      if (didAuthenticate) {
        await updateLastActiveTime();
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      _logger.e(
          'PlatformException during authentication: ${e.code} - ${e.message}');
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        await setBiometricEnabled(false);
      }
      // Don't throw the error, just return false
      return false;
    } catch (e) {
      _logger.e('Unexpected error during authentication: $e');
      // Don't throw the error, just return false
      return false;
    }
  }

  Future<void> clearBiometricData() async {
    try {
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _secureStorage.delete(key: _lastActiveTimeKey);
    } catch (e) {
      _logger.e('Error clearing biometric data: $e');
      // Don't rethrow as this is cleanup
    }
  }
}
