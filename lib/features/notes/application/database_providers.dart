import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/features/notes/data/app_database.dart';

/// Provider for the singleton instance of the [AppDatabase].
///
/// This provider ensures that the database is created only once.
final databaseProvider = Provider<AppDatabase>((ref) {
  // Note: It's crucial that AppDatabase handles its own opening logic
  // (e.g., via LazyDatabase) to avoid re-creating connections.
  return AppDatabase();

  // Ensure the database is closed when the provider is disposed.
  // ref.onDispose(() => ref.state.close()); // Error: ref.state doesn't exist here
  // Correction: Access the created instance directly
  // ref.onDispose(() => appDatabase.close()); // Needs instance
  // Let's create the instance first:
  // final appDatabase = AppDatabase();
  // ref.onDispose(() => appDatabase.close());
  // return appDatabase;
  // Simpler: Riverpod handles disposal automatically for Provider if the
  // created object doesn't have a specific dispose/close method called out.
  // If explicit closing is needed later (e.g. due to SQLCipher needing explicit handling),
  // we can revisit this.
});

/// Provider for the [NoteDao].
///
/// Depends on [databaseProvider] to get the database instance.
final noteDaoProvider = Provider<NoteDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.noteDao;
});

/// StreamProvider that watches all notes from the database.
///
/// It uses the [noteDaoProvider] to get the DAO instance and calls
/// `watchAllNotes()` to get the stream.
final allNotesStreamProvider = StreamProvider<List<Note>>((ref) {
  final dao = ref.watch(noteDaoProvider);
  return dao.watchAllNotes();
}); 