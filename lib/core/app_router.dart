import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import the actual screen
import 'package:lockpaper/features/notes/presentation/screens/notes_list_screen.dart';

/// Defines the application's routes using GoRouter.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true, // Enable GoRouter logging for debugging
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'home', // Give the route a name
        builder: (BuildContext context, GoRouterState state) {
          // Use the actual NotesListScreen
          return const NotesListScreen();
        },
        // TODO: Add routes for other screens like NoteEditor
        // routes: <RouteBase>[
        //   GoRoute(
        //     path: 'note/:id', // Path parameter for note ID
        //     name: 'noteEditor',
        //     builder: (BuildContext context, GoRouterState state) {
        //       final noteId = state.pathParameters['id']!;
        //       // Determine if creating a new note or editing existing
        //       final isNewNote = noteId == 'new';
        //       // return NoteEditorScreen(noteId: isNewNote ? null : int.parse(noteId));
        //       return PlaceholderScreen(title: isNewNote ? 'New Note' : 'Edit Note $noteId'); // Placeholder
        //     },
        //   ),
        // ],
      ),
      // TODO: Add routes for settings, lock screen, etc.
    ],
    // TODO: Add error handling/navigation observers if needed
    // errorBuilder: (context, state) => ErrorScreen(state.error),
  );

  // Private constructor to prevent instantiation
  AppRouter._();
}

// Placeholder for screens not yet created (can be removed later)
// Used in commented-out routes above
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title Placeholder')),
    );
  }
} 