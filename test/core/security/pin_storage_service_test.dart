import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockpaper/core/security/pin_storage_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:crypt/crypt.dart'; // Import crypt for hashing checks if needed

// Mocks
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockRef extends Mock implements Ref {}

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late PinStorageService pinStorageService;

  // Stored hash for verification tests (generated using the service's method)
  // Example: Hash for "123456" using Crypt.sha512
  final testPin = '123456';
  final storedHash = Crypt.sha512(testPin).toString();

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    pinStorageService = PinStorageService(mockSecureStorage);
  });

  group('PinStorageService', () {
    const pinStorageKey = 'app_pin_hash'; // Change final to const

    group('hasPin', () {
       test('should return true if a PIN hash is stored', () async {
        // Arrange
        when(() => mockSecureStorage.read(key: pinStorageKey))
            .thenAnswer((_) async => storedHash); // Use pre-calculated hash

        // Act
        final result = await pinStorageService.hasPin();

        // Assert
        expect(result, isTrue);
        verify(() => mockSecureStorage.read(key: pinStorageKey)).called(1);
      });

      test('should return false if no PIN hash is stored (null)', () async {
         // Arrange
         when(() => mockSecureStorage.read(key: pinStorageKey))
             .thenAnswer((_) async => null);

         // Act
         final result = await pinStorageService.hasPin();

         // Assert
         expect(result, isFalse);
         verify(() => mockSecureStorage.read(key: pinStorageKey)).called(1);
       });

       test('should return false if stored PIN hash is empty', () async {
         // Arrange
         when(() => mockSecureStorage.read(key: pinStorageKey))
             .thenAnswer((_) async => '');

         // Act
         final result = await pinStorageService.hasPin();

         // Assert
         expect(result, isFalse);
         verify(() => mockSecureStorage.read(key: pinStorageKey)).called(1);
       });

       test('should return false and handle exception on storage read error', () async {
         // Arrange
         final exception = Exception('Storage error');
         when(() => mockSecureStorage.read(key: pinStorageKey))
             .thenThrow(exception);

         // Act
         final result = await pinStorageService.hasPin();

         // Assert
         expect(result, isFalse);
         verify(() => mockSecureStorage.read(key: pinStorageKey)).called(1);
         // Optionally check if the error was logged (if using a mock logger)
       });
    });

    group('setPin', () {
      test('should hash the PIN and write it to secure storage', () async {
        // Arrange
        const pinToSet = 'newPin123';
        // Capture the arguments passed to write
        when(() => mockSecureStorage.write(key: pinStorageKey, value: any(named: 'value')))
            .thenAnswer((_) async => Future.value()); // Mock successful write

        // Act
        await pinStorageService.setPin(pinToSet);

        // Assert
        final captured = verify(() => mockSecureStorage.write(
            key: pinStorageKey,
            value: captureAny(named: 'value'),
          )).captured;
        
        // Verify a non-empty string was captured (the hash)
        expect(captured.single, isA<String>());
        expect(captured.single, isNotEmpty);
        // We can also verify that the captured hash matches the original pin
        // using the Crypt object (since it includes the salt)
        final hashFromStorage = captured.single as String;
        expect(Crypt(hashFromStorage).match(pinToSet), isTrue);
      });

       test('should rethrow exception on storage write error', () async {
         // Arrange
         const pinToSet = 'errorPin';
         final exception = Exception('Storage write error');
         when(() => mockSecureStorage.write(key: pinStorageKey, value: any(named: 'value')))
             .thenThrow(exception);

         // Act & Assert
         expect(
           () => pinStorageService.setPin(pinToSet),
           throwsA(exception), // Check that the specific exception is rethrown
         );
         
          // Verify write was attempted (even though it failed)
          verify(() => mockSecureStorage.write(
            key: pinStorageKey,
            value: any(named: 'value'),
          )).called(1);
       });
    });

    group('verifyPin', () {
      test('should return true if entered PIN matches the stored hash', () async {
        // Arrange
        when(() => mockSecureStorage.read(key: pinStorageKey))
            .thenAnswer((_) async => storedHash); // Use pre-calculated hash for "123456"
        
        // Act
        final result = await pinStorageService.verifyPin(testPin); // testPin is "123456"

        // Assert
        expect(result, isTrue);
        verify(() => mockSecureStorage.read(key: pinStorageKey)).called(1);
      });

       test('should return false if entered PIN does not match the stored hash', () async {
        // Arrange
         when(() => mockSecureStorage.read(key: pinStorageKey))
             .thenAnswer((_) async => storedHash);
         const incorrectPin = '654321';

         // Act
         final result = await pinStorageService.verifyPin(incorrectPin);

         // Assert
         expect(result, isFalse);
         verify(() => mockSecureStorage.read(key: pinStorageKey)).called(1);
       });

       test('should return false if no PIN hash is stored (null)', () async {
         // Arrange
         when(() => mockSecureStorage.read(key: pinStorageKey))
             .thenAnswer((_) async => null);

         // Act
         final result = await pinStorageService.verifyPin(testPin);

         // Assert
         expect(result, isFalse);
         verify(() => mockSecureStorage.read(key: pinStorageKey)).called(1);
       });

       test('should return false if stored PIN hash is empty', () async {
         // Arrange
         when(() => mockSecureStorage.read(key: pinStorageKey))
             .thenAnswer((_) async => '');

         // Act
         final result = await pinStorageService.verifyPin(testPin);

         // Assert
         expect(result, isFalse);
         verify(() => mockSecureStorage.read(key: pinStorageKey)).called(1);
       });

       test('should return false and handle exception on storage read error', () async {
         // Arrange
         final exception = Exception('Storage read error');
         when(() => mockSecureStorage.read(key: pinStorageKey))
             .thenThrow(exception);

         // Act
         final result = await pinStorageService.verifyPin(testPin);

         // Assert
         expect(result, isFalse);
         verify(() => mockSecureStorage.read(key: pinStorageKey)).called(1);
       });
    });

    group('deletePin', () {
      test('should call secureStorage.delete with the correct key', () async {
        // Arrange
        when(() => mockSecureStorage.delete(key: pinStorageKey))
            .thenAnswer((_) async => Future.value()); // Mock successful delete

        // Act
        await pinStorageService.deletePin();

        // Assert
        verify(() => mockSecureStorage.delete(key: pinStorageKey)).called(1);
      });

      test('should rethrow exception on storage delete error', () async {
        // Arrange
        final exception = Exception('Storage delete error');
        when(() => mockSecureStorage.delete(key: pinStorageKey))
            .thenThrow(exception);

        // Act & Assert
        expect(
          () => pinStorageService.deletePin(),
          throwsA(exception),
        );
        verify(() => mockSecureStorage.delete(key: pinStorageKey)).called(1);
      });
    });
  });
} 