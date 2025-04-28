import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math'; // For random key generation
import 'dart:convert'; // For encoding

// TODO: Consider using PBKDF2 derivation from PIN as per plan.md

class EncryptionKeyService {
  // Make storage final but not initialized here
  final FlutterSecureStorage _storage;
  
  // Define storage key as a constant
  static const _dbKeyStorageKey = 'database_encryption_key';

  // Add a constructor that accepts FlutterSecureStorage
  // Provide a default instance for normal use
  EncryptionKeyService({FlutterSecureStorage? storage}) 
    : _storage = storage ?? const FlutterSecureStorage();

  /// Generates a secure random 32-byte (256-bit) key, stores it Base64 encoded
  Future<String> generateAndStoreNewKey() async {
    final random = Random.secure();
    // Generate 32 random bytes for a 256-bit key
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    // Use URL-safe Base64 encoding suitable for storage
    final base64Key = base64UrlEncode(keyBytes);
    await _storage.write(key: _dbKeyStorageKey, value: base64Key);
    return base64Key;
  }

  /// Retrieves the stored database key.
  Future<String?> getDatabaseKey() async {
    final key = await _storage.read(key: _dbKeyStorageKey);
    return key;
  }

  /// Checks if an encryption key is stored.
  Future<bool> hasStoredKey() async {
    final key = await _storage.read(key: _dbKeyStorageKey);
    final exists = key != null && key.isNotEmpty;
    return exists;
  }

  /// Deletes the stored database key.
   Future<void> deleteDatabaseKey() async {
    await _storage.delete(key: _dbKeyStorageKey);
  }
}

// Riverpod provider for the service
final encryptionKeyServiceProvider = Provider<EncryptionKeyService>((ref) {
  // Provide the default instance when creating through Riverpod
  return EncryptionKeyService();
}); 