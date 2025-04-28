import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lockpaper/core/security/biometrics_service.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:mocktail/mocktail.dart'; // Import mocktail

// Define mock using mocktail
class MockLocalAuthentication extends Mock implements LocalAuthentication {}

// Define a dummy AuthenticationOptions for fallback registration
class FakeAuthenticationOptions extends Fake implements AuthenticationOptions {}

void main() {
  late MockLocalAuthentication mockAuth;
  late BiometricsService biometricsService;

  // Register fallback value for AuthenticationOptions before tests run
  setUpAll(() {
    registerFallbackValue(FakeAuthenticationOptions());
  });

  setUp(() {
    mockAuth = MockLocalAuthentication();
    // Inject the mock LocalAuthentication instance
    biometricsService = BiometricsService(mockAuth);
  });

  group('BiometricsService Tests', () {
    group('canAuthenticate', () {
      test('should return true if canCheckBiometrics and isDeviceSupported are true', () async {
        // Arrange
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) => Future.value(true));
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) => Future.value(true));
        
        // Act
        final result = await biometricsService.canAuthenticate;

        // Assert
        expect(result, isTrue);
        verify(() => mockAuth.canCheckBiometrics).called(1);
        verify(() => mockAuth.isDeviceSupported()).called(1);
      });

      test('should return false if canCheckBiometrics is false', () async {
        // Arrange
        when(() => mockAuth.canCheckBiometrics).thenAnswer((_) => Future.value(false));
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) => Future.value(true)); // Still need to mock this

        // Act
        final result = await biometricsService.canAuthenticate;

        // Assert
        expect(result, isFalse);
        verify(() => mockAuth.canCheckBiometrics).called(1);
        verify(() => mockAuth.isDeviceSupported()).called(1); // Verify it was checked
      });

      test('should return false if isDeviceSupported is false', () async {
        // Arrange
        when(() => mockAuth.isDeviceSupported()).thenAnswer((_) => Future.value(false));

        // Act
        final result = await biometricsService.canAuthenticate;

        // Assert
        expect(result, isFalse);
        verify(() => mockAuth.isDeviceSupported()).called(1);
      });
    });

    group('authenticate', () {
       const testReason = 'Test authentication';
       // Define expected options matcher using mocktail
       final expectedOptionsMatcher = isA<AuthenticationOptions>()
           .having((o) => o.stickyAuth, 'stickyAuth', true)
           .having((o) => o.biometricOnly, 'biometricOnly', false);

      test('should return true on successful authentication', () async {
        // Arrange
        when(() => mockAuth.authenticate(
          localizedReason: testReason,
          options: any(named: 'options', that: expectedOptionsMatcher)
        )).thenAnswer((_) => Future.value(true));

        // Act
        final result = await biometricsService.authenticate(testReason);

        // Assert
        expect(result, isTrue);
        verify(() => mockAuth.authenticate(
          localizedReason: testReason,
          options: any(named: 'options', that: expectedOptionsMatcher)
        )).called(1);
      });

      test('should return false on failed authentication', () async {
        // Arrange
        when(() => mockAuth.authenticate(
          localizedReason: testReason,
          options: any(named: 'options', that: expectedOptionsMatcher)
        )).thenAnswer((_) => Future.value(false));

        // Act
        final result = await biometricsService.authenticate(testReason);

        // Assert
        expect(result, isFalse);
        verify(() => mockAuth.authenticate(
          localizedReason: testReason,
          options: any(named: 'options', that: expectedOptionsMatcher)
        )).called(1);
      });

      test('should return false on PlatformException error', () async {
        // Arrange
        final platformException = PlatformException(code: 'TestError');
        when(() => mockAuth.authenticate(
          localizedReason: testReason,
          options: any(named: 'options', that: expectedOptionsMatcher)
        )).thenThrow(platformException);

        // Act 
        final result = await biometricsService.authenticate(testReason);
        
        // Assert
        expect(result, isFalse);

        verify(() => mockAuth.authenticate(
          localizedReason: testReason,
          options: any(named: 'options', that: expectedOptionsMatcher)
        )).called(1);
      });
    });
  });
} 