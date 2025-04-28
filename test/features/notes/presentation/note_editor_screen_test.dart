import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lockpaper/features/notes/application/database_providers.dart';
import 'package:lockpaper/features/notes/data/app_database.dart';
import 'package:lockpaper/features/notes/presentation/screens/note_editor_screen.dart';
import 'package:mocktail/mocktail.dart';

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
  late StreamController<Note?> noteStreamController;

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
    when(() => mockGoRouter.pop()).thenAnswer((_) async {});
    when(() => mockGoRouter.canPop()).thenReturn(true);
    when(() => mockGoRouter.goNamed(any(),
            pathParameters: any(named: 'pathParameters')))
        .thenAnswer((_) async {});
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

      // Act
      // Enter text into the title and body fields
      await tester.enterText(find.byKey(const Key('note_title_field')), 'New Title');
      await tester.enterText(find.byKey(const Key('note_body_field')), 'New Body');
      await tester.pump(); // Allow state to update

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

      // Act
      // Enter new text
      const updatedTitle = 'Updated Title';
      const updatedBody = 'Updated Body';
      await tester.enterText(find.byKey(const Key('note_title_field')), updatedTitle);
      await tester.enterText(find.byKey(const Key('note_body_field')), updatedBody);
      await tester.pump(); // Allow state to update

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

    // TODO: Test deleting existing note (including dialog)
    // TODO: Test preventing saving empty note
  });
} 