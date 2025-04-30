import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart'; // Import animations package
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

// Import screens and providers
import 'package:lockpaper/features/notes/presentation/screens/notes_list_screen.dart';
import 'package:lockpaper/features/notes/presentation/screens/note_editor_screen.dart'; // Import editor
import 'package:lockpaper/core/presentation/screens/pin_setup/confirm_pin_screen.dart';
import 'package:lockpaper/core/presentation/screens/pin_setup/create_pin_screen.dart';
import 'package:lockpaper/core/presentation/screens/lock_screen.dart'; // Import LockScreen
import 'package:lockpaper/core/application/app_lock_provider.dart'; // Import lock provider
import 'package:lockpaper/core/presentation/screens/pin_change/enter_current_pin_screen.dart';
import 'package:lockpaper/core/presentation/screens/pin_change/enter_new_pin_screen.dart';
import 'package:lockpaper/core/presentation/screens/pin_change/confirm_new_pin_screen.dart';
import 'package:lockpaper/features/settings/presentation/screens/settings_screen.dart'; // Import SettingsScreen

/// Defines the application's routes using GoRouter.
class AppRouter {
  // Make router accept Ref
  static GoRouter getRouter(WidgetRef ref) {
    // Define route names centrally (optional but good practice)
    const lockRoute = '/lock';
    const notesPath = '/'; // Use path consistently for logic
    const notesRouteName = NotesListScreen.routeName; // Use const
    const createPinRoute = CreatePinScreen.routeName; // Use const
    const confirmPinRoute = ConfirmPinScreen.routeName; // Use const
    
    // Paths that don't require authentication or are part of the auth flow
    final unauthenticatedPaths = {lockRoute, createPinRoute, confirmPinRoute};

    return GoRouter(
      // Change initialLocation? Can be handled by redirect.
      initialLocation: notesPath, // Use path '/' for initial location
      debugLogDiagnostics: true,
      // refreshListenable: // Could potentially use a listenable based on appLockStateProvider
      redirect: (BuildContext context, GoRouterState state) {
        final isLocked = ref.read(appLockStateProvider);
        final currentLocation = state.matchedLocation; // More reliable than location/subloc

        // If locked and not already on an auth path, redirect to lock screen
        if (isLocked && !unauthenticatedPaths.contains(currentLocation)) {
          return lockRoute;
        }

        // If unlocked and currently on the lock screen, redirect to home path
        if (!isLocked && currentLocation == lockRoute) {
          return notesPath; // Use path '/' for redirect target
        }

        // No redirect needed
        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: notesPath, // Use path '/' 
          name: notesRouteName, // Can keep name 'home' or change to '/' for consistency
          builder: (BuildContext context, GoRouterState state) {
            return const NotesListScreen();
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'note/:id', // Path param: integer ID or 'new'
              name: NoteEditorScreen.routeName,
              pageBuilder: (BuildContext context, GoRouterState state) {
                final noteIdParam = state.pathParameters['id']!;
                final int? noteId = noteIdParam == 'new' ? null : int.tryParse(noteIdParam);

                return CustomTransitionPage(
                  key: state.pageKey,
                  child: NoteEditorScreen(noteId: noteId),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeThroughTransition(
                      animation: animation,
                      secondaryAnimation: secondaryAnimation,
                      child: child,
                    );
                  },
                );
              },
            ),
          ],
        ),
        // PIN Setup Routes
        GoRoute(
          path: CreatePinScreen.routeName,
          name: CreatePinScreen.routeName,
          builder: (BuildContext context, GoRouterState state) {
            return const CreatePinScreen();
          },
        ),
        GoRoute(
          path: ConfirmPinScreen.routeName,
          name: ConfirmPinScreen.routeName,
          builder: (BuildContext context, GoRouterState state) {
            final initialPin = state.extra as String?;
            if (initialPin == null) {
              print('Error: ConfirmPinScreen called without initialPin argument. Navigating back.');
              // Use context.pop() if within the router's context
              WidgetsBinding.instance.addPostFrameCallback((_) { 
                 if (context.canPop()) context.pop(); 
              });
              return const Scaffold(body: Center(child: Text("Error: Missing PIN"))); // Show temp error
            }
            return ConfirmPinScreen(initialPin: initialPin);
          },
        ),
        // Lock Screen Route
        GoRoute(
           path: lockRoute,
           name: lockRoute, // Use the constant
           builder: (BuildContext context, GoRouterState state) {
              // This context *is* within the GoRouter tree
              return LockScreen(
                onUnlocked: () {
                  // Read notifier to change state
                   ref.read(appLockStateProvider.notifier).state = false;
                   // Navigate home using path '/' after unlocking
                   context.go(notesPath);
                },
              );
           },
        ),
        // Add Change PIN routes
        GoRoute(
          name: EnterCurrentPinScreen.routeName,
          path: EnterCurrentPinScreen.routeName,
          builder: (context, state) => const EnterCurrentPinScreen(),
        ),
        GoRoute(
          name: EnterNewPinScreen.routeName,
          path: EnterNewPinScreen.routeName,
          builder: (context, state) => const EnterNewPinScreen(),
        ),
        GoRoute(
          name: ConfirmNewPinScreen.routeName,
          path: ConfirmNewPinScreen.routeName,
          builder: (context, state) {
            final newPin = state.extra as String?;
            // TODO: Add error handling if newPin is null?
            return ConfirmNewPinScreen(newPinToConfirm: newPin ?? '');
          },
        ),
        // Settings Route
        GoRoute(
          path: SettingsScreen.routeName, 
          name: SettingsScreen.routeName,
          builder: (BuildContext context, GoRouterState state) {
            return const SettingsScreen();
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold( // Basic error screen
         body: Center(child: Text('Route Error: ${state.error}')),
       ),
    );
  }

  // Private constructor remains
  AppRouter._();
}

// Remove the generic PlaceholderScreen as it's no longer needed by active routes
// class PlaceholderScreen extends StatelessWidget { ... } 