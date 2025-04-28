import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lockpaper/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Test', () {
    testWidgets('Full Unlock, CRUD, and Lock flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // --- Step 1: Unlock the app ---
      print('Integration Test: Finding unlock button...');
      // Find by icon instead
      final unlockButtonFinder = find.byIcon(Icons.fingerprint);
      // // Find by text first, then find the ancestor button
      // final buttonTextFinder = find.text('Authenticate with biometrics');
      // final unlockButtonFinder = find.ancestor(
      //   of: buttonTextFinder,
      //   matching: find.byType(ElevatedButton)
      // );
      // // final unlockButtonFinder = find.widgetWithText(ElevatedButton, 'Authenticate with biometrics'); // Original problematic finder
      expect(unlockButtonFinder, findsOneWidget, reason: 'Expected to find the unlock button icon');
      print('Integration Test: Tapping unlock button...');
      await tester.tap(unlockButtonFinder);
      print('Integration Test: Waiting for unlock and navigation...');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      // Add an extra delay for safety
      await Future.delayed(const Duration(milliseconds: 500));

      // --- Step 2: Verify NotesListScreen is shown ---
      print('Integration Test: Verifying NotesListScreen...');
      final fabFinder = find.byTooltip('Create Note');
      expect(fabFinder, findsOneWidget, reason: 'Expected to find FAB on NotesListScreen');

      // --- Step 3: Tap FAB to go to NoteEditorScreen ---
      print('Integration Test: Tapping FAB...');
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // --- Step 4: Enter title and body ---
      print('Integration Test: Entering text...');
      final titleFieldFinder = find.byKey(const Key('note_title_field'));
      final bodyFieldFinder = find.byKey(const Key('note_body_field'));
      expect(titleFieldFinder, findsOneWidget, reason: 'Expected to find title field');
      expect(bodyFieldFinder, findsOneWidget, reason: 'Expected to find body field');

      const noteTitle = 'Integration Test Note Title';
      const noteBody = 'This is the body of the note created during the integration test.';
      await tester.enterText(titleFieldFinder, noteTitle);
      await tester.enterText(bodyFieldFinder, noteBody);
      await tester.pump();

      // --- Step 5: Tap Save ---
      print('Integration Test: Tapping save...');
      final saveButtonFinder = find.byIcon(Icons.save_alt_outlined);
      expect(saveButtonFinder, findsOneWidget, reason: 'Expected to find save button');
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      // --- Step 6: Verify back on NotesListScreen and new note is present ---
      print('Integration Test: Verifying back on list screen with new note...');
      expect(fabFinder, findsOneWidget, reason: 'Expected to find FAB after saving');
      final newNoteFinder = find.descendant(
        of: find.byType(ListTile),
        matching: find.text(noteTitle)
      );
      expect(newNoteFinder, findsOneWidget, reason: 'Expected to find new note title in a ListTile');

      // --- Step 7: Tap the new note to go back to editor ---
      print('Integration Test: Tapping the new note...');
      final listTileFinder = find.ancestor(
        of: newNoteFinder,
        matching: find.byType(ListTile)
      );
      expect(listTileFinder, findsOneWidget, reason: 'Failed to find ancestor ListTile for the new note');
      await tester.tap(listTileFinder);
      await tester.pumpAndSettle();

      // --- Step 8: Edit the note title/body ---
      print('Integration Test: Editing the note...');
      expect(titleFieldFinder, findsOneWidget, reason: 'Expected title field to be present for editing');
      expect(bodyFieldFinder, findsOneWidget, reason: 'Expected body field to be present for editing');

      const updatedNoteTitle = 'Integration Test Note Title [Updated]';
      const updatedNoteBody = 'The body was updated during the integration test.';
      await tester.enterText(titleFieldFinder, ''); 
      await tester.enterText(titleFieldFinder, updatedNoteTitle);
      await tester.enterText(bodyFieldFinder, ''); 
      await tester.enterText(bodyFieldFinder, updatedNoteBody);
      await tester.pump();

      // --- Step 9: Tap Save ---
      print('Integration Test: Tapping save after edit...');
      expect(saveButtonFinder, findsOneWidget, reason: 'Expected to find save button after edit');
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      // --- Step 10: Verify back on NotesListScreen and updated note is present ---
      print('Integration Test: Verifying back on list screen with updated note...');
      expect(fabFinder, findsOneWidget, reason: 'Expected FAB to be present after second save');
      final updatedNoteFinder = find.descendant(
        of: find.byType(ListTile),
        matching: find.text(updatedNoteTitle)
      );
      expect(updatedNoteFinder, findsOneWidget, reason: 'Expected to find updated note title in a ListTile');

      // --- Step 11: Tap the updated note ---
      print('Integration Test: Tapping the updated note...');
      final updatedListTileFinder = find.ancestor(
        of: updatedNoteFinder,
        matching: find.byType(ListTile)
      );
      expect(updatedListTileFinder, findsOneWidget, reason: 'Failed to find ancestor ListTile for the updated note');
      await tester.tap(updatedListTileFinder);
      await tester.pumpAndSettle(); // Wait for navigation

      // --- Step 12: Tap Delete icon ---
      print('Integration Test: Tapping delete icon...');
      final deleteIconFinder = find.byIcon(Icons.delete_outline);
      expect(deleteIconFinder, findsOneWidget, reason: 'Expected to find delete icon');
      await tester.tap(deleteIconFinder);
      await tester.pumpAndSettle(); // Wait for dialog

      // --- Step 13: Tap Delete in confirmation dialog ---
      print('Integration Test: Confirming delete...');
      final confirmDeleteButtonFinder = find.widgetWithText(TextButton, 'Delete');
      expect(confirmDeleteButtonFinder, findsOneWidget, reason: 'Expected to find Delete button in dialog');
      await tester.tap(confirmDeleteButtonFinder);
      await tester.pumpAndSettle(); // Wait for delete and navigation

      // --- Step 14: Verify back on NotesListScreen and note is gone ---
      print('Integration Test: Verifying note deletion...');
      expect(fabFinder, findsOneWidget, reason: 'Expected FAB to be present after delete');
      // Verify the updated note title is NO LONGER found
      expect(find.text(updatedNoteTitle), findsNothing, reason: 'Expected updated note title to be gone after deletion');

      // TODO: Implement remaining steps:
      // 15. (Optional) Simulate app going to background and resuming to test lock
    });
  });
} 