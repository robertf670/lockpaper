import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockpaper/core/security/encryption_key_service.dart';
import 'dart:convert'; // Import for base64Url
import 'package:mocktail/mocktail.dart'; // Import mocktail

// Define mock using mocktail
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late EncryptionKeyService keyService;

  const dbKeyStorageKey = 'database_encryption_key'; // Keep using constant

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    // Inject the mock storage into the service instance for testing
    keyService = EncryptionKeyService(storage: mockStorage);
    
    // Register fallback value for named 'value' argument in write
    registerFallbackValue(''); 
  });

  group('EncryptionKeyService Tests', () {
    test('generateAndStoreNewKey should write a key and return it', () async {
      // Arrange
      // Use mocktail's verify(...) syntax for capturing later
      when(() => mockStorage.write(key: dbKeyStorageKey, value: any(named: 'value')))
          .thenAnswer((_) async {}); // Just need a dummy answer for write

      // Act
      final generatedKey = await keyService.generateAndStoreNewKey();

      // Assert
      // Verify write was called and capture the argument
      final captured = verify(() => mockStorage.write(key: dbKeyStorageKey, value: captureAny(named: 'value'))).captured;
      
      // Verify the captured value is not empty and matches the returned key
      expect(captured, isNotEmpty);
      expect(captured.first, isA<String>()); // Ensure captured type is String
      final capturedValue = captured.first as String;
      expect(capturedValue, isNotEmpty);
      expect(generatedKey, capturedValue);
      // Optionally, decode and check byte length (32 bytes for 256-bit)
      expect(base64Url.decode(generatedKey).length, 32);
    });

    test('getDatabaseKey should return stored key', () async {
      // Arrange
      const storedKey = 'test_key';
      when(() => mockStorage.read(key: dbKeyStorageKey)).thenAnswer((_) => Future.value(storedKey));

      // Act
      final retrievedKey = await keyService.getDatabaseKey();

      // Assert
      verify(() => mockStorage.read(key: dbKeyStorageKey)).called(1);
      expect(retrievedKey, storedKey);
    });

     test('getDatabaseKey should return null if no key stored', () async {
      // Arrange
      when(() => mockStorage.read(key: dbKeyStorageKey)).thenAnswer((_) => Future<String?>.value(null));

      // Act
      final retrievedKey = await keyService.getDatabaseKey();

      // Assert
      verify(() => mockStorage.read(key: dbKeyStorageKey)).called(1);
      expect(retrievedKey, isNull);
    });

    test('hasStoredKey should return true if key exists', () async {
      // Arrange
      when(() => mockStorage.read(key: dbKeyStorageKey)).thenAnswer((_) => Future.value('some_key'));

      // Act
      final exists = await keyService.hasStoredKey();

      // Assert
      verify(() => mockStorage.read(key: dbKeyStorageKey)).called(1);
      expect(exists, isTrue);
    });

    test('hasStoredKey should return false if key is null', () async {
      // Arrange
      when(() => mockStorage.read(key: dbKeyStorageKey)).thenAnswer((_) => Future<String?>.value(null));

      // Act
      final exists = await keyService.hasStoredKey();

      // Assert
      verify(() => mockStorage.read(key: dbKeyStorageKey)).called(1);
      expect(exists, isFalse);
    });

    test('hasStoredKey should return false if key is empty', () async {
      // Arrange
      when(() => mockStorage.read(key: dbKeyStorageKey)).thenAnswer((_) => Future.value(''));

      // Act
      final exists = await keyService.hasStoredKey();

      // Assert
      verify(() => mockStorage.read(key: dbKeyStorageKey)).called(1);
      expect(exists, isFalse);
    });

    test('deleteDatabaseKey should call delete on storage', () async {
      // Arrange
      // No return value needed for delete, just verification
       when(() => mockStorage.delete(key: dbKeyStorageKey)).thenAnswer((_) => Future.value()); // Use Future.value() for void async

      // Act
      await keyService.deleteDatabaseKey();

      // Assert
      verify(() => mockStorage.delete(key: dbKeyStorageKey)).called(1);
    });
  });
} 