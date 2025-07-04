import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/features/notes/data/note_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'dart:async'; // Import for StreamSubscription
// import 'package:sqflite_sqlcipher/sqflite.dart' show Database;
// TODO: Import sqflite_sqlcipher if needed for encryption

// Import the generated part file
part 'app_database.g.dart';

@DriftAccessor(tables: [Notes])
class NoteDao extends DatabaseAccessor<AppDatabase> with _$NoteDaoMixin {
  /// Creates the DAO.
  NoteDao(super.db);

  /// Watches all notes, ordered by pinned status and then creation date descending.
  Stream<List<Note>> watchAllNotes() => (
    select(notes)
      ..orderBy([
        (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ])
  ).watch();

  /// Watches a single note by its ID.
  Stream<Note?> watchNoteById(int id) =>
      (select(notes)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Inserts a new note.
  Future<int> insertNote(NotesCompanion note) => into(notes).insert(note);

  /// Updates an existing note.
  Future<bool> updateNote(NotesCompanion note) => update(notes).replace(note);

  /// Updates the pinned status of a note.
  Future<bool> updatePinStatus(int noteId, bool isPinned) async {
    final count = await (update(notes)..where((t) => t.id.equals(noteId)))
        .write(NotesCompanion(isPinned: Value(isPinned)));
    return count > 0;
  }

  /// Deletes a note.
  Future<int> deleteNote(NotesCompanion note) => delete(notes).delete(note);
}

/// The Drift database class for the application.
@DriftDatabase(tables: [Notes], daos: [NoteDao])
class AppDatabase extends _$AppDatabase {
  /// Creates the database connection.
  /// The QueryExecutor is now passed in, making it testable and allowing
  /// lazy initialization based on the encryption key.
  AppDatabase(super.e);

  // Added DAO getter
  @override
  NoteDao get noteDao => NoteDao(this);

  /// The schema version of the database.
  /// Increment this number whenever you change the schema.
  @override
  int get schemaVersion => 2;

  // Override close method to clean up resources
  @override
  Future<void> close() {
    // print("Closing AppDatabase...");
    return super.close();
  }

  // TODO: Implement migrations if schema changes in the future
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        // We added the isPinned column to the notes table
        await m.addColumn(notes, notes.isPinned);
      }
    },
  );
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
    // print("Set sqlite3.tempDirectory to: $cachebase (inside LazyDatabase)");

    // Use the standard NativeDatabase constructor (runs on the calling isolate)
    // The override in main.dart should ensure SQLCipher is loaded.
    return NativeDatabase(file, 
      setup: (rawDb) { // rawDb is a sqlite3.Database
        // print("NativeDatabase setup: Applying PRAGMA key...");
        // Execute PRAGMA key using string interpolation (binding not supported for PRAGMA)
        // Ensure the key doesn't contain problematic characters (like ';') 
        // - our Base64URL key should be safe.
        rawDb.execute("PRAGMA key = '$encryptionKey';"); // Use interpolation
        // print("NativeDatabase setup: PRAGMA key applied.");
        try {
          final result = rawDb.select('PRAGMA cipher_version;');
          // print("SQLCipher version via PRAGMA: ${result.firstOrNull?['cipher_version']}");
          if (result.isEmpty) {
            // print("WARNING: PRAGMA cipher_version returned empty. SQLCipher might not be active!");
          }
        } catch (e) {
          // print("Error executing PRAGMA cipher_version: $e");
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

/// StateNotifier for managing the AppDatabase lifecycle.
class AppDatabaseNotifier extends StateNotifier<AppDatabase?> {
  final Ref _ref;
  AppDatabase? _databaseInstance; // Hold the single instance

  AppDatabaseNotifier(this._ref) : super(null) {
    _listenToKey();
  }

  void _listenToKey() {
    _ref.listen<String?>(encryptionKeyProvider, (previousKey, newKey) async {
      if (newKey != null && _databaseInstance == null) {
        // print("Encryption key available, opening database...");
        try {
          final executor = _openConnection(newKey);
          _databaseInstance = AppDatabase(executor);
          state = _databaseInstance; // Update state with the created instance
          // print("Database instance created and ready.");
        } catch (e) {
          // print("Error opening database: $e");
          // Optionally set state to an error state or keep it null
          state = null; 
        }
      } else if (newKey == null && _databaseInstance != null) {
        // Key removed (e.g., explicit logout/reset in future?), close DB
        // print("Encryption key removed, closing database...");
        _closeDatabase();
      }
    }, fireImmediately: true); // Fire immediately to check initial key state
  }

  Future<void> _closeDatabase() async {
    await _databaseInstance?.close();
    _databaseInstance = null;
    // Check if mounted before modifying state during disposal
    if (mounted) {
      state = null;
    }
    // print("Database instance closed.");
  }

  @override
  void dispose() {
    // print("Disposing AppDatabaseNotifier, closing database.");
    _closeDatabase(); // Ensure database is closed when notifier is disposed
    super.dispose();
  }
}

/// Provider for the AppDatabase instance.
/// Manages the database lifecycle based on the encryption key.
final appDatabaseProvider = StateNotifierProvider<AppDatabaseNotifier, AppDatabase?>((ref) {
  return AppDatabaseNotifier(ref);
});

// REMOVED old Provider
// final appDatabaseProvider = Provider<AppDatabase>((ref) {
//   final key = ref.watch(encryptionKeyProvider);
//   if (key == null) {
//     throw Exception("AppDatabase requested but encryption key is not available.");
//   }
//   final executor = _openConnection(key);
//   return AppDatabase(executor);
// }); 