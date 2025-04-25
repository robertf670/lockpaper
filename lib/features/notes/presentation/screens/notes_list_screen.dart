import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen that displays the list of notes.
class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Fetch and display notes using Riverpod providers

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lockpaper'),
        // TODO: Add actions like settings, search?
      ),
      body: const Center(
        // TODO: Replace with ListView/GridView of notes
        child: Text('Notes List Will Appear Here'),
      ),
      floatingActionButton: FloatingActionButton(
        // TODO: Implement navigation to note editor screen
        onPressed: () {
          // GoRouter.of(context).push('/note/new'); // Example navigation
        },
        tooltip: 'Create Note',
        child: const Icon(Icons.add),
      ),
    );
  }
} 