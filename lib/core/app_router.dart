import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import screens
import 'package:lockpaper/features/notes/presentation/screens/notes_list_screen.dart';
import 'package:lockpaper/features/notes/presentation/screens/note_editor_screen.dart'; // Import editor

/// Defines the application's routes using GoRouter.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true, // Enable GoRouter logging for debugging
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: NotesListScreen.routeName, // Use name from screen
        builder: (BuildContext context, GoRouterState state) {
          return const NotesListScreen();
        },
        // Nested route for the editor
        routes: <RouteBase>[
          GoRoute(
            path: 'note/:id', // Path param: integer ID or 'new'
            name: NoteEditorScreen.routeName,
            builder: (BuildContext context, GoRouterState state) {
              final noteIdParam = state.pathParameters['id']!;
              // Pass the note ID (as int?) or null if 'new'
              final int? noteId = noteIdParam == 'new' ? null : int.tryParse(noteIdParam);
              // TODO: Add error handling if ID is not 'new' and not a valid int
              return NoteEditorScreen(noteId: noteId);
            },
          ),
        ],
      ),
      // TODO: Add routes for settings, lock screen, etc.
    ],
    // TODO: Add error handling/navigation observers if needed
    // errorBuilder: (context, state) => ErrorScreen(state.error),
  );

  // Private constructor to prevent instantiation
  AppRouter._();
}

// Remove the generic PlaceholderScreen as it's no longer needed by active routes
// class PlaceholderScreen extends StatelessWidget { ... } 