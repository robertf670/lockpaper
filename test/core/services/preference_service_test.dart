import 'package:flutter_test/flutter_test.dart';
import 'package:lockpaper/core/services/preference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Use SharedPreferences.setMockInitialValues to control the underlying data
  // Keys are defined in PreferenceService
  const String biometricsEnabledKey = 'biometrics_enabled';

  // No late variables needed as we use setMockInitialValues before each test potentially

  group('PreferenceService Tests', () {
    
    // Test default value (when key doesn't exist)
    test('isBiometricsEnabled returns true by default if key not set', () async {
      // Arrange: Ensure no initial value for the key
      SharedPreferences.setMockInitialValues({}); 
      final service = PreferenceService(await SharedPreferences.getInstance());

      // Act
      final result = service.isBiometricsEnabled();

      // Assert
      expect(result, isTrue);
    });

    // Test reading existing true value
    test('isBiometricsEnabled returns true when value is set to true', () async {
      // Arrange: Set initial value to true
      SharedPreferences.setMockInitialValues({biometricsEnabledKey: true}); 
      final service = PreferenceService(await SharedPreferences.getInstance());

      // Act
      final result = service.isBiometricsEnabled();

      // Assert
      expect(result, isTrue);
    });

    // Test reading existing false value
    test('isBiometricsEnabled returns false when value is set to false', () async {
      // Arrange: Set initial value to false
      SharedPreferences.setMockInitialValues({biometricsEnabledKey: false}); 
      final service = PreferenceService(await SharedPreferences.getInstance());

      // Act
      final result = service.isBiometricsEnabled();

      // Assert
      expect(result, isFalse);
    });

    // Test setting value to true
    test('setBiometricsEnabled(true) sets the value correctly', () async {
      // Arrange: Start with any state (e.g., empty)
      SharedPreferences.setMockInitialValues({}); 
      final prefs = await SharedPreferences.getInstance();
      final service = PreferenceService(prefs);

      // Act
      await service.setBiometricsEnabled(true);

      // Assert: Check the underlying SharedPreferences instance
      expect(prefs.getBool(biometricsEnabledKey), isTrue);
      // Also verify the service reads the new value correctly
      expect(service.isBiometricsEnabled(), isTrue);
    });

    // Test setting value to false
    test('setBiometricsEnabled(false) sets the value correctly', () async {
      // Arrange: Start with any state (e.g., true)
       SharedPreferences.setMockInitialValues({biometricsEnabledKey: true}); 
      final prefs = await SharedPreferences.getInstance();
      final service = PreferenceService(prefs);

      // Act
      await service.setBiometricsEnabled(false);

      // Assert: Check the underlying SharedPreferences instance
      expect(prefs.getBool(biometricsEnabledKey), isFalse);
       // Also verify the service reads the new value correctly
      expect(service.isBiometricsEnabled(), isFalse);
    });

  });
} 