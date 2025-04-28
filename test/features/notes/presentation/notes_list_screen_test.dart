import 'dart:async'; // Import for StreamController
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lockpaper/features/notes/application/database_providers.dart';
import 'package:lockpaper/features/notes/data/app_database.dart';
import 'package:lockpaper/features/notes/presentation/screens/notes_list_screen.dart';
import 'package:lockpaper/features/notes/presentation/screens/note_editor_screen.dart';
import 'package:mocktail/mocktail.dart';

// Mocks - Adjust mock for provider
// class MockNotesList extends AutoDisposeAsyncNotifier<List<Note>> with Mock implements NotesList {} // Remove old mock
class MockGoRouter extends Mock implements GoRouter {}
class MockNoteDao extends Mock implements NoteDao {} // Add mock for NoteDao

// Helper to pump the widget with providers and mocks
Widget createTestableWidget({
  // required MockNotesList mockNotesList, // Remove old mock param
  required StreamController<List<Note>> notesStreamController, // Use controller
  required MockGoRouter mockGoRouter,
  required MockNoteDao mockNoteDao, // Add DAO mock parameter
}) {
  return ProviderScope(
    overrides: [
      // Override with the controller's stream
      allNotesStreamProvider.overrideWith((ref) => notesStreamController.stream),
      noteDaoProvider.overrideWithValue(mockNoteDao), // Override DAO provider
    ],
    child: InheritedGoRouter( 
      goRouter: mockGoRouter,
      child: const MaterialApp(
        home: NotesListScreen(),
      ),
    ),
  );
}

void main() {
  // late MockNotesList mockNotesList; // Remove old mock variable
  late MockGoRouter mockGoRouter;
  late StreamController<List<Note>> notesStreamController;
  late MockNoteDao mockNoteDao; // Add DAO mock variable

  // Sample notes data
  final testNotes = [
    Note(id: 1, title: 'Note 1', body: 'Body 1', createdAt: DateTime.now()),
    Note(id: 2, title: 'Note 2', body: 'Body 2', createdAt: DateTime.now()),
  ];
  final testError = Exception('Failed to load notes');

  setUp(() {
    // mockNotesList = MockNotesList(); // Remove old mock setup
    mockGoRouter = MockGoRouter();
    notesStreamController = StreamController<List<Note>>(); // Create controller
    mockNoteDao = MockNoteDao(); // Initialize DAO mock

    // Setup default GoRouter behavior with explicit Future<void> returns
    when(() => mockGoRouter.go(any())).thenAnswer((_) async => Future<void>.value()); 
    when(() => mockGoRouter.push(any())).thenAnswer((_) async => Future<void>.value()); 
    when(() => mockGoRouter.goNamed(any(), pathParameters: any(named: 'pathParameters')))
        .thenAnswer((_) async => Future<void>.value());

  });

  tearDown(() {
    notesStreamController.close(); // Close the controller after each test
  });

  group('NotesListScreen Widget Tests', () {
    testWidgets('Displays AppBar with correct title', (WidgetTester tester) async {
      // Arrange 
      await tester.pumpWidget(createTestableWidget(
        notesStreamController: notesStreamController,
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      ));
      // Initial state is often loading before stream emits
      await tester.pump(); 
      
      // Emit some data (can be empty) to move past loading state
      notesStreamController.add([]);
      await tester.pumpAndSettle();

      // Assert
      expect(find.widgetWithText(AppBar, 'Lockpaper'), findsOneWidget); 
    });

    testWidgets('Displays loading indicator initially', (WidgetTester tester) async {
      // Arrange 
      await tester.pumpWidget(createTestableWidget(
        notesStreamController: notesStreamController,
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      ));
      // Assert initial loading state *before* emitting data
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(); // Pump once to render the loading indicator
    });

    testWidgets('Displays list of notes when data is emitted', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestableWidget(
        notesStreamController: notesStreamController,
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      ));
      await tester.pump(); // Process initial loading

      // Act: Emit data
      notesStreamController.add(testNotes);
      await tester.pumpAndSettle(); 

      // Assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Note 1'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Note 2'), findsOneWidget);
      expect(find.text('No notes yet! Tap + to add one.'), findsNothing);
    });

    testWidgets('Displays empty state message when empty list is emitted', (WidgetTester tester) async {
      // Arrange
       await tester.pumpWidget(createTestableWidget(
        notesStreamController: notesStreamController,
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      ));
       await tester.pump(); // Process initial loading

      // Act: Emit empty list
      notesStreamController.add([]);
       await tester.pumpAndSettle(); 

      // Assert: Find the specific empty state text directly
      expect(find.text('No notes yet. Tap + to add one!'), findsOneWidget);
    });

    testWidgets('Displays error message when error is emitted', (WidgetTester tester) async {
       // Arrange
       await tester.pumpWidget(createTestableWidget(
        notesStreamController: notesStreamController,
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      ));
       await tester.pump(); // Process initial loading

       // Act: Emit error
       notesStreamController.addError(testError, StackTrace.current);
       await tester.pumpAndSettle();

       // Assert
       expect(find.textContaining('Error loading notes: Exception: Failed to load notes'), findsOneWidget);
       expect(find.byType(ListView), findsNothing);
       expect(find.byType(CircularProgressIndicator), findsNothing);
    });

     testWidgets('FAB exists and navigates to editor on tap', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestableWidget(
        notesStreamController: notesStreamController,
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      ));
       await tester.pump(); // Process initial loading

      // Act: Emit data so FAB is definitely visible
      notesStreamController.add(testNotes);
      await tester.pumpAndSettle();

       // Find the FAB
       final fabFinder = find.byType(FloatingActionButton);
       expect(fabFinder, findsOneWidget);

       // Act: Tap the FAB
       await tester.tap(fabFinder);
       await tester.pumpAndSettle();

       // Assert: Verify GoRouter was called with goNamed
       verify(() => mockGoRouter.goNamed(
         NoteEditorScreen.routeName, 
         pathParameters: {'id': 'new'}
       )).called(1);
    });

    testWidgets('Tapping a note item navigates to editor with correct ID', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestableWidget(
        notesStreamController: notesStreamController,
        mockGoRouter: mockGoRouter,
        mockNoteDao: mockNoteDao,
      ));
      await tester.pump(); // Process initial loading

      // Act: Emit data and let UI settle
      notesStreamController.add(testNotes);
      await tester.pumpAndSettle();

      // Find the first ListTile (assuming based on title)
      final noteTileFinder = find.widgetWithText(ListTile, 'Note 1');
      expect(noteTileFinder, findsOneWidget);

      // Act: Tap the tile
      await tester.tap(noteTileFinder);
      await tester.pumpAndSettle(); // Allow navigation to process

      // Assert: Verify GoRouter was called with the correct ID
      verify(() => mockGoRouter.goNamed(
        NoteEditorScreen.routeName, 
        pathParameters: {'id': '1'} // Expecting ID 1 for 'Note 1'
      )).called(1);
    });

    // TODO: Test note deletion (Requires mocking DAO and UI implementation)
  });
} 