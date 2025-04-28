import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lockpaper/main.dart' as app;
import 'package:lockpaper/features/notes/presentation/screens/notes_list_screen.dart'; // Import for routeName
import 'package:lockpaper/features/notes/presentation/screens/note_editor_screen.dart'; // Import for routeName

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('Complete Note CRUD Flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Expect Lock Screen first (assuming it starts locked)
      // print("Step 1: Expecting Lock Screen");
      expect(find.text('Enter PIN'), findsOneWidget);
      // Simulate successful unlock (adjust based on actual LockScreen logic)
      // For now, assume tapping a button/entering correct PIN triggers unlock
      // This needs specific knowledge of the LockScreen implementation
      // Example: await tester.tap(find.byKey(const Key('unlock_button')));
      // For now, we'll manually bypass the lock for the test flow
      // In a real test, you'd interact with the UI or mock the auth service
      // print("Step 1.1: Simulating unlock (bypassing actual UI interaction)");
      await tester.pumpAndSettle(); // Give time for state change
      
      // After unlock, should be on NotesListScreen
      // print("Step 2: Expecting Notes List Screen");
      expect(find.byType(NotesListScreen), findsOneWidget);
      // Check for initial empty state
      expect(find.text('No notes yet. Tap + to add one!'), findsOneWidget);

      // Tap FAB to go to NoteEditorScreen
      // print("Step 3: Tapping FAB to create note");
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Should be on NoteEditorScreen (new note)
      // print("Step 4: Expecting Note Editor Screen (New)");
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'New Note'), findsOneWidget);

      // Enter title and body
      const noteTitle = 'Integration Test Note';
      const noteBody = 'This is the body of the integration test note.';
      // print("Step 5: Entering note title and body");
      await tester.enterText(find.byKey(const Key('note_title_field')), noteTitle);
      await tester.enterText(find.byKey(const Key('note_body_field')), noteBody);
      await tester.pump();

      // Tap save
      // print("Step 6: Saving the new note");
      await tester.tap(find.byIcon(Icons.save_alt_outlined));
      await tester.pumpAndSettle();

      // Should be back on NotesListScreen
      // print("Step 7: Expecting Notes List Screen after save");
      expect(find.byType(NotesListScreen), findsOneWidget);
      // Expect the new note to be displayed
      expect(find.text(noteTitle), findsOneWidget);
      // Check body preview too if necessary
      // expect(find.textContaining(noteBody.substring(0, 10)), findsOneWidget); 

      // Tap the note to edit it
      // print("Step 8: Tapping the note to edit");
      await tester.tap(find.text(noteTitle));
      await tester.pumpAndSettle();

      // Should be on NoteEditorScreen (edit note)
      // print("Step 9: Expecting Note Editor Screen (Edit)");
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Edit Note'), findsOneWidget);
      // Check that existing text is loaded
      expect(find.text(noteTitle), findsOneWidget);
      expect(find.text(noteBody), findsOneWidget);

      // Modify the title and body
      const updatedTitle = 'Updated Test Note';
      const updatedBody = 'The body has been updated.';
      // print("Step 10: Updating note title and body");
      await tester.enterText(find.byKey(const Key('note_title_field')), updatedTitle);
      await tester.enterText(find.byKey(const Key('note_body_field')), updatedBody);
      await tester.pump();

      // Tap save again
      // print("Step 11: Saving the updated note");
      await tester.tap(find.byIcon(Icons.save_alt_outlined));
      await tester.pumpAndSettle();

      // Should be back on NotesListScreen
      // print("Step 12: Expecting Notes List Screen after update");
      expect(find.byType(NotesListScreen), findsOneWidget);
      // Expect the updated note to be displayed
      expect(find.text(updatedTitle), findsOneWidget);
      expect(find.text(noteTitle), findsNothing); // Old title gone
      // Check updated body preview if necessary
      // expect(find.textContaining(updatedBody.substring(0, 10)), findsOneWidget);

      // Tap the updated note to go back to the editor for deletion
      // print("Step 13: Tapping the updated note for deletion");
      await tester.tap(find.text(updatedTitle));
      await tester.pumpAndSettle();

      // Should be on NoteEditorScreen (edit note) again
      // print("Step 14: Expecting Note Editor Screen for delete action");
      expect(find.byType(NoteEditorScreen), findsOneWidget);

      // Tap the delete icon
      // print("Step 15: Tapping delete icon");
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle(); // Wait for dialog

      // Confirm deletion in the dialog
      // print("Step 16: Confirming deletion in dialog");
      expect(find.text('Delete Note?'), findsOneWidget); // Check dialog title
      await tester.tap(find.text('Delete')); // Tap the confirm button
      await tester.pumpAndSettle();

      // Should be back on NotesListScreen
      // print("Step 17: Expecting Notes List Screen after deletion");
      expect(find.byType(NotesListScreen), findsOneWidget);
      // Expect the empty state message again
      expect(find.text('No notes yet. Tap + to add one!'), findsOneWidget);
      expect(find.text(updatedTitle), findsNothing);
    });
  });
} 