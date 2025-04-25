import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lockpaper/core/security/biometrics_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/services.dart'; // For PlatformException

// Generate mocks for LocalAuthentication
@GenerateMocks([LocalAuthentication])
import 'biometrics_service_test.mocks.dart'; // Import generated mocks

void main() {
  late MockLocalAuthentication mockAuth;
  late BiometricsService biometricsService;

  setUp(() {
    mockAuth = MockLocalAuthentication();
    // Inject the mock LocalAuthentication instance
    biometricsService = BiometricsService(auth: mockAuth);
  });

  group('BiometricsService Tests', () {
    group('canAuthenticate', () {
      test('should return true if canCheckBiometrics and isDeviceSupported are true', () async {
        // Arrange
        when(mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
        
        // Act
        final result = await biometricsService.canAuthenticate;

        // Assert
        expect(result, isTrue);
        verify(mockAuth.canCheckBiometrics).called(1);
        verify(mockAuth.isDeviceSupported()).called(1);
      });

      test('should return false if canCheckBiometrics is false', () async {
        // Arrange
        when(mockAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(mockAuth.isDeviceSupported()).thenAnswer((_) async => true); // Still need to mock this

        // Act
        final result = await biometricsService.canAuthenticate;

        // Assert
        expect(result, isFalse);
         verify(mockAuth.canCheckBiometrics).called(1);
        verify(mockAuth.isDeviceSupported()).called(1); // Verify it was checked
      });

      test('should return false if isDeviceSupported is false', () async {
        // Arrange
        when(mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act
        final result = await biometricsService.canAuthenticate;

        // Assert
        expect(result, isFalse);
         verify(mockAuth.canCheckBiometrics).called(1);
         verify(mockAuth.isDeviceSupported()).called(1);
      });
    });

    group('authenticate', () {
       const testReason = 'Test authentication';
       // Helper to create common AuthenticationOptions
       const expectedOptions = AuthenticationOptions(
         stickyAuth: false,
         biometricOnly: false,
       );

      test('should return true on successful authentication', () async {
        // Arrange
        when(mockAuth.authenticate(
          localizedReason: testReason,
          options: expectedOptions
        )).thenAnswer((_) async => true);

        // Act
        final result = await biometricsService.authenticate(testReason);

        // Assert
        expect(result, isTrue);
        verify(mockAuth.authenticate(
          localizedReason: testReason,
          options: expectedOptions
        )).called(1);
      });

      test('should return false on failed authentication', () async {
        // Arrange
         when(mockAuth.authenticate(
          localizedReason: testReason,
          options: expectedOptions
        )).thenAnswer((_) async => false);

        // Act
        final result = await biometricsService.authenticate(testReason);

        // Assert
        expect(result, isFalse);
         verify(mockAuth.authenticate(
          localizedReason: testReason,
          options: expectedOptions
        )).called(1);
      });

      test('should rethrow PlatformException on error', () async {
        // Arrange
        final platformException = PlatformException(code: 'TestError');
        when(mockAuth.authenticate(
          localizedReason: testReason,
          options: expectedOptions
        )).thenThrow(platformException);

        // Act & Assert
        expect(
          () => biometricsService.authenticate(testReason),
          throwsA(isA<PlatformException>())
        );
         verify(mockAuth.authenticate(
          localizedReason: testReason,
          options: expectedOptions
        )).called(1);
      });
    });
  });
} 