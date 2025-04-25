import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// TODO: Replace with actual screen imports
// import 'package:lockpaper/features/notes/presentation/screens/notes_list_screen.dart';

/// Placeholder widget for the home screen.
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home Screen Placeholder'),
      ),
    );
  }
}

/// Defines the application's routes using GoRouter.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          // TODO: Replace with the actual NotesListScreen
          return const PlaceholderHomeScreen();
        },
        // TODO: Add routes for other screens like NoteEditor
        // routes: <RouteBase>[
        //   GoRoute(
        //     path: 'note/:id',
        //     builder: (BuildContext context, GoRouterState state) {
        //       final noteId = state.pathParameters['id']!;
        //       // return NoteEditorScreen(noteId: noteId);
        //       return PlaceholderScreen(title: 'Edit Note $noteId');
        //     },
        //   ),
        // ],
      ),
    ],
    // TODO: Add error handling/navigation observers if needed
    // errorBuilder: (context, state) => ErrorScreen(state.error),
  );

  // Private constructor to prevent instantiation
  AppRouter._();
} 