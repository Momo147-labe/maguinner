import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_moderne_magasin/services/license_service.dart';
import 'package:gestion_moderne_magasin/core/database/database_helper.dart';

void main() {
  group('License System Tests - STRICT LOGIC', () {
    
    test('Device ID generation should be stable and unique', () async {
      final deviceId1 = await LicenseService.generateDeviceId();
      final deviceId2 = await LicenseService.generateDeviceId();
      
      expect(deviceId1, equals(deviceId2));
      expect(deviceId1.isNotEmpty, true);
      expect(deviceId1.contains('-'), true); // Format validation
      print('Generated Device ID: $deviceId1');
    });

    test('License validation should follow GOLDEN RULE', () async {
      // 🔒 Test initial state (no license)
      final hasLicenseInitial = await LicenseService.hasValidLicense();
      expect(hasLicenseInitial, false);
      
      // 🔒 Test after saving license directly to SQLite
      await DatabaseHelper.instance.saveLicense('TEST-LICENSE-KEY');
      final hasLicenseAfter = await LicenseService.hasValidLicense();
      expect(hasLicenseAfter, true);
      
      // 🔒 Test license retrieval
      final license = await LicenseService.getCurrentLicense();
      expect(license, 'TEST-LICENSE-KEY');
      
      // 🔒 Test deactivation (GOLDEN RULE)
      await LicenseService.deactivate();
      final hasLicenseAfterDeactivate = await LicenseService.hasValidLicense();
      expect(hasLicenseAfterDeactivate, false);
    });

    test('Database license methods should be bulletproof', () async {
      // Clear any existing license
      await DatabaseHelper.instance.clearLicense();
      
      // 🔒 Test no license (GOLDEN RULE)
      final noLicense = await DatabaseHelper.instance.getLicense();
      expect(noLicense, null);
      
      // 🔒 Test save license
      await DatabaseHelper.instance.saveLicense('TEST-KEY-123');
      final savedLicense = await DatabaseHelper.instance.getLicense();
      expect(savedLicense, 'TEST-KEY-123');
      
      // 🔒 Test clear license (back to GOLDEN RULE)
      await DatabaseHelper.instance.clearLicense();
      final clearedLicense = await DatabaseHelper.instance.getLicense();
      expect(clearedLicense, null);
    });

    test('LicenseResult should handle all cases correctly', () {
      // Test success result
      final successResult = LicenseResult.success('Licence activée');
      expect(successResult.isSuccess, true);
      expect(successResult.message, 'Licence activée');
      
      // Test error result
      final errorResult = LicenseResult.error('Licence déjà utilisée ailleurs');
      expect(errorResult.isSuccess, false);
      expect(errorResult.message, 'Licence déjà utilisée ailleurs');
    });
  });
}