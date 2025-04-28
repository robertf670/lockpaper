import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockpaper/core/security/encryption_key_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:convert'; // Import for base64Url

// Mocks are now generated via test/mocks/core_mocks.dart
// @GenerateMocks([FlutterSecureStorage])
import '../../mocks/core_mocks.mocks.dart'; // Correct relative path

void main() {
  late MockFlutterSecureStorage mockStorage;
  late EncryptionKeyService keyService;

  const dbKeyStorageKey = 'database_encryption_key'; // Keep using constant

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    // Inject the mock storage into the service instance for testing
    keyService = EncryptionKeyService(storage: mockStorage);
  });

  group('EncryptionKeyService Tests', () {
    test('generateAndStoreNewKey should write a key and return it', () async {
      // Arrange
      // Capture the argument written to storage
      final captured = <String>[];
      when(mockStorage.write(key: dbKeyStorageKey, value: captureAnyNamed('value')))
          .thenAnswer((invocation) async {
              captured.add(invocation.namedArguments[#value] as String);
            });

      // Act
      final generatedKey = await keyService.generateAndStoreNewKey();

      // Assert
      // Verify write was called exactly once with the correct key
      verify(mockStorage.write(key: dbKeyStorageKey, value: anyNamed('value'))).called(1);
      // Verify the captured value is not empty and matches the returned key
      expect(captured, isNotEmpty);
      expect(captured.first, isNotEmpty);
      expect(generatedKey, captured.first);
      // Optionally, decode and check byte length (32 bytes for 256-bit)
      expect(base64Url.decode(generatedKey).length, 32);
    });

    test('getDatabaseKey should return stored key', () async {
      // Arrange
      const storedKey = 'test_key';
      when(mockStorage.read(key: dbKeyStorageKey)).thenAnswer((_) async => storedKey);

      // Act
      final retrievedKey = await keyService.getDatabaseKey();

      // Assert
      verify(mockStorage.read(key: dbKeyStorageKey)).called(1);
      expect(retrievedKey, storedKey);
    });

     test('getDatabaseKey should return null if no key stored', () async {
      // Arrange
      when(mockStorage.read(key: dbKeyStorageKey)).thenAnswer((_) async => null);

      // Act
      final retrievedKey = await keyService.getDatabaseKey();

      // Assert
      verify(mockStorage.read(key: dbKeyStorageKey)).called(1);
      expect(retrievedKey, isNull);
    });

    test('hasStoredKey should return true if key exists', () async {
      // Arrange
      when(mockStorage.read(key: dbKeyStorageKey)).thenAnswer((_) async => 'some_key');

      // Act
      final exists = await keyService.hasStoredKey();

      // Assert
      verify(mockStorage.read(key: dbKeyStorageKey)).called(1);
      expect(exists, isTrue);
    });

    test('hasStoredKey should return false if key is null', () async {
      // Arrange
      when(mockStorage.read(key: dbKeyStorageKey)).thenAnswer((_) async => null);

      // Act
      final exists = await keyService.hasStoredKey();

      // Assert
      verify(mockStorage.read(key: dbKeyStorageKey)).called(1);
      expect(exists, isFalse);
    });

    test('hasStoredKey should return false if key is empty', () async {
      // Arrange
      when(mockStorage.read(key: dbKeyStorageKey)).thenAnswer((_) async => '');

      // Act
      final exists = await keyService.hasStoredKey();

      // Assert
      verify(mockStorage.read(key: dbKeyStorageKey)).called(1);
      expect(exists, isFalse);
    });

    test('deleteDatabaseKey should call delete on storage', () async {
      // Arrange
      // No return value needed for delete, just verification
       when(mockStorage.delete(key: dbKeyStorageKey)).thenAnswer((_) async => {});

      // Act
      await keyService.deleteDatabaseKey();

      // Assert
      verify(mockStorage.delete(key: dbKeyStorageKey)).called(1);
    });
  });
} 