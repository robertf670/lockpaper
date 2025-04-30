import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lockpaper/core/presentation/screens/pin_change/enter_current_pin_screen.dart';
import 'package:lockpaper/features/settings/presentation/screens/settings_screen.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockNavigatorObserver mockNavigatorObserver;
  late GoRouter testRouter;

  // Define routes needed for this test
  final testRoutes = <RouteBase>[
    GoRoute(
      path: '/', 
      builder: (context, state) => const Scaffold(body: Text('Initial Route')),
    ),
    GoRoute(
      name: SettingsScreen.routeName,
      path: SettingsScreen.routeName,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      name: EnterCurrentPinScreen.routeName, // Target for navigation
      path: EnterCurrentPinScreen.routeName,
      builder: (context, state) => 
          const Scaffold(body: Text('Mock Enter Current PIN Screen')),
    ),
  ];

  setUp(() {
    mockNavigatorObserver = MockNavigatorObserver();

    testRouter = GoRouter(
      initialLocation: '/', // Start somewhere else
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
    // Need ProviderScope even if not directly using providers on this screen
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: testRouter),
      ),
    );
    // Navigate to the SettingsScreen
    testRouter.pushNamed(SettingsScreen.routeName);
    await tester.pumpAndSettle(); // Allow navigation to complete
  }

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders initial UI elements correctly', (tester) async {
      await pumpTestScreen(tester);

      expect(find.text('Settings'), findsOneWidget); // AppBar title
      expect(find.widgetWithText(ListTile, 'Change PIN'), findsOneWidget);
      expect(find.widgetWithIcon(ListTile, Icons.pin_outlined), findsOneWidget);
      expect(find.text('Modify your application unlock PIN'), findsOneWidget); // Subtitle
    });

    testWidgets('tapping Change PIN navigates to EnterCurrentPinScreen', (tester) async {
      // Arrange
      await pumpTestScreen(tester);
      
      // Act
      await tester.tap(find.widgetWithText(ListTile, 'Change PIN'));
      await tester.pumpAndSettle(); // Allow navigation to process

      // Assert
      // Verify navigation occurred using the observer
      final captured = verify(() => mockNavigatorObserver.didPush(captureAny(), any())).captured;
      // Check the name of the last pushed route
      expect((captured.last as Route<dynamic>?)?.settings.name, EnterCurrentPinScreen.routeName);
      // Check we landed on the mock target screen
      expect(find.text('Mock Enter Current PIN Screen'), findsOneWidget);
    });
  });
} 