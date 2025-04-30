import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:lockpaper/features/notes/application/database_providers.dart';
// import 'package:lockpaper/features/notes/data/app_database.dart'; // Unused
import 'package:lockpaper/features/notes/presentation/screens/note_editor_screen.dart'; // Import for route name
import 'package:flutter_markdown/flutter_markdown.dart'; // Add this import
import 'package:lockpaper/core/presentation/screens/pin_change/enter_current_pin_screen.dart'; // Import Change PIN start screen

/// Screen that displays the list of notes.
class NotesListScreen extends ConsumerWidget {
  /// Route name for navigation.
  static const String routeName = 'home'; // Added route name

  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the stream provider for notes
    final notesAsyncValue = ref.watch(allNotesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lockpaper'),
        // Add actions like settings, search?
        actions: [
          // Temporary button to trigger Change PIN flow
          IconButton(
            icon: const Icon(Icons.pin_outlined), // Or Icons.key_outlined
            tooltip: 'Change PIN',
            onPressed: () {
              // Navigate to EnterCurrentPinScreen
              context.pushNamed(EnterCurrentPinScreen.routeName); // Use pushNamed
            },
          ),
        ],
      ),
      body: notesAsyncValue.when(
        // Data loaded successfully
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(
              child: Text('No notes yet. Tap + to add one!'),
            );
          }
          // Display notes in a ListView
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              // Add Semantics for better screen reader support
              return Semantics(
                button: true, // Indicate it acts like a button
                label: 'View or edit note: ${note.title.isNotEmpty ? note.title : 'Untitled Note'}', // Describe action and content
                excludeSemantics: true, // Prevent child text being read separately
                child: ListTile(
                  title: Text(note.title.isNotEmpty ? note.title : 'Untitled Note'),
                  // Revert subtitle back to Text widget for stability
                  subtitle: Text(
                    note.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Navigate to editor on tap
                  onTap: () {
                    // Use goNamed for type safety and clarity
                    GoRouter.of(context).goNamed(
                      NoteEditorScreen.routeName,
                      pathParameters: {'id': note.id.toString()}, // Pass note ID as string
                    );
                  },
                  // TODO: Add long-press for delete/multi-select?
                ),
              );
            },
          );
        },
        // Error state
        error: (error, stackTrace) => Center(
          child: Text('Error loading notes: $error'),
        ),
        // Loading state
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      floatingActionButton: Hero(
        tag: 'fab', // Add the Hero tag
        child: FloatingActionButton(
          heroTag: null, // Re-enable this to disable the FAB's default Hero
          onPressed: () {
            GoRouter.of(context).goNamed(
              NoteEditorScreen.routeName,
              pathParameters: {'id': 'new'}, // Pass 'new' for creating
            );
          },
          tooltip: 'Create Note',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
} 