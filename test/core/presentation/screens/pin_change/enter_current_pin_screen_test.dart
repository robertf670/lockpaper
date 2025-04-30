import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lockpaper/core/presentation/screens/pin_change/enter_current_pin_screen.dart';
import 'package:lockpaper/core/presentation/screens/pin_change/enter_new_pin_screen.dart';
import 'package:lockpaper/core/security/pin_storage_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinput/pinput.dart';

// Mocks
class MockPinStorageService extends Mock implements PinStorageService {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockPinStorageService mockPinStorageService;
  late MockNavigatorObserver mockNavigatorObserver;
  late GoRouter testRouter;
  const currentPin = '123456';

  // Define routes for the test router
  final testRoutes = <RouteBase>[
    GoRoute(
      path: '/', 
      builder: (context, state) => const Scaffold(body: Text('Initial Route')),
    ),
    GoRoute(
      name: EnterCurrentPinScreen.routeName,
      path: EnterCurrentPinScreen.routeName,
      builder: (context, state) => const EnterCurrentPinScreen(),
    ),
    GoRoute(
      name: EnterNewPinScreen.routeName, // Target for success
      path: EnterNewPinScreen.routeName,
      builder: (context, state) => 
          const Scaffold(body: Text('Mock Enter New PIN Screen')),
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

  Future<void> pumpTestScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pinStorageServiceProvider.overrideWithValue(mockPinStorageService),
        ],
        child: MaterialApp.router(routerConfig: testRouter),
      ),
    );
    // Navigate to the screen under test
    testRouter.pushNamed(EnterCurrentPinScreen.routeName);
    await tester.pump(); // Start navigation
    await tester.pump(const Duration(seconds: 1)); // Allow navigation and focus request
  }

  group('EnterCurrentPinScreen Widget Tests', () {
    testWidgets('renders initial UI elements correctly', (tester) async {
      await pumpTestScreen(tester);

      expect(find.text('Enter Current PIN'), findsOneWidget);
      expect(find.textContaining('Please enter your current 6-digit PIN'), findsOneWidget);
      expect(find.byType(Pinput), findsOneWidget);
    });

    testWidgets('entering incorrect PIN shows error and does not navigate', (tester) async {
      // Arrange
      const wrongPin = '000000';
      when(() => mockPinStorageService.verifyPin(wrongPin)).thenAnswer((_) async => false);
      await pumpTestScreen(tester);
      
      // Act
      final pinputFinder = find.byType(Pinput);
      final pinputWidget = tester.widget<Pinput>(pinputFinder);
      final controller = pinputWidget.controller!;
      controller.text = wrongPin;
      await tester.pump(); // Process update
      await tester.pump(); // Process async verifyPin
      await tester.pump(const Duration(seconds: 1)); // Allow error state changes

      // Assert
      verify(() => mockPinStorageService.verifyPin(wrongPin)).called(1);
      expect(find.text('Incorrect PIN. Please try again.'), findsOneWidget);
      expect(controller.text, isEmpty);
      
      // Verify no navigation to EnterNewPinScreen occurred
      final captured = verify(() => mockNavigatorObserver.didPush(captureAny(), any())).captured;
      expect(
        captured.any((route) => (route as Route<dynamic>?)?.settings.name == EnterNewPinScreen.routeName), 
        isFalse,
        reason: 'Should not have navigated on incorrect PIN'
      );
    });

    testWidgets('entering correct PIN verifies and navigates to EnterNewPinScreen', (tester) async {
      // Arrange
      when(() => mockPinStorageService.verifyPin(currentPin)).thenAnswer((_) async => true);
      await pumpTestScreen(tester);
      
      // Act
      final pinputFinder = find.byType(Pinput);
      final pinputWidget = tester.widget<Pinput>(pinputFinder);
      pinputWidget.controller!.text = currentPin;
      await tester.pump(); // Process update
      await tester.pump(); // Process async verifyPin
      await tester.pump(const Duration(seconds: 1)); // Allow navigation changes

      // Assert
      verify(() => mockPinStorageService.verifyPin(currentPin)).called(1);
      
      // Verify navigation to EnterNewPinScreen occurred
      final captured = verify(() => mockNavigatorObserver.didPush(captureAny(), any())).captured;
      expect(
        captured.any((route) => (route as Route<dynamic>?)?.settings.name == EnterNewPinScreen.routeName), 
        isTrue,
        reason: 'Should have navigated on correct PIN'
      );
      expect(find.text('Mock Enter New PIN Screen'), findsOneWidget); // Check we landed
    });
  });
} 