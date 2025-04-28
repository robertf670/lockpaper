import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:local_auth/error_codes.dart' as auth_error; // REMOVED
// Remove platform-specific imports unless needed for specific features
// import 'package:local_auth_android/local_auth_android.dart';
// import 'package:local_auth_ios/local_auth_ios.dart';

part 'biometrics_service.g.dart';

/// Service class for handling biometric authentication.
class BiometricsService {
  // Accept LocalAuthentication via constructor
  final LocalAuthentication _auth;
  final Ref ref;

  // SIMPLIFIED Constructor: Takes required positional argument
  BiometricsService(this._auth, this.ref);

  /// Checks if the device supports biometrics and if they are enrolled.
  Future<bool> get canAuthenticate async {
    try {
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      if (!isDeviceSupported) return false;

      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      return canCheckBiometrics;
    } catch (e) {
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
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }
}

/// Riverpod provider for the BiometricsService.
@riverpod
BiometricsService biometricsService(Ref ref) {
  // Provide the actual LocalAuthentication instance
  return BiometricsService(LocalAuthentication(), ref);
}

// Remove the duplicate manual provider
// final biometricsServiceProvider = Provider<BiometricsService>((ref) {
//   return BiometricsService(LocalAuthentication(), ref);
// }); 