import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart'; // Import animations package

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
            // Use pageBuilder for custom transitions
            pageBuilder: (BuildContext context, GoRouterState state) {
              final noteIdParam = state.pathParameters['id']!;
              final int? noteId = noteIdParam == 'new' ? null : int.tryParse(noteIdParam);

              return CustomTransitionPage(
                key: state.pageKey,
                child: NoteEditorScreen(noteId: noteId),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  // Use FadeThroughTransition
                  return FadeThroughTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    child: child,
                  );
                },
                // Optional: Adjust transition duration
                // transitionDuration: const Duration(milliseconds: 300),
              );
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