import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import for navigation
import 'package:drift/drift.dart' as drift; // Import drift for Companion
import 'package:lockpaper/features/notes/application/database_providers.dart'; // Import providers
import 'package:lockpaper/features/notes/data/app_database.dart'; // Import Note
import 'package:lockpaper/features/notes/presentation/screens/notes_list_screen.dart'; // Import NotesListScreen for navigation fallback

/// Screen for creating or editing a note.
class NoteEditorScreen extends ConsumerStatefulWidget {
  /// Route name for navigation.
  static const String routeName = 'noteEditor';

  /// The ID of the note to edit, or null if creating a new note.
  final int? noteId;

  const NoteEditorScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  bool _didLoadInitialData = false;

  // TODO: Load existing note data if widget.noteId is not null
  // TODO: Implement delete logic

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose controllers
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // --- Methods ---

  Future<void> _saveNote() async {
    final dao = ref.read(noteDaoProvider);
    final navigator = GoRouter.of(context); // Use GoRouter for navigation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final title = _titleController.text;
    final body = _bodyController.text;

    // Prevent saving empty notes (optional, adjust as needed)
    if (title.isEmpty && body.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Cannot save an empty note.')),
      );
      return;
    }

    final now = DateTime.now();

    try {
      if (widget.noteId == null) {
        // Insert new note
        final companion = NotesCompanion(
          title: drift.Value(title),
          body: drift.Value(body),
          // createdAt is handled by default
        );
        await dao.insertNote(companion);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Note saved successfully.')),
        );
      } else {
        // Update existing note
        final companion = NotesCompanion(
          id: drift.Value(widget.noteId!),
          title: drift.Value(title),
          body: drift.Value(body),
          updatedAt: drift.Value(now), // Set update timestamp
        );
        final success = await dao.updateNote(companion);
        if (success) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Note updated successfully.')),
          );
        } else {
          // Handle update failure (e.g., note not found, should be rare)
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Failed to update note.')),
          );
        }
      }
      // Navigate back to the list screen after saving
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        // Fallback if cannot pop (e.g., deep link directly to editor)
        navigator.goNamed(NotesListScreen.routeName);
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error saving note: $e')),
      );
    }
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    final isNewNote = widget.noteId == null;

    // Watch the provider if editing, otherwise use a placeholder value
    final noteAsyncValue = isNewNote
        ? const AsyncData<Note?>(null) // Provide a default AsyncData state for new notes
        : ref.watch(noteByIdStreamProvider(widget.noteId!));

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewNote ? 'New Note' : 'Edit Note'),
        // Show actions only when data is loaded or when creating a new note
        actions: (isNewNote || noteAsyncValue.hasValue) ? [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: 'Save Note',
            onPressed: _saveNote, // Call save method
          ),
          if (!isNewNote)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Note',
              onPressed: () {
                // TODO: Implement delete logic
              },
            ),
        ] : [], // Hide actions while loading/error
      ),
      // Use .when on the AsyncValue to handle states
      body: noteAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading note: $error'),
        ),
        data: (note) {
          // Populate controllers *once* when data arrives for an existing note
          if (!isNewNote && note != null && !_didLoadInitialData) {
            _titleController.text = note.title;
            _bodyController.text = note.body;
            // Use WidgetsBinding to delay setting the flag until after this build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                 _didLoadInitialData = true;
              }
            });
          }

          // Always return the editor fields layout
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(hintText: 'Title'),
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Note content...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    expands: true,
                    controller: _bodyController,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 