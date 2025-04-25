import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
// Remove platform-specific imports unless needed for specific features
// import 'package:local_auth_android/local_auth_android.dart';
// import 'package:local_auth_ios/local_auth_ios.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service class for handling biometric authentication.
class BiometricsService {
  // Accept LocalAuthentication via constructor
  final LocalAuthentication _auth;

  // Constructor with default instance for normal use
  BiometricsService({LocalAuthentication? auth}) 
    : _auth = auth ?? LocalAuthentication();

  /// Checks if the device supports biometrics and if they are enrolled.
  Future<bool> get canAuthenticate async {
    final bool canCheckBiometrics = await _auth.canCheckBiometrics;
    // Note: `isDeviceSupported()` also checks `canCheckBiometrics` internally,
    // but checking explicitly first might be slightly clearer.
    // `isDeviceSupported()` checks if hardware is present and functional.
    final bool isDeviceSupported = await _auth.isDeviceSupported();

    // Additionally, check if any biometrics are actually enrolled.
    // final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
    // bool hasEnrolledBiometrics = availableBiometrics.isNotEmpty;
    // Simplified check: canAuthenticate returns true only if supported and can check.
    // Actual enrollment check might be needed depending on desired UX.
    return canCheckBiometrics && isDeviceSupported;
  }

  /// Attempts to authenticate the user using biometrics.
  ///
  /// Returns `true` if authentication is successful, `false` otherwise.
  /// Throws [PlatformException] if there's an error during the process.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason, // Displayed to the user
        // Use default platform messages by not providing authMessages unless customization needed
        // authMessages: const <AuthMessages>[
        //   AndroidAuthMessages(
        //     signInTitle: 'Authentication Required',
        //     biometricHint: '',
        //     cancelButton: 'Cancel',
        //   ),
        //   IOSAuthMessages(
        //     cancelButton: 'Cancel',
        //   ),
        // ],
        options: const AuthenticationOptions(
          stickyAuth: false, // Changed to false
          biometricOnly: false, // Allow device credentials (PIN/Pattern/Password) as fallback
        ),
      );
    } on PlatformException catch (e) {
      // Handle specific errors, e.g., `NotAvailable`, `NotEnrolled`, `LockedOut`
      // For now, rethrow to be handled by the caller
      print('Biometric authentication error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}

/// Provider for the [BiometricsService].
final biometricsServiceProvider = Provider<BiometricsService>((ref) {
  // Provide the default instance
  return BiometricsService();
}); 