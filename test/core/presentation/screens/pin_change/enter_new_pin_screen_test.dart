import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lockpaper/core/presentation/screens/pin_change/confirm_new_pin_screen.dart';
import 'package:lockpaper/core/presentation/screens/pin_change/enter_new_pin_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pinput/pinput.dart';

// Mocks
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockNavigatorObserver mockNavigatorObserver;
  late GoRouter testRouter;

  // Define routes for the test router
  final testRoutes = <RouteBase>[
    GoRoute(
      path: '/', 
      builder: (context, state) => const Scaffold(body: Text('Initial Route')),
    ),
    GoRoute(
      name: EnterNewPinScreen.routeName,
      path: EnterNewPinScreen.routeName,
      builder: (context, state) => const EnterNewPinScreen(),
    ),
    GoRoute(
      name: ConfirmNewPinScreen.routeName, // Target for success
      path: ConfirmNewPinScreen.routeName,
      builder: (context, state) {
         final newPin = state.extra as String?;
         return Scaffold(body: Text('Mock Confirm New PIN: $newPin'));
      }
    ),
  ];

  setUp(() {
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
    // Need ProviderScope even if not overriding anything for this screen
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: testRouter),
      ),
    );
    // Navigate to the screen under test
    testRouter.pushNamed(EnterNewPinScreen.routeName);
    await tester.pump(); // Start navigation
    await tester.pump(const Duration(seconds: 1)); // Allow navigation and focus request
  }

  group('EnterNewPinScreen Widget Tests', () {
    testWidgets('renders initial UI elements correctly', (tester) async {
      await pumpTestScreen(tester);

      expect(find.text('Enter New PIN'), findsOneWidget);
      expect(find.textContaining('Enter your new secure 6-digit PIN.'), findsOneWidget);
      expect(find.byType(Pinput), findsOneWidget);
    });

    testWidgets('entering PIN navigates to ConfirmNewPinScreen with correct arguments', (tester) async {
      // Arrange
      const newPin = '987654';
      await pumpTestScreen(tester);
      
      // Act
      final pinputFinder = find.byType(Pinput);
      final pinputWidget = tester.widget<Pinput>(pinputFinder);
      pinputWidget.controller!.text = newPin;
      await tester.pump(); // Process update
      await tester.pump(const Duration(seconds: 1)); // Allow navigation changes

      // Assert
      // Verify navigation occurred using the observer
      Route<dynamic>? pushedRoute;
      String? pushedRouteName;

      // Capture the last pushed route details
      final captured = verify(() => mockNavigatorObserver.didPush(captureAny(), any())).captured;
      if (captured.isNotEmpty) {
        pushedRoute = captured.last as Route<dynamic>?;
        pushedRouteName = pushedRoute?.settings.name;
        // For pushNamed, args are in settings.arguments (via RouteSettings passed to MaterialPageRoute)
        // For goNamed used internally by pushNamed, it might be in state.extra.
        // Let's check settings.arguments first as it's more standard for push.
        // However, GoRouter often uses its own internal routing mechanisms.
        // Let's rely on checking the mock screen content which receives state.extra.
      }
      
      // Check we landed on the mock confirmation screen
      expect(find.text('Mock Confirm New PIN: $newPin'), findsOneWidget);
      // Check the route *name* was correct
      expect(pushedRouteName, ConfirmNewPinScreen.routeName);
    });
  });
} 