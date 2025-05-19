import 'package:drift/drift.dart';

/// Defines the structure of the 'notes' table in the database.
@DataClassName('Note') // Customize the generated data class name
class Notes extends Table {
  /// Primary key, auto-incrementing.
  IntColumn get id => integer().autoIncrement()();

  /// Title of the note (max 100 chars, enforced by application logic).
  TextColumn get title => text().withLength(min: 0, max: 100)();

  /// Body content of the note.
  TextColumn get body => text()();

  /// Timestamp when the note was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Timestamp when the note was last updated (nullable).
  DateTimeColumn get updatedAt => dateTime().nullable()();

  /// Whether the note is pinned (defaults to false).
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
} 