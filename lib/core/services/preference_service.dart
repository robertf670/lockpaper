import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preference_service.g.dart';

const _biometricsEnabledKey = 'biometrics_enabled';

/// Service for managing user preferences.
class PreferenceService {
  final SharedPreferences _prefs;

  PreferenceService(this._prefs);

  /// Checks if biometric authentication is enabled by the user.
  /// Defaults to true if no preference is set yet.
  bool isBiometricsEnabled() {
    return _prefs.getBool(_biometricsEnabledKey) ?? true; // Default to enabled
  }

  /// Sets the user's preference for enabling biometric authentication.
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _prefs.setBool(_biometricsEnabledKey, enabled);
  }
}

/// Provider for the PreferenceService itself.
@Riverpod(keepAlive: true)
Future<PreferenceService> preferenceService(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return PreferenceService(prefs);
}

/// Simple boolean provider for easy access to the biometrics setting.
@riverpod
bool biometricsEnabled(Ref ref) {
  // Watch the async preference service provider
  final preferenceServiceAsyncValue = ref.watch(preferenceServiceProvider);
  // Return the current value, defaulting to true if loading/error
  return preferenceServiceAsyncValue.when(
    data: (service) => service.isBiometricsEnabled(),
    loading: () => true, // Default to true while loading
    error: (err, stack) => true, // Default to true on error as well
  );
} 