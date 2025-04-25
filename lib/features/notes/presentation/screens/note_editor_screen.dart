import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  // TODO: Add TextEditingControllers for title and body
  // TODO: Load existing note data if widget.noteId is not null
  // TODO: Implement save/delete logic

  @override
  void initState() {
    super.initState();
    // TODO: Initialize controllers and load data
  }

  @override
  void dispose() {
    // TODO: Dispose controllers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNewNote = widget.noteId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewNote ? 'New Note' : 'Edit Note'),
        actions: [
          // TODO: Add Save button
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: 'Save Note',
            onPressed: () {
              // TODO: Implement save logic
            },
          ),
          // TODO: Add Delete button only when editing
          if (!isNewNote)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Note',
              onPressed: () {
                // TODO: Implement delete logic
              },
            ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // TODO: Add TextField for title
            TextField(
              decoration: InputDecoration(hintText: 'Title'),
              // controller: _titleController,
            ),
            SizedBox(height: 8),
            // TODO: Add Expanded TextField for body
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Note content...',
                  border: InputBorder.none, // Remove underline
                ),
                maxLines: null, // Allow multiple lines
                expands: true, // Fill available space
                // controller: _bodyController,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 