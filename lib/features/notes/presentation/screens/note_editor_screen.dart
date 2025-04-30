import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import for navigation
import 'package:drift/drift.dart' as drift; // Import drift for Companion
import 'package:lockpaper/features/notes/application/database_providers.dart'; // Import providers
import 'package:lockpaper/features/notes/data/app_database.dart'; // Import Note
import 'package:lockpaper/features/notes/presentation/screens/notes_list_screen.dart'; // Import NotesListScreen for navigation fallback
import 'package:flutter_markdown/flutter_markdown.dart'; // Import Markdown

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
  bool _isPreviewMode = false; // State variable for preview toggle

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
      bool didPop = false; // Flag to track if navigation happened
      if (widget.noteId == null) {
        // Insert new note
        final companion = NotesCompanion(
          title: drift.Value(title),
          body: drift.Value(body),
          // createdAt is handled by default
        );
        await dao.insertNote(companion);
        
        // Navigate FIRST
        if (navigator.canPop()) {
          navigator.pop();
          didPop = true;
        } else {
          navigator.goNamed(NotesListScreen.routeName);
        }
        // Show SnackBar AFTER navigation (if popped)
        if (didPop) {
          // scaffoldMessenger.showSnackBar(
          //   const SnackBar(content: Text('Note saved successfully.')),
          // ); // <<< REMOVED SNACKBAR
        }

      } else {
        // Update existing note
        final companion = NotesCompanion(
          id: drift.Value(widget.noteId!),
          title: drift.Value(title),
          body: drift.Value(body),
          updatedAt: drift.Value(now), // Set update timestamp
        );
        final success = await dao.updateNote(companion);

        // Navigate FIRST
        if (navigator.canPop()) {
            navigator.pop();
            didPop = true;
          } else {
            navigator.goNamed(NotesListScreen.routeName);
          }

        // Show SnackBar AFTER navigation (if popped)
        if (didPop) {
           if (success) {
            // scaffoldMessenger.showSnackBar(
            //   const SnackBar(content: Text('Note updated successfully.')),
            // ); // <<< REMOVED SNACKBAR
          } else {
            // scaffoldMessenger.showSnackBar(
            //   const SnackBar(content: Text('Failed to update note.')),
            // ); // <<< REMOVED SNACKBAR
          }
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error saving note: $e')),
      );
    }
  }

  Future<void> _deleteNote() async {
    // Can only delete existing notes
    if (widget.noteId == null) return;

    final navigator = GoRouter.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final dao = ref.read(noteDaoProvider);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text('Are you sure you want to permanently delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Not confirmed
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true), // Confirmed
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // If user confirmed deletion
    if (confirmed == true) {
      try {
        // Create a companion with only the ID for deletion
        final companion = NotesCompanion(id: drift.Value(widget.noteId!));
        final count = await dao.deleteNote(companion);

        if (count > 0) {
          // Pop FIRST
          bool didPop = false;
          if (navigator.canPop()) {
            navigator.pop();
            didPop = true;
          } else {
            navigator.goNamed(NotesListScreen.routeName);
          }

          // Then show SnackBar (might still be problematic if context is gone)
          // This relies on the ScaffoldMessenger still being accessible briefly
          // or potentially using the root messenger if configured.
          // A more robust solution might involve passing state back.
          if (didPop) { // Only show if we popped back to a screen with a Scaffold
             // scaffoldMessenger.showSnackBar(
             //   const SnackBar(content: Text('Note deleted successfully.')),
             // ); // <<< REMOVED SNACKBAR
          }

        } else {
          // Note might have been deleted already
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Note not found for deletion.')),
          );
        }
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error deleting note: $e')),
        );
      }
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

    // Populate controllers *once* when data arrives for an existing note
    if (!isNewNote && noteAsyncValue.hasValue && noteAsyncValue.value != null) {
      _titleController.text = noteAsyncValue.value!.title;
      _bodyController.text = noteAsyncValue.value!.body;
    }

    // REMOVED Hero widget wrapping Scaffold
    // return Hero(
    //   tag: 'fab', // Use the SAME tag as the FAB
    //   child: Scaffold(
    return Scaffold(
        appBar: AppBar(
          title: Text(isNewNote ? 'New Note' : 'Edit Note'),
          // Show actions only when data is loaded or when creating a new note
          actions: (isNewNote || noteAsyncValue.hasValue) ? [
            // Preview Toggle Button
            IconButton(
              icon: Icon(_isPreviewMode ? Icons.edit_note_outlined : Icons.visibility_outlined),
              tooltip: _isPreviewMode ? 'Edit Note' : 'Preview Note',
              onPressed: () {
                setState(() {
                  _isPreviewMode = !_isPreviewMode;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.save_alt_outlined),
              tooltip: 'Save Note',
              onPressed: _saveNote, // Call save method
            ),
            if (!isNewNote)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete Note',
                onPressed: _deleteNote, // Call delete method
              ),
          ] : [], // Hide actions while loading/error
        ),
        // Restore the original body structure
        body: noteAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error loading note: $error'),
          ),
          data: (note) {
            // Define the Markdown stylesheet MANUALLY using the current theme
            final theme = Theme.of(context);
            final textTheme = theme.textTheme;
            final colorScheme = theme.colorScheme;
            final baseStyle = textTheme.bodyMedium!;
            
            // Create stylesheet manually, not using fromTheme()
            final markdownStyleSheet = MarkdownStyleSheet(
              a: TextStyle(color: colorScheme.primary), // Link style
              p: baseStyle,
              pPadding: const EdgeInsets.symmetric(vertical: 4.0), // Add some paragraph spacing
              h1: textTheme.headlineLarge,
              h1Padding: const EdgeInsets.symmetric(vertical: 8.0),
              h2: textTheme.headlineMedium,
              h2Padding: const EdgeInsets.symmetric(vertical: 6.0),
              h3: textTheme.headlineSmall,
              h3Padding: const EdgeInsets.symmetric(vertical: 4.0),
              h4: textTheme.titleLarge,
              h4Padding: const EdgeInsets.symmetric(vertical: 4.0),
              h5: textTheme.titleMedium,
              h5Padding: const EdgeInsets.symmetric(vertical: 4.0),
              h6: textTheme.titleSmall,
              h6Padding: const EdgeInsets.symmetric(vertical: 4.0),
              em: baseStyle.copyWith(fontStyle: FontStyle.italic),
              strong: baseStyle.copyWith(fontWeight: FontWeight.bold),
              del: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
              blockquote: textTheme.bodyLarge!.copyWith(color: colorScheme.onSurfaceVariant),
              blockquotePadding: const EdgeInsets.all(8.0),
              blockquoteDecoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha((255 * 0.1).round()),
                border: Border(left: BorderSide(color: colorScheme.primary, width: 4.0)),
              ),
              code: baseStyle.copyWith(
                fontFamily: 'monospace',
                backgroundColor: colorScheme.onSurface.withAlpha((255 * 0.1).round()),
                fontSize: baseStyle.fontSize! * 0.9, // Slightly smaller for code
              ),
              codeblockPadding: const EdgeInsets.all(8.0),
              codeblockDecoration: BoxDecoration(
                color: colorScheme.onSurface.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: theme.dividerColor.withAlpha((255 * 0.5).round()), width: 1.0),
              ),
              horizontalRuleDecoration: BoxDecoration(
                border: Border(top: BorderSide(width: 1.5, color: theme.dividerColor.withAlpha((255 * 0.5).round()))),
              ),
              // List styles
              listIndent: 24.0,
              listBullet: baseStyle,
              listBulletPadding: const EdgeInsets.only(right: 8.0),
              // Table styles (if needed later)
              // tableHead: baseStyle.copyWith(fontWeight: FontWeight.bold),
              // tableBody: baseStyle,
              // tableBorder: TableBorder.all(color: theme.dividerColor, width: 1.0),
              // tableColumnWidth: const IntrinsicColumnWidth(),
              // tableCellsPadding: const EdgeInsets.all(8.0),
              // tableCellsDecoration: BoxDecoration(),
            );

            // Wrap the content in a SingleChildScrollView to prevent overflow
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  // Ensure Column doesn't try to expand infinitely vertically
                  // when inside a SingleChildScrollView.
                  // We rely on the Expanded TextField to fill the space.
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const Key('note_title_field'),
                      decoration: const InputDecoration(hintText: 'Title'),
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 8),
                    // Need to constrain the height of the Expanded TextField
                    // inside a SingleChildScrollView.
                    // Let's give it a reasonable initial height, but it can grow.
                    SizedBox(
                      // Adjust height as needed, or use MediaQuery
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: _isPreviewMode
                          ? Builder(builder: (context) { // Use Builder to get context for print
                              // Process text line by line to remove leading whitespace
                              final rawText = _bodyController.text;
                              final lines = rawText.split('\n');
                              final trimmedLines = lines.map((line) => line.trimLeft());
                              final textToRender = trimmedLines.join('\n');
                              
                              // --- REMOVED DIAGNOSTIC PRINT ---
                              // print("--- Rendering Markdown (Lines Trimmed) ---");
                              // print(textToRender); 
                              // print("--- End Markdown Text ---");
                              // --- END DIAGNOSTIC PRINT ---
                              
                              return MarkdownBody( // Show Markdown Preview
                                data: textToRender,
                                selectable: true, // Allow text selection in preview
                                // RE-ENABLE custom stylesheet
                                styleSheet: markdownStyleSheet, 
                              );
                            })
                          : TextField( // Show Text Editor
                              key: const Key('note_body_field'),
                              decoration: const InputDecoration(
                                hintText: 'Note content (Markdown supported)...',
                                border: InputBorder.none,
                              ),
                              maxLines: null,
                              expands: true,
                              controller: _bodyController,
                              textCapitalization: TextCapitalization.sentences,
                              textAlignVertical: TextAlignVertical.top,
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      // ),
    );
  }
} 