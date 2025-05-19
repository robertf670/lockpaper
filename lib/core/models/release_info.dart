import 'package:flutter/foundation.dart';

/// Represents a single change in a release
class ReleaseChange {
  final String description;
  final String? category;

  const ReleaseChange({
    required this.description,
    this.category,
  });
}

/// Represents a version release with its changes
class ReleaseInfo {
  final String version;
  final DateTime releaseDate;
  final List<ReleaseChange> changes;

  const ReleaseInfo({
    required this.version,
    required this.releaseDate,
    required this.changes,
  });
} 