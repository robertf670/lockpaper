import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lockpaper/core/security/biometrics_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/services.dart'; // For PlatformException

// Mocks are now generated via test/mocks/core_mocks.dart
// @GenerateMocks([LocalAuthentication]) 
import '../../mocks/core_mocks.mocks.dart'; // Correct relative path

void main() {
  late MockLocalAuthentication mockAuth;
  late BiometricsService biometricsService;

  setUp(() {
    mockAuth = MockLocalAuthentication();
    // Inject the mock LocalAuthentication instance
    biometricsService = BiometricsService(mockAuth);
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
        // when(mockAuth.canCheckBiometrics).thenAnswer((_) async => true); // No need to mock this if isDeviceSupported is false
        when(mockAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act
        final result = await biometricsService.canAuthenticate;

        // Assert
        expect(result, isFalse);
        // verify(mockAuth.canCheckBiometrics).called(1); // Should not be called if device not supported
         verify(mockAuth.isDeviceSupported()).called(1);
      });
    });

    group('authenticate', () {
       const testReason = 'Test authentication';
       // Helper to create common AuthenticationOptions
       const expectedOptions = AuthenticationOptions(
         stickyAuth: true,
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

      test('should return false on PlatformException error', () async {
        // Arrange
        final platformException = PlatformException(code: 'TestError');
        when(mockAuth.authenticate(
          localizedReason: testReason,
          options: expectedOptions
        )).thenThrow(platformException);

        // Act 
        final result = await biometricsService.authenticate(testReason);
        
        // Assert
        expect(result, isFalse);

         verify(mockAuth.authenticate(
          localizedReason: testReason,
          options: expectedOptions
        )).called(1);
      });
    });
  });
} 