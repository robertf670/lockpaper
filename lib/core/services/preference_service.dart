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

/// Riverpod provider for the PreferenceService.
/// Uses FutureProvider since SharedPreferences.getInstance() is async.
@riverpod
Future<PreferenceService> preferenceService(PreferenceServiceRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  return PreferenceService(prefs);
}

/// Simple provider for the current state of the biometrics preference.
/// Reads from PreferenceService and handles the async nature.
@riverpod
bool biometricsEnabled(BiometricsEnabledRef ref) {
  // Watch the async preferenceService provider
  final prefServiceAsyncValue = ref.watch(preferenceServiceProvider);
  // Return the value from the service when loaded, default to true otherwise
  return prefServiceAsyncValue.when(
    data: (service) => service.isBiometricsEnabled(),
    loading: () => true, // Default to true while loading
    error: (_, __) => true, // Default to true on error (safer default?)
  );
} 