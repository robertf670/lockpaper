import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/features/notes/data/note_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
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
  /// The QueryExecutor is now passed in, making it testable and allowing
  /// lazy initialization based on the encryption key.
  AppDatabase(QueryExecutor e) : super(e);

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

/// Creates the Drift query executor using NativeDatabase with SQLCipher.
QueryExecutor _openConnection(String encryptionKey) {
  // Use LazyDatabase to perform async setup before opening sync
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db_encrypted.sqlite'));

    // Configure temp directory for sqlite3 just before opening
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;
    print("Set sqlite3.tempDirectory to: $cachebase (inside LazyDatabase)");

    // Use the standard NativeDatabase constructor (runs on the calling isolate)
    // The override in main.dart should ensure SQLCipher is loaded.
    return NativeDatabase(file, 
      setup: (rawDb) { // rawDb is a sqlite3.Database
        print("NativeDatabase setup: Applying PRAGMA key...");
        // Execute PRAGMA key using string interpolation (binding not supported for PRAGMA)
        // Ensure the key doesn't contain problematic characters (like ';') 
        // - our Base64URL key should be safe.
        rawDb.execute("PRAGMA key = '$encryptionKey';"); // Use interpolation
        print("NativeDatabase setup: PRAGMA key applied.");
        try {
          final result = rawDb.select('PRAGMA cipher_version;');
          print("SQLCipher version via PRAGMA: ${result.firstOrNull?['cipher_version']}");
          if (result.isEmpty) {
            print("WARNING: PRAGMA cipher_version returned empty. SQLCipher might not be active!");
          }
        } catch (e) {
          print("Error executing PRAGMA cipher_version: $e");
        }
      },
    );
  });
}

// --- Riverpod Providers ---

/// Provider for the encryption key.
/// 
/// This will be null initially and set by the authentication flow (LockScreen)
/// once the user successfully authenticates.
final encryptionKeyProvider = StateProvider<String?>((ref) => null);

/// Provider for the AppDatabase.
/// Now a FutureProvider because opening the DB is async.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  // Use watch instead of read if you want this provider to rebuild
  // automatically when the key changes (e.g., on first set).
  final key = ref.watch(encryptionKeyProvider);

  if (key == null) {
    // Database cannot be opened without the key.
    // Using a simple Provider means dependents might error if they try to read
    // before the key is set. A FutureProvider might offer better loading states.
    // Consider how UI will handle this state.
    throw Exception("AppDatabase requested but encryption key is not available.");
  }

  // _openConnection now returns QueryExecutor directly via LazyDatabase
  final executor = _openConnection(key);
  return AppDatabase(executor);
}); 