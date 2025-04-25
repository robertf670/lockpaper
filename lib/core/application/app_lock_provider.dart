import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider holding the current lock state of the application.
///
/// - `true`: App is locked, LockScreen should be shown.
/// - `false`: App is unlocked, main content can be shown.
final appLockStateProvider = StateProvider<bool>((ref) {
  // App starts in a locked state by default.
  return true;
}); 