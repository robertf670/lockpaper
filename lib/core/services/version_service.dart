import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/core/models/release_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'version_service.g.dart';

const _lastVersionKey = 'last_app_version';

/// The current app version
/// This should be updated manually when updating pubspec.yaml
/// When releasing a new version:
/// 1. Update pubspec.yaml version
/// 2. Update android/app/build.gradle.kts versionCode and versionName
/// 3. Update currentAppVersion here
/// 4. Add a new ReleaseInfo entry to the versionHistory list below
const String currentAppVersion = '1.2.0';

/// Service for managing app version information and history
class VersionService {
  final SharedPreferences _prefs;

  VersionService(this._prefs);

  /// Get the current app version
  String get currentVersion => currentAppVersion;

  /// Get the last seen version (null if first launch)
  String? get lastSeenVersion => _prefs.getString(_lastVersionKey);

  /// Check if this is a fresh install (no previous version recorded)
  bool get isFreshInstall => lastSeenVersion == null;

  /// Check if the app has been updated since last launch
  bool get isUpdated => 
      !isFreshInstall && lastSeenVersion != currentVersion;

  /// Store the current version as last seen
  Future<void> markVersionSeen() async {
    await _prefs.setString(_lastVersionKey, currentVersion);
  }

  /// Get all release notes in reverse chronological order
  List<ReleaseInfo> getReleaseHistory() {
    return versionHistory;
  }

  /// Get release notes for versions after the last seen version
  /// Returns empty list if no updates or fresh install
  List<ReleaseInfo> getNewReleaseNotes() {
    if (isFreshInstall) {
      // For fresh installs, we don't show release notes
      return [];
    }

    if (!isUpdated) {
      // No updates
      return [];
    }

    // Filter versions newer than last seen version
    return versionHistory.where((release) {
      // Simple version comparison - not semantic versioning aware
      return release.version.compareTo(lastSeenVersion!) > 0;
    }).toList();
  }
}

/// Provider for the VersionService
@Riverpod(keepAlive: true)
Future<VersionService> versionService(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  return VersionService(prefs);
}

/// Static version history data
/// Add new versions at the TOP of this list (reverse chronological order)
final List<ReleaseInfo> versionHistory = [
  // Version 1.2.0 - New Entry (Pin Note Feature)
  ReleaseInfo(
    version: '1.2.0',
    releaseDate: DateTime.now(), // Use current date for release
    changes: [
      ReleaseChange(
        category: 'Feature',
        description: 'Added ability to pin notes to the top of the list.',
      ),
      ReleaseChange(
        category: 'Improvement',
        description: 'Pinned notes now appear first in the notes list and editor.',
      ),
      ReleaseChange(
        category: 'Improvement',
        description: 'Updated app versioning and What\'s New mechanism.',
      ),
    ],
  ),
  // Version 1.1.0 - New Entry
  ReleaseInfo(
    version: '1.1.0',
    releaseDate: DateTime(2024, 5, 30),
    changes: [
      ReleaseChange(
        category: 'Feature',
        description: 'Added "What\'s New" screen to highlight app updates',
      ),
      ReleaseChange(
        category: 'Feature',
        description: 'Added version history in settings for tracking changes',
      ),
      ReleaseChange(
        category: 'Improvement',
        description: 'Enhanced navigation with more reliable screen transitions',
      ),
    ],
  ),
  // Current version (1.0.0)
  ReleaseInfo(
    version: '1.0.0',
    releaseDate: DateTime(2024, 5, 29),
    changes: [
      ReleaseChange(
        category: 'Initial Release',
        description: 'First public release of Lockpaper',
      ),
      ReleaseChange(
        category: 'Feature',
        description: 'End-to-end encrypted notes with AES-256',
      ),
      ReleaseChange(
        category: 'Feature',
        description: 'Biometric and PIN authentication',
      ),
      ReleaseChange(
        category: 'Feature',
        description: 'Markdown editing and preview',
      ),
    ],
  ),
]; 