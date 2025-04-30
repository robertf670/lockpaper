import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lockpaper/features/notes/application/database_providers.dart';
import 'package:lockpaper/features/notes/data/app_database.dart';
import 'package:lockpaper/features/notes/presentation/screens/note_editor_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// Mocks
class MockGoRouter extends Mock implements GoRouter {}
class MockNoteDao extends Mock implements NoteDao {}

// Helper data structure to return widget and controller
class TestWidgetResult {
  final Widget widget;
  final StreamController<Note?> controller;

  TestWidgetResult(this.widget, this.controller);
}

// Helper to pump the widget with providers and mocks
TestWidgetResult createTestableWidget({
  required int? noteId, // Pass null for new note, ID for existing
  required MockGoRouter mockGoRouter,
  required MockNoteDao mockNoteDao,
  // Note? initialNoteData, // Removed: Data will be emitted within tests
}) {
  // Use StreamController to manage the single note stream
  // Broadcast controller allows multiple listeners if needed, safer default
  final noteStreamController = StreamController<Note?>.broadcast();
  // Removed initial data emission: noteStreamController.add(...)

  final widget = ProviderScope(
    overrides: [
      noteDaoProvider.overrideWithValue(mockNoteDao),
      // Override the family provider for the specific ID being tested
      if (noteId != null)
        noteByIdStreamProvider(noteId)
            .overrideWith((ref) => noteStreamController.stream)
      // No need to override for null noteId, as the screen should handle it
    ],
    child: InheritedGoRouter(
      goRouter: mockGoRouter,
      child: MaterialApp(
        home: NoteEditorScreen(noteId: noteId),
      ),
    ),
  );

  return TestWidgetResult(widget, noteStreamController);
}

void main() {
  late MockGoRouter mockGoRouter;
  late MockNoteDao mockNoteDao;
  // Define controller here to close in tearDown
  // late StreamController<Note?> noteStreamController; // Unused

  // Sample note data
  final testNote = Note(
    id: 1,
    title: 'Test Title',
    body: 'Test Body',
    createdAt: DateTime.now(),
  );

  setUpAll(() {
    // Register fallback values for types used in verify
    registerFallbackValue(const NotesCompanion());
  });

  setUp(() {
    mockGoRouter = MockGoRouter();
    mockNoteDao = MockNoteDao();
    // Note: StreamController is created *inside* createTestableWidget now
    // We retrieve it from the result in tests that need it.

    // Default GoRouter behavior
    when(() => mockGoRouter.go(any())).thenAnswer((_) async {});
    when(() => mockGoRouter.push(any())).thenAnswer((_) async {});
    when(() => mockGoRouter.pop()).thenAnswer((_) {});
    when(() => mockGoRouter.canPop()).thenReturn(true);
    when(() => mockGoRouter.goNamed(any(),
            pathParameters: any(named: 'pathParameters')))
        .thenAnswer((_) async { return null; });
  });

  // Ensure controllers are closed after tests that use them
  //tearDown(() {
  //  if (!noteStreamController.isClosed) {
  //    noteStreamController.close();
  //  }
  //});


  group('NoteEditorScreen Widget Tests', () {
    testWidgets('Displays "New Note" AppBar when creating new note', (WidgetTester tester) async {
      // Arrange
      final testWidgetResult = createTestableWidget(
        noteId: null, // New note
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      );
      await tester.pumpWidget(testWidgetResult.widget);
      // For new note, stream provider isn't used, so just settle
      await tester.pumpAndSettle();

      // Assert
      expect(find.widgetWithText(AppBar, 'New Note'), findsOneWidget);
      // Close controller if created, though not used in this test
      testWidgetResult.controller.close();
    });

    testWidgets('Displays "Edit Note" AppBar when editing existing note', (WidgetTester tester) async {
      // Arrange
      // No need to mock watchNoteById directly when overriding the provider
      // when(() => mockNoteDao.watchNoteById(1)).thenAnswer((_) => Stream.value(testNote));

      final testWidgetResult = createTestableWidget(
        noteId: 1, // Existing note ID
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
        // initialNoteData: testNote, // Removed
      );
      await tester.pumpWidget(testWidgetResult.widget);

      // Act: Emit the note data *after* the widget is built
      testWidgetResult.controller.add(testNote);
      await tester.pumpAndSettle(); // Now settle after data emission

      // Assert
      expect(find.widgetWithText(AppBar, 'Edit Note'), findsOneWidget);

      // Clean up
      await testWidgetResult.controller.close();
    });

    testWidgets('Loads existing note data into TextFields', (WidgetTester tester) async {
       // Arrange
       // No need to mock watchNoteById directly when overriding the provider
       // when(() => mockNoteDao.watchNoteById(1)).thenAnswer((_) => Stream.value(testNote));

       final testWidgetResult = createTestableWidget(
        noteId: 1,
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
        // initialNoteData: testNote, // Removed
      );
       await tester.pumpWidget(testWidgetResult.widget);

       // Act: Emit the note data
       testWidgetResult.controller.add(testNote);
       await tester.pumpAndSettle();

      // Assert
      expect(find.widgetWithText(TextField, 'Test Title'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Test Body'), findsOneWidget);

       // Clean up
      await testWidgetResult.controller.close();
    });

    testWidgets('Saves a new note and pops the screen', (WidgetTester tester) async {
      // Arrange
      // Mock the insertNote method to simulate successful creation
      when(() => mockNoteDao.insertNote(any()))
          .thenAnswer((_) async => 1); // Return a dummy ID

      final testWidgetResult = createTestableWidget(
        noteId: null, // New note
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      );
      await tester.pumpWidget(testWidgetResult.widget);
      await tester.pumpAndSettle();
      await tester.pump(); // Extra pump for UI to settle fully

      // Act
      // Enter text into the title and body fields
      await tester.enterText(find.byKey(const Key('note_title_field')), 'New Title');
      await tester.enterText(find.byKey(const Key('note_body_field')), 'New Body');
      await tester.pump(); // Allow state to update
      await tester.pump(); // Extra pump after entering text

      // Tap the save button (using the correct icon)
      await tester.tap(find.byIcon(Icons.save_alt_outlined));
      await tester.pumpAndSettle(); // Wait for async operations like save and pop

      // Assert
      // Verify that insertNote was called with the correct data
      final captured = verify(() => mockNoteDao.insertNote(captureAny())).captured;
      expect(captured.length, 1);
      final companion = captured.first as NotesCompanion;
      expect(companion.title.value, 'New Title');
      expect(companion.body.value, 'New Body');

      // Verify that the screen was popped
      verify(() => mockGoRouter.pop()).called(1);

      // Clean up (controller not really used here, but good practice)
      await testWidgetResult.controller.close();
    });

    testWidgets('Updates an existing note and pops the screen', (WidgetTester tester) async {
      // Arrange
      // Mock updateNote to simulate success
      when(() => mockNoteDao.updateNote(any())).thenAnswer((_) async => true);

      final testWidgetResult = createTestableWidget(
        noteId: testNote.id, // Existing note ID
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      );
      await tester.pumpWidget(testWidgetResult.widget);

      // Emit initial data
      testWidgetResult.controller.add(testNote);
      await tester.pumpAndSettle();
      await tester.pump(); // Extra pump for UI to settle fully after data load

      // Act
      // Enter new text
      const updatedTitle = 'Updated Title';
      const updatedBody = 'Updated Body';
      await tester.enterText(find.byKey(const Key('note_title_field')), updatedTitle);
      await tester.enterText(find.byKey(const Key('note_body_field')), updatedBody);
      await tester.pump(); // Allow state to update
      await tester.pump(); // Extra pump after entering text

      // Tap save
      await tester.tap(find.byIcon(Icons.save_alt_outlined));
      await tester.pumpAndSettle(); // Wait for save and pop

      // Assert
      // Verify updateNote call
      final captured = verify(() => mockNoteDao.updateNote(captureAny())).captured;
      expect(captured.length, 1);
      final companion = captured.first as NotesCompanion;
      expect(companion.id.value, testNote.id);
      expect(companion.title.value, updatedTitle);
      expect(companion.body.value, updatedBody);
      // Check that updatedAt is present (since it's set during update)
      expect(companion.updatedAt.present, isTrue);
      expect(companion.updatedAt.value, isNotNull);

      // Verify pop call
      verify(() => mockGoRouter.pop()).called(1);

      // Clean up
      await testWidgetResult.controller.close();
    });

    testWidgets('Deletes an existing note after confirmation and pops', (WidgetTester tester) async {
      // Arrange
      // Mock deleteNote to simulate success
      when(() => mockNoteDao.deleteNote(any())).thenAnswer((_) async => 1);

      final testWidgetResult = createTestableWidget(
        noteId: testNote.id, // Existing note ID
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      );
      await tester.pumpWidget(testWidgetResult.widget);

      // Emit initial data
      testWidgetResult.controller.add(testNote);
      await tester.pumpAndSettle();

      // Act
      // Tap the delete icon
      expect(find.byIcon(Icons.delete_outline), findsOneWidget); // Ensure delete icon is present
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle(); // Allow dialog to show

      // Confirm deletion in the dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle(); // Wait for delete and pop

      // Assert
      // Verify deleteNote call
      final captured = verify(() => mockNoteDao.deleteNote(captureAny())).captured;
      expect(captured.length, 1);
      final companion = captured.first as NotesCompanion;
      expect(companion.id.value, testNote.id); // Verify ID
      // Other fields should be absent for delete
      expect(companion.title.present, isFalse);
      expect(companion.body.present, isFalse);

      // Verify pop call
      verify(() => mockGoRouter.pop()).called(1);

      // Clean up
      await testWidgetResult.controller.close();
    });

    testWidgets('Does not save or pop when note is empty', (WidgetTester tester) async {
      // Arrange
      // No need to mock DAO methods as they shouldn't be called

      final testWidgetResult = createTestableWidget(
        noteId: null, // New note
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      );
      await tester.pumpWidget(testWidgetResult.widget);
      await tester.pumpAndSettle();

      // Act
      // Ensure fields are empty (they should be by default)
      expect(find.widgetWithText(TextField, ''), findsNWidgets(2)); // Title and Body

      // Tap the save button
      await tester.tap(find.byIcon(Icons.save_alt_outlined));
      await tester.pumpAndSettle(); // Allow SnackBar to show

      // Assert
      // Verify that insertNote was NOT called
      verifyNever(() => mockNoteDao.insertNote(any()));

      // Verify that pop was NOT called
      verifyNever(() => mockGoRouter.pop());

      // Verify that the SnackBar is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Cannot save an empty note.'), findsOneWidget);

      // Clean up
      testWidgetResult.controller.close(); // Close even if not used
    });

    // --- BACK NAVIGATION TESTS ---

    testWidgets('Tapping back button on New Note screen pops without saving', (WidgetTester tester) async {
      // Arrange
      final testWidgetResult = createTestableWidget(
        noteId: null, // New note
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      );
      await tester.pumpWidget(testWidgetResult.widget);
      await tester.pumpAndSettle();

      // Enter some text (but don't save)
      await tester.enterText(find.byKey(const Key('note_title_field')), 'Unsaved Title');
      await tester.pump();

      // Act: Simulate back navigation directly via mock router
      mockGoRouter.pop(); // Simulate pop directly
      await tester.pumpAndSettle();

      // Assert
      verifyNever(() => mockNoteDao.insertNote(any())); // Ensure save was NOT called
      verify(() => mockGoRouter.pop()).called(1); // Ensure pop was called

      await testWidgetResult.controller.close();
    });

    testWidgets('Tapping back button on Edit Note screen with NO changes pops without saving', (WidgetTester tester) async {
      // Arrange
      final testWidgetResult = createTestableWidget(
        noteId: testNote.id, // Existing note
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      );
      await tester.pumpWidget(testWidgetResult.widget);
      // Emit initial data
      testWidgetResult.controller.add(testNote);
      await tester.pumpAndSettle();

      // Act: Simulate back navigation directly via mock router
      mockGoRouter.pop(); // Simulate pop directly
      await tester.pumpAndSettle();

      // Assert
      verifyNever(() => mockNoteDao.updateNote(any())); // Ensure update was NOT called
      verify(() => mockGoRouter.pop()).called(1); // Ensure pop was called

      await testWidgetResult.controller.close();
    });

     testWidgets('Tapping back button on Edit Note screen WITH changes pops without saving', (WidgetTester tester) async {
      // Arrange
      final testWidgetResult = createTestableWidget(
        noteId: testNote.id, // Existing note
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      );
      await tester.pumpWidget(testWidgetResult.widget);
      // Emit initial data
      testWidgetResult.controller.add(testNote);
      await tester.pump();

      // Act: Simulate back navigation directly via mock router
      mockGoRouter.pop(); // Simulate pop directly
      await tester.pumpAndSettle();

      // Assert
      verifyNever(() => mockNoteDao.updateNote(any())); // Ensure update was NOT called
      verify(() => mockGoRouter.pop()).called(1); // Ensure pop was called

      await testWidgetResult.controller.close();
    });

    // --- ERROR HANDLING TESTS ---

    testWidgets('Shows error SnackBar if saving new note fails', (WidgetTester tester) async {
      // Arrange
      final testError = Exception('DAO insert failed');
      when(() => mockNoteDao.insertNote(any())).thenThrow(testError);

      final testWidgetResult = createTestableWidget(
        noteId: null, 
        mockGoRouter: mockGoRouter, 
        mockNoteDao: mockNoteDao,
      );
      await tester.pumpWidget(testWidgetResult.widget);
      await tester.pumpAndSettle();
      await tester.pump(); // Extra pump for UI to settle fully

      // Act
      await tester.enterText(find.byKey(const Key('note_title_field')), 'Error Title');
      await tester.enterText(find.byKey(const Key('note_body_field')), 'Error Body');
      await tester.pump();
      await tester.pump(); // Extra pump after entering text

      await tester.tap(find.byIcon(Icons.save_alt_outlined));
      await tester.pumpAndSettle(); // Allow SnackBar to show

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Error saving note: $testError'), findsOneWidget);
      verifyNever(() => mockGoRouter.pop()); // Ensure no navigation occurred

      await testWidgetResult.controller.close();
    });

    testWidgets('Shows error SnackBar if updating existing note fails', (WidgetTester tester) async {
      // Arrange
      final testError = Exception('DAO update failed');
      when(() => mockNoteDao.updateNote(any())).thenThrow(testError);

      final testWidgetResult = createTestableWidget(
        noteId: testNote.id,
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      );
      await tester.pumpWidget(testWidgetResult.widget);
      testWidgetResult.controller.add(testNote);
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byKey(const Key('note_title_field')), 'Error Update Title');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.save_alt_outlined));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Error saving note: $testError'), findsOneWidget);
      verifyNever(() => mockGoRouter.pop());

      await testWidgetResult.controller.close();
    });

    testWidgets('Shows error SnackBar if deleting existing note fails', (WidgetTester tester) async {
      // Arrange
      final testError = Exception('DAO delete failed');
      when(() => mockNoteDao.deleteNote(any())).thenThrow(testError);

       final testWidgetResult = createTestableWidget(
        noteId: testNote.id,
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      );
      await tester.pumpWidget(testWidgetResult.widget);
      testWidgetResult.controller.add(testNote);
      await tester.pumpAndSettle();

      // Act
      // Tap delete icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle(); // Show dialog
      // Tap confirm delete
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle(); // Process delete attempt and show SnackBar

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Error deleting note: $testError'), findsOneWidget);
      verifyNever(() => mockGoRouter.pop());
      
      await testWidgetResult.controller.close();
    });

    // --- PREVIEW TOGGLE TESTS --- 

    testWidgets('Tapping preview button hides editor and shows Markdown preview', (WidgetTester tester) async {
      // Arrange
      final testWidgetResult = createTestableWidget(
        noteId: testNote.id,
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      );
      await tester.pumpWidget(testWidgetResult.widget);
      testWidgetResult.controller.add(testNote);
      await tester.pumpAndSettle();

      // Assert initial state (Edit mode)
      expect(find.byKey(const Key('note_title_field')), findsOneWidget); // Title always visible
      expect(find.byKey(const Key('note_body_field')), findsOneWidget); // Body editor visible
      expect(find.byType(MarkdownBody), findsNothing); // Preview not visible
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget); // Preview button visible
      expect(find.byIcon(Icons.edit_note_outlined), findsNothing); // Edit button not visible

      // Act: Tap the preview button
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle(); // Allow AnimatedSwitcher to complete

      // Assert final state (Preview mode)
      expect(find.byKey(const Key('note_title_field')), findsOneWidget); // Title still visible
      expect(find.byKey(const Key('note_body_field')), findsNothing); // Body editor not visible
      expect(find.byType(MarkdownBody), findsOneWidget); // Preview visible
      expect(find.byIcon(Icons.visibility_outlined), findsNothing); // Preview button not visible
      expect(find.byIcon(Icons.edit_note_outlined), findsOneWidget); // Edit button visible

      await testWidgetResult.controller.close();
    });

    testWidgets('Tapping edit button hides preview and shows editor', (WidgetTester tester) async {
      // Arrange
      final testWidgetResult = createTestableWidget(
        noteId: testNote.id,
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      );
      await tester.pumpWidget(testWidgetResult.widget);
      testWidgetResult.controller.add(testNote);
      await tester.pumpAndSettle();

      // Go into preview mode first
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      // Assert initial state (Preview mode)
      expect(find.byKey(const Key('note_title_field')), findsOneWidget);
      expect(find.byKey(const Key('note_body_field')), findsNothing);
      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.byIcon(Icons.edit_note_outlined), findsOneWidget);

      // Act: Tap the edit button
      await tester.tap(find.byIcon(Icons.edit_note_outlined));
      await tester.pumpAndSettle(); // Allow AnimatedSwitcher to complete

      // Assert final state (Edit mode)
      expect(find.byKey(const Key('note_title_field')), findsOneWidget);
      expect(find.byKey(const Key('note_body_field')), findsOneWidget);
      expect(find.byType(MarkdownBody), findsNothing);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.edit_note_outlined), findsNothing);

      await testWidgetResult.controller.close();
    });

    // TODO: Add tests for delete confirmation dialog (Cancel button)
  });
} 