import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lockpaper/features/notes/data/app_database.dart';

/// Provider for the [NoteDao].
///
/// Depends on [appDatabaseProvider] (from app_database.dart) to get the database instance.
final noteDaoProvider = Provider<NoteDao>((ref) {
  // Watch the correct provider (which might be in loading/error state initially)
  // Handle potential error state when watching the provider
  try {
    final database = ref.watch(appDatabaseProvider);
    return database.noteDao;
  } catch (e, stackTrace) {
    // Log the error or handle it appropriately
    print('Error accessing appDatabaseProvider in noteDaoProvider: $e\n$stackTrace');
    // Depending on UI needs, might rethrow or return a dummy/error state DAO
    rethrow; // Rethrow for now to make the error visible
  }
});

/// StreamProvider that watches all notes from the database.
///
/// It uses the [noteDaoProvider] to get the DAO instance and calls
/// `watchAllNotes()` to get the stream.
final allNotesStreamProvider = StreamProvider<List<Note>>((ref) {
  // Handle potential error when watching noteDaoProvider
  try {
    final dao = ref.watch(noteDaoProvider);
    return dao.watchAllNotes();
  } catch (e, stackTrace) {
    print('Error accessing noteDaoProvider in allNotesStreamProvider: $e\n$stackTrace');
    // Return an empty stream or a stream with an error
    return Stream.error(e, stackTrace);
  }
});

/// Family StreamProvider that watches a single note by its ID.
///
/// Accepts the note ID as an argument.
final noteByIdStreamProvider = StreamProvider.family<Note?, int>((ref, noteId) {
  // Handle potential error when watching noteDaoProvider
  try {
    final dao = ref.watch(noteDaoProvider);
    return dao.watchNoteById(noteId);
  } catch (e, stackTrace) {
     print('Error accessing noteDaoProvider in noteByIdStreamProvider: $e\n$stackTrace');
    // Return an empty stream or a stream with an error
    return Stream.error(e, stackTrace);
  }
}); 