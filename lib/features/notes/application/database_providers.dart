import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/features/notes/data/app_database.dart';

/// Provider for the [NoteDao].
///
/// Depends on [appDatabaseProvider] to get the database instance.
/// Throws an exception if the database is not available (key not set).
final noteDaoProvider = Provider<NoteDao>((ref) {
  // Watch the AppDatabase? state from the StateNotifierProvider
  final database = ref.watch(appDatabaseProvider);

  // If the database instance is not yet available (still null),
  // dependents should handle this state (e.g., show loading).
  if (database == null) {
    throw Exception("NoteDao requested but AppDatabase is not available (key not set or DB failed to open).");
  }
  // Database is available, return the DAO
  return database.noteDao;
  // Removed the try-catch as the null check handles the main expected issue.
  // Other unexpected errors during watch will propagate naturally.
});

/// StreamProvider that watches all notes from the database.
///
/// Handles the case where the underlying DAO provider might throw an exception
/// if the database isn't ready yet.
final allNotesStreamProvider = StreamProvider<List<Note>>((ref) {
  try {
    // Watch the noteDaoProvider. If it throws (DB not ready), catch it.
    final dao = ref.watch(noteDaoProvider);
    return dao.watchAllNotes();
  } catch (e, stackTrace) {
    // Log the error (likely DB not ready) and return an error stream
    // print('Error watching noteDaoProvider in allNotesStreamProvider: $e\n$stackTrace');
    // UI needs to handle this stream error state (e.g., show loading/error message)
    return Stream.error(e, stackTrace);
  }
});

/// Family StreamProvider that watches a single note by its ID.
///
/// Handles the case where the underlying DAO provider might throw an exception.
final noteByIdStreamProvider = StreamProvider.family<Note?, int>((ref, noteId) {
  try {
    // Watch the noteDaoProvider. If it throws (DB not ready), catch it.
    final dao = ref.watch(noteDaoProvider);
    return dao.watchNoteById(noteId);
  } catch (e, stackTrace) {
    // Log the error and return an error stream
    // print('Error watching noteDaoProvider in noteByIdStreamProvider($noteId): $e\n$stackTrace');
    return Stream.error(e, stackTrace);
  }
}); 