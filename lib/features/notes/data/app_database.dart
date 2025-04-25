import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:lockpaper/features/notes/data/note_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// import 'package:sqflite_sqlcipher/sqflite.dart' show Database;
// TODO: Import sqflite_sqlcipher if needed for encryption

// Import the generated part file
part 'app_database.g.dart';

@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  /// Creates the DAO.
  NoteDao(AppDatabase db) : super(db);

  /// Watches all notes, ordered by creation date descending.
  Stream<List<Note>> watchAllNotes() =>
      (select(notes)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  /// Watches a single note by its ID.
  Stream<Note?> watchNoteById(int id) =>
      (select(notes)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Inserts a new note.
  Future<int> insertNote(NotesCompanion note) => into(notes).insert(note);

  /// Updates an existing note.
  Future<bool> updateNote(NotesCompanion note) => update(notes).replace(note);

  /// Deletes a note.
  Future<int> deleteNote(NotesCompanion note) => delete(notes).delete(note);
}

/// The Drift database class for the application.
@DriftDatabase(tables: [Notes], daos: [NoteDao])
class AppDatabase extends _$AppDatabase {
  /// Creates the database connection.
  AppDatabase() : super(_openConnection());

  // Added DAO getter
  NoteDao get noteDao => NoteDao(this);

  /// The schema version of the database.
  /// Increment this number whenever you change the schema.
  @override
  int get schemaVersion => 1;

  // TODO: Implement migrations if schema changes in the future
  // @override
  // MigrationStrategy get migration => MigrationStrategy(
  //   onCreate: (Migrator m) => m.createAll(),
  //   onUpgrade: (Migrator m, int from, int to) async {
  //     if (from == 1) {
  //       // Example migration: await m.addColumn(notes, notes.priority);
  //     }
  //   },
  // );
}

/// Creates the database connection based on the platform.
///
/// For native platforms (Android/iOS), it uses `NativeDatabase`.
/// For web, it would use `WebDatabase` (not implemented here).
LazyDatabase _openConnection() {
  // TODO: Add encryption key handling with sqflite_sqlcipher later
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));

    // // Example with SQLCipher:
    // final database = await Database.openDatabase(
    //   file.path,
    //   password: 'your_secret_password', // Replace with secure key management
    // );
    // return NativeDatabase.opened(database);

    // Default without encryption for now:
    return NativeDatabase.createInBackground(file);
  });
} 