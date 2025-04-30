import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lockpaper/core/presentation/screens/pin_setup/confirm_pin_screen.dart';
import 'package:lockpaper/core/security/pin_storage_service.dart';
import 'package:lockpaper/features/notes/presentation/screens/notes_list_screen.dart'; // Import NotesListScreen
import 'package:mocktail/mocktail.dart';
import 'package:pinput/pinput.dart';

// Mocks
class MockPinStorageService extends Mock implements PinStorageService {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockPinStorageService mockPinStorageService;
  late MockNavigatorObserver mockNavigatorObserver;
  late GoRouter testRouter;
  const initialPin = '123456'; // PIN passed from CreatePinScreen

  // Define routes for the test router
  final testRoutes = <RouteBase>[
    GoRoute(
      path: '/', // Initial dummy path
      builder: (context, state) => const Scaffold(body: Text('Initial Route')),
    ),
    GoRoute(
      name: ConfirmPinScreen.routeName,
      path: ConfirmPinScreen.routeName, // Use path e.g., '/confirm-pin'
      builder: (context, state) {
        final pin = state.extra as String? ?? ''; // Get pin from extra
        return ConfirmPinScreen(initialPin: pin);
      },
    ),
    GoRoute(
      name: NotesListScreen.routeName,
      path: '/${NotesListScreen.routeName}', // Use path e.g., '/notes'
      builder: (context, state) => 
          const Scaffold(body: Text('Mock Notes Screen')), // Target screen
    ),
  ];

  setUp(() {
    mockPinStorageService = MockPinStorageService();
    mockNavigatorObserver = MockNavigatorObserver();

    // Create the test router instance for each test
    testRouter = GoRouter(
      initialLocation: '/', // Start at the dummy route
      routes: testRoutes,
      observers: [mockNavigatorObserver],
    );

    // Register fallback value for Route for the observer
    registerFallbackValue(MaterialPageRoute<void>(builder: (_) => Container()));
    registerFallbackValue(const RouteSettings()); // Needed if capturing settings

    // Add dummy mocks for other NavigatorObserver methods to prevent "Unexpected calls"
    // We only care about didPush in these tests.
    when(() => mockNavigatorObserver.didPop(any(), any())).thenAnswer((_) {});
    when(() => mockNavigatorObserver.didRemove(any(), any())).thenAnswer((_) {});
    when(() => mockNavigatorObserver.didReplace(newRoute: any(named: 'newRoute'), oldRoute: any(named: 'oldRoute'))).thenAnswer((_) {});
    when(() => mockNavigatorObserver.didStartUserGesture(any(), any())).thenAnswer((_) {});
    when(() => mockNavigatorObserver.didStopUserGesture()).thenAnswer((_) {});
    when(() => mockNavigatorObserver.didChangeTop(any(), any())).thenAnswer((_) {});
    // Mocking the getter
    when(() => mockNavigatorObserver.navigator).thenReturn(null); 
  });

  // Helper function to pump the main widget with the router
  Future<void> pumpTestRouterWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pinStorageServiceProvider.overrideWithValue(mockPinStorageService),
        ],
        child: MaterialApp.router(
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(), 
          routerConfig: testRouter,
        ),
      ),
    );
  }

  group('ConfirmPinScreen Widget Tests', () {
    testWidgets('renders initial UI elements correctly', (tester) async {
      // Arrange: Pump the router and navigate to the screen
      await pumpTestRouterWidget(tester);
      testRouter.pushNamed(ConfirmPinScreen.routeName, extra: initialPin);
      await tester.pump(); // Start navigation
      await tester.pump(const Duration(seconds: 1)); // Allow navigation and focus request

      // Assert
      expect(find.text('Confirm PIN'), findsOneWidget);
      expect(find.textContaining('Re-enter your PIN to confirm.'), findsOneWidget);
      expect(find.byType(Pinput), findsOneWidget);
    });

    testWidgets('entering matching PIN saves and navigates to NotesListScreen', (tester) async {
      // Arrange
      when(() => mockPinStorageService.setPin(any())).thenAnswer((_) async => true);
      // No need to mock navigation, observer will track it

      await pumpTestRouterWidget(tester);
      testRouter.pushNamed(ConfirmPinScreen.routeName, extra: initialPin);
      await tester.pump(); // Start navigation
      await tester.pump(const Duration(seconds: 1)); // Allow navigation and focus request

      // Act: Enter the matching PIN
      final pinputFinder = find.byType(Pinput);
      final pinputWidget = tester.widget<Pinput>(pinputFinder);
      pinputWidget.controller!.text = initialPin;
      await tester.pump(); // Process controller update & trigger onCompleted
      await tester.pump(); // Allow async pinService.setPin to complete
      await tester.pump(const Duration(seconds: 1)); // Allow time for navigation/snackbar animations

      // Assert
      verify(() => mockPinStorageService.setPin(initialPin)).called(1);
      
      // Verify navigation occurred using the observer
      final captured = verify(() => mockNavigatorObserver.didPush(captureAny(), any())).captured;
      // Check if the pushed route corresponds to the NotesListScreen
      final pushedRoute = captured.last as Route<dynamic>?;
      expect(pushedRoute?.settings.name, NotesListScreen.routeName);

      // Check for success SnackBar message
      expect(find.text('PIN set successfully!'), findsOneWidget); 
      // Verify we landed on the mock notes screen
      expect(find.text('Mock Notes Screen'), findsOneWidget);
    });

    testWidgets('entering mismatching PIN shows error text and clears field', (tester) async {
      // Arrange
      const wrongPin = '654321';
      await pumpTestRouterWidget(tester);
      testRouter.pushNamed(ConfirmPinScreen.routeName, extra: initialPin);
      await tester.pump(); // Start navigation
      await tester.pump(const Duration(seconds: 1)); // Allow navigation and focus request

      // Act: Enter mismatching PIN
      final pinputFinder = find.byType(Pinput);
      final pinputWidget = tester.widget<Pinput>(pinputFinder);
      final controller = pinputWidget.controller!;
      controller.text = wrongPin;
      await tester.pump(); // Process controller update & trigger onCompleted
      await tester.pump(); // Allow potential async gap
      await tester.pump(const Duration(seconds: 1)); // Allow time for error state/focus animations

      // Assert
      verifyNever(() => mockPinStorageService.setPin(any()));
      
      // Verify navigation to NotesListScreen did NOT occur
      // Ignore potential spurious navigation to 'home' in test environment
      final captured = verify(() => 
        mockNavigatorObserver.didPush(captureAny(), any())
      ).captured;
      expect(
        captured.any((route) {
          final name = (route as Route<dynamic>?)?.settings.name;
          // ONLY check for the intended success route
          return name == NotesListScreen.routeName;
        }), 
        isFalse, 
        reason: 'Should not have navigated to NotesListScreen'
      );

      // Check for error message
      expect(find.text('PINs do not match. Please try again.'), findsOneWidget);
      expect(controller.text, isEmpty);
    });

    testWidgets('PIN storage failure shows error text', (tester) async {
       // Arrange
       // Mock setPin to throw an exception to simulate failure
       when(() => mockPinStorageService.setPin(any()))
           .thenThrow(Exception('Mock PIN storage failed')); // Use thenThrow
           
       await pumpTestRouterWidget(tester);
       testRouter.pushNamed(ConfirmPinScreen.routeName, extra: initialPin);
       await tester.pump(); // Start navigation
       await tester.pump(const Duration(seconds: 1)); // Allow navigation and focus request

       // Act: Enter matching PIN
       final pinputFinder = find.byType(Pinput);
       final pinputWidget = tester.widget<Pinput>(pinputFinder);
       pinputWidget.controller!.text = initialPin; 
       await tester.pump(); // Process controller update & trigger onCompleted
       await tester.pump(); // Allow async pinService.setPin to complete (and throw)
       await tester.pump(const Duration(seconds: 1)); // Allow time for error state/focus animations

       // Assert
       verify(() => mockPinStorageService.setPin(initialPin)).called(1);
       
       // Verify navigation to NotesListScreen did NOT occur
       final captured = verify(() => 
         mockNavigatorObserver.didPush(captureAny(), any())
       ).captured;
       expect(
         captured.any((route) {
           final name = (route as Route<dynamic>?)?.settings.name;
           return name == NotesListScreen.routeName;
         }), 
         isFalse,
         reason: 'Should not have navigated to NotesListScreen'
       );

       // Check for storage error message
       expect(find.text('Failed to save PIN. Please try again.'), findsOneWidget);
    });

    // TODO: Add tests for focus management if needed.
    // TODO: Add tests for specific Pinput error states/themes if implemented.
  });
} 