import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// Remove platform-specific imports unless needed for specific features
// import 'package:local_auth_android/local_auth_android.dart';
// import 'package:local_auth_ios/local_auth_ios.dart';

part 'biometrics_service.g.dart';

/// Service class for handling biometric authentication.
class BiometricsService {
  // Accept LocalAuthentication via constructor
  final LocalAuthentication _auth;

  // SIMPLIFIED Constructor: Takes required positional argument
  BiometricsService(this._auth);

  /// Checks if the device supports biometrics and if they are enrolled.
  Future<bool> get canAuthenticate async {
    try {
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      print('[BiometricsService] isDeviceSupported: $isDeviceSupported');
      if (!isDeviceSupported) return false;

      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      print('[BiometricsService] canCheckBiometrics: $canCheckBiometrics');
      return canCheckBiometrics;
    } catch (e) {
      print('[BiometricsService] Error checking biometrics: $e');
      return false;
    }
  }

  /// Attempts to authenticate the user using biometrics.
  ///
  /// Returns `true` if authentication is successful, `false` otherwise.
  /// Throws [PlatformException] if there's an error during the process.
  Future<bool> authenticate(String localizedReason) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true, 
          biometricOnly: false,
        ),
      );
      print('[BiometricsService] authenticate result: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      print('[BiometricsService] Authentication error: $e');
      return false;
    }
  }
}

/// Riverpod provider for the BiometricsService.
@riverpod
BiometricsService biometricsService(BiometricsServiceRef ref) {
  // Provide the actual LocalAuthentication instance
  return BiometricsService(LocalAuthentication());
} 