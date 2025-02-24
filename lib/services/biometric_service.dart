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
        _logger.w(
            'Platform not supported for biometrics: ${Platform.operatingSystem}');
        return false;
      }

      // First check if the device supports biometric authentication
      final bool deviceSupported = await _auth.isDeviceSupported();
      if (!deviceSupported) {
        _logger.w('Device does not support biometric authentication');
        return false;
      }

      // Then check if biometrics can be used
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      if (!canAuthenticateWithBiometrics) {
        _logger.w('Device cannot authenticate with biometrics');
        return false;
      }

      // Get available biometric types
      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();
      _logger.d('Available biometrics: $availableBiometrics');

      if (availableBiometrics.isEmpty) {
        _logger.w('No biometric methods available');
        return false;
      }

      if (Platform.isIOS) {
        final bool hasFaceId = availableBiometrics.contains(BiometricType.face);
        _logger.d('iOS device has Face ID: $hasFaceId');
        if (!hasFaceId) {
          _logger.w('Face ID not available on this iOS device');
        }
        return hasFaceId;
      } else if (Platform.isAndroid) {
        final bool hasFingerprint =
            availableBiometrics.contains(BiometricType.fingerprint);
        final bool hasFaceId = availableBiometrics.contains(BiometricType.face);
        _logger.d(
            'Android device has biometrics - Fingerprint: $hasFingerprint, Face: $hasFaceId');
        return hasFingerprint || hasFaceId;
      }

      return false;
    } on PlatformException catch (e) {
      _logger.e(
          'PlatformException checking biometric availability: ${e.code} - ${e.message}');
      // Handle specific platform exceptions
      switch (e.code) {
        case 'NotAvailable':
          _logger.w('Biometric hardware not available');
          break;
        case 'NotEnrolled':
          _logger.w('No biometrics enrolled on device');
          break;
        case 'PasscodeNotSet':
          _logger.w('Device security is not enabled');
          break;
        default:
          _logger.w('Unknown platform error: ${e.code}');
      }
      return false;
    } catch (e) {
      _logger.e('Unexpected error checking biometric availability: $e');
      return false;
    }
  }

  Future<Map<String, String>> getBiometricStatus() async {
    try {
      if (!Platform.isIOS && !Platform.isAndroid) {
        return {
          'available': 'false',
          'reason': 'Platform not supported',
          'canEnable': 'false'
        };
      }

      final bool deviceSupported = await _auth.isDeviceSupported();
      if (!deviceSupported) {
        return {
          'available': 'false',
          'reason': 'Device does not support biometric authentication',
          'canEnable': 'false'
        };
      }

      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      if (!canAuthenticateWithBiometrics) {
        return {
          'available': 'false',
          'reason': 'Biometric authentication not available',
          'canEnable': 'false'
        };
      }

      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return {
          'available': 'false',
          'reason': 'No biometric methods enrolled',
          'canEnable': 'true'
        };
      }

      if (Platform.isIOS && !availableBiometrics.contains(BiometricType.face)) {
        return {
          'available': 'false',
          'reason': 'Face ID not set up',
          'canEnable': 'true'
        };
      }

      final bool isEnabled = await isBiometricEnabled();
      return {
        'available': 'true',
        'enabled': isEnabled.toString(),
        'canEnable': 'true',
        'methods': availableBiometrics.map((type) => type.toString()).join(', ')
      };
    } catch (e) {
      _logger.e('Error getting biometric status: $e');
      return {
        'available': 'false',
        'reason': 'Error checking biometric status',
        'canEnable': 'false'
      };
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final status = await getBiometricStatus();

      if (enabled && status['available'] == 'false') {
        if (status['canEnable'] == 'true') {
          throw PlatformException(
            code: 'SETUP_REQUIRED',
            message: status['reason'] ?? 'Biometric setup required',
          );
        } else {
          throw PlatformException(
            code: 'NOT_AVAILABLE',
            message:
                status['reason'] ?? 'Biometric authentication not available',
          );
        }
      }

      await _secureStorage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );

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

      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        _logger.w('No biometrics enrolled');
        await setBiometricEnabled(false);
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

      // Handle specific error codes
      switch (e.code) {
        case 'NotAvailable':
          _logger.w('Biometric authentication not available');
          await setBiometricEnabled(false);
          break;
        case 'NotEnrolled':
          _logger.w('No biometrics enrolled on device');
          await setBiometricEnabled(false);
          break;
        case 'LockedOut':
          _logger.w(
              'Biometric authentication locked out due to too many attempts');
          break;
        case 'PermanentlyLockedOut':
          _logger.w('Biometric authentication permanently locked out');
          await setBiometricEnabled(false);
          break;
        default:
          _logger.w('Unknown biometric error: ${e.code}');
      }
      return false;
    } catch (e) {
      _logger.e('Unexpected error during authentication: $e');
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
