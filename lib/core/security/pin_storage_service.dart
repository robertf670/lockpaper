import 'package:crypt/crypt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pin_storage_service.g.dart';

const _pinStorageKey = 'app_pin_hash';

/// Service for securely storing and verifying the user's PIN.
class PinStorageService {
  final FlutterSecureStorage _secureStorage;

  PinStorageService(this._secureStorage);

  /// Checks if a PIN hash is currently stored.
  Future<bool> hasPin() async {
    try {
      final storedHash = await _secureStorage.read(key: _pinStorageKey);
      return storedHash != null && storedHash.isNotEmpty;
    } catch (e) {
      // Handle potential storage errors
      // TODO: Replace with proper logging
      return false;
    }
  }

  /// Hashes and stores the provided PIN.
  /// Uses SHA512 for hashing.
  Future<void> setPin(String pin) async {
    try {
      // Hash the PIN using SHA512 with a salt.
      final hash = Crypt.sha512(pin).toString();
      await _secureStorage.write(key: _pinStorageKey, value: hash);
    } catch (e) {
      // Handle potential storage/hashing errors
      // TODO: Replace with proper logging
      rethrow; // Rethrow to indicate failure
    }
  }

  /// Verifies the entered PIN against the stored hash.
  Future<bool> verifyPin(String enteredPin) async {
    try {
      final storedHash = await _secureStorage.read(key: _pinStorageKey);
      if (storedHash == null || storedHash.isEmpty) {
        // TODO: Replace with proper logging (maybe debug level)
        return false; // No PIN set
      }

      final c = Crypt(storedHash);
      return c.match(enteredPin);
    } catch (e) {
      // Handle potential storage/hashing errors
      // TODO: Replace with proper logging
      return false;
    }
  }

  /// Deletes the stored PIN hash. Use with caution.
  Future<void> deletePin() async {
     try {
      await _secureStorage.delete(key: _pinStorageKey);
    } catch (e) {
      // Handle potential storage errors
      // TODO: Replace with proper logging
      rethrow;
    }
  }
}

/// Riverpod provider for the PinStorageService.
@riverpod
PinStorageService pinStorageService(Ref ref) {
  // Provide the actual FlutterSecureStorage instance
  // Consider providing FlutterSecureStorage itself via a provider if used elsewhere
  return PinStorageService(const FlutterSecureStorage());
} 