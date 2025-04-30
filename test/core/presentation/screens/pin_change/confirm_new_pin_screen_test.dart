import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lockpaper/core/presentation/screens/pin_change/confirm_new_pin_screen.dart';
import 'package:lockpaper/core/security/pin_storage_service.dart';
import 'package:lockpaper/features/notes/presentation/screens/notes_list_screen.dart'; 
import 'package:mocktail/mocktail.dart';
import 'package:pinput/pinput.dart';

// Mocks
class MockPinStorageService extends Mock implements PinStorageService {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockPinStorageService mockPinStorageService;
  late MockNavigatorObserver mockNavigatorObserver;
  late GoRouter testRouter;
  const newPin = '987654'; // New PIN passed to this screen

  // Define routes for the test router
  final testRoutes = <RouteBase>[
    GoRoute(
      path: '/', 
      builder: (context, state) => const Scaffold(body: Text('Initial Route')),
    ),
    GoRoute(
      name: ConfirmNewPinScreen.routeName,
      path: ConfirmNewPinScreen.routeName,
      builder: (context, state) {
        final pinArg = state.extra as String? ?? ''; // Get pin from extra
        return ConfirmNewPinScreen(newPinToConfirm: pinArg);
      },
    ),
    GoRoute(
      name: NotesListScreen.routeName, // Target for success
      path: '/${NotesListScreen.routeName}',
      builder: (context, state) => 
          const Scaffold(body: Text('Mock Notes Screen')), 
    ),
  ];

  setUp(() {
    mockPinStorageService = MockPinStorageService();
    mockNavigatorObserver = MockNavigatorObserver();

    testRouter = GoRouter(
      initialLocation: '/',
      routes: testRoutes,
      observers: [mockNavigatorObserver],
    );

    registerFallbackValue(MaterialPageRoute<void>(builder: (_) => Container()));
    registerFallbackValue(const RouteSettings()); 

    // Add dummy mocks for other NavigatorObserver methods
    when(() => mockNavigatorObserver.didPop(any(), any())).thenAnswer((_) {});
    when(() => mockNavigatorObserver.didRemove(any(), any())).thenAnswer((_) {});
    when(() => mockNavigatorObserver.didReplace(newRoute: any(named: 'newRoute'), oldRoute: any(named: 'oldRoute'))).thenAnswer((_) {});
    when(() => mockNavigatorObserver.didStartUserGesture(any(), any())).thenAnswer((_) {});
    when(() => mockNavigatorObserver.didStopUserGesture()).thenAnswer((_) {});
    when(() => mockNavigatorObserver.didChangeTop(any(), any())).thenAnswer((_) {});
    when(() => mockNavigatorObserver.navigator).thenReturn(null); 
  });

  // Helper function to pump the screen
  Future<void> pumpTestScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pinStorageServiceProvider.overrideWithValue(mockPinStorageService),
        ],
        // Need ScaffoldMessenger for SnackBar
        child: MaterialApp.router(
          scaffoldMessengerKey: GlobalKey<ScaffoldMessengerState>(), 
          routerConfig: testRouter,
        ),
      ),
    );
    // Navigate to the screen under test, passing the new PIN
    testRouter.pushNamed(ConfirmNewPinScreen.routeName, extra: newPin);
    await tester.pump(); // Start navigation
    await tester.pump(const Duration(seconds: 1)); // Allow navigation and focus request
  }

  group('ConfirmNewPinScreen Widget Tests', () {
    testWidgets('renders initial UI elements correctly', (tester) async {
      await pumpTestScreen(tester);

      expect(find.text('Confirm New PIN'), findsOneWidget);
      expect(find.textContaining('Re-enter your new 6-digit PIN'), findsOneWidget);
      expect(find.byType(Pinput), findsOneWidget);
    });

    testWidgets('entering mismatching PIN shows error text and clears field', (tester) async {
      // Arrange
      const wrongPin = '111111';
      await pumpTestScreen(tester);
      
      // Act
      final pinputFinder = find.byType(Pinput);
      final pinputWidget = tester.widget<Pinput>(pinputFinder);
      final controller = pinputWidget.controller!;
      controller.text = wrongPin;
      await tester.pump(); // Process update
      await tester.pump(const Duration(seconds: 1)); // Allow error state changes & focus delay

      // Assert
      verifyNever(() => mockPinStorageService.setPin(any()));
      expect(find.text('PINs do not match. Please try again.'), findsOneWidget);
      expect(controller.text, isEmpty);
      
      // Verify no navigation to NotesListScreen occurred
      final captured = verify(() => mockNavigatorObserver.didPush(captureAny(), any())).captured;
      expect(
        captured.any((route) => (route as Route<dynamic>?)?.settings.name == NotesListScreen.routeName), 
        isFalse,
        reason: 'Should not have navigated on mismatching PIN'
      );
    });

     testWidgets('entering matching PIN with storage failure shows error text', (tester) async {
       // Arrange
       when(() => mockPinStorageService.setPin(newPin))
           .thenThrow(Exception('Mock save failed'));
       await pumpTestScreen(tester);
       
       // Act
       final pinputFinder = find.byType(Pinput);
       final pinputWidget = tester.widget<Pinput>(pinputFinder);
       pinputWidget.controller!.text = newPin;
       await tester.pump(); // Process update
       await tester.pump(); // Process async setPin (and throw)
       await tester.pump(const Duration(seconds: 1)); // Allow error state changes

       // Assert
       verify(() => mockPinStorageService.setPin(newPin)).called(1);
       expect(find.text('Failed to save new PIN. Please try again.'), findsOneWidget);
       
       // Verify no navigation to NotesListScreen occurred
       final captured = verify(() => mockNavigatorObserver.didPush(captureAny(), any())).captured;
       expect(
         captured.any((route) => (route as Route<dynamic>?)?.settings.name == NotesListScreen.routeName), 
         isFalse,
         reason: 'Should not have navigated on PIN save failure'
       );
    });

    testWidgets('entering matching PIN successfully saves and navigates', (tester) async {
      // Arrange
      when(() => mockPinStorageService.setPin(newPin)).thenAnswer((_) async {}); // Success
      await pumpTestScreen(tester);
      
      // Act
      final pinputFinder = find.byType(Pinput);
      final pinputWidget = tester.widget<Pinput>(pinputFinder);
      pinputWidget.controller!.text = newPin;
      await tester.pump(); // Process update
      await tester.pump(); // Process async setPin
      await tester.pump(const Duration(seconds: 1)); // Allow navigation changes & SnackBar

      // Assert
      verify(() => mockPinStorageService.setPin(newPin)).called(1);
      
      // Verify navigation to NotesListScreen occurred
      final captured = verify(() => mockNavigatorObserver.didPush(captureAny(), any())).captured;
      expect(
        captured.any((route) => (route as Route<dynamic>?)?.settings.name == NotesListScreen.routeName), 
        isTrue,
        reason: 'Should have navigated on successful PIN change'
      );
      expect(find.text('Mock Notes Screen'), findsOneWidget); // Check we landed
      expect(find.text('PIN changed successfully!'), findsOneWidget); // Check SnackBar
    });

  });
} 