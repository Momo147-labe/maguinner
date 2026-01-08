import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import '../core/database/database_helper.dart';

class LicenseService {
  static const _url = 'https://magasinlicence.onrender.com/api/license/activate';
  static const _timeout = Duration(seconds: 30);

  /// Génère un ID unique pour l'appareil (Desktop Safe)
  static Future<String> generateDeviceId() async {
    final info = DeviceInfoPlugin();

    if (Platform.isWindows) {
      final win = await info.windowsInfo;
      final deviceId = 'WIN-${win.computerName}-${win.numberOfCores}';
      debugPrint('DEVICE ID => $deviceId');
      return deviceId;
    }

    if (Platform.isLinux) {
      final linux = await info.linuxInfo;
      final deviceId = 'LINUX-${linux.machineId}';
      debugPrint('DEVICE ID => $deviceId');
      return deviceId;
    }

    final deviceId = 'UNKNOWN-${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('DEVICE ID => $deviceId');
    return deviceId;
  }

  /// Active une licence avec le backend (LOGIQUE STRICTE)
  static Future<LicenseResult> activate(String key) async {
    try {
      final deviceId = await generateDeviceId();
      debugPrint('ACTIVATING LICENSE => Key: ${key.trim()}, Device: $deviceId');

      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'license_key': key.trim(),
          'device_id': deviceId,
        }),
      ).timeout(_timeout);

      debugPrint('BACKEND RESPONSE => Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode != 200) {
        return LicenseResult.error('Erreur serveur (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final success = data['success'] as bool?;
      final message = data['message'] as String? ?? 'Réponse invalide';

      // 🔒 LOGIQUE STRICTE : Seules 2 réponses autorisées
      if (success == true && 
          (message == 'Licence activée' || message == 'Licence déjà activée')) {
        
        // ✅ OBLIGATOIRE : Sauvegarder en SQLite
        await DatabaseHelper.instance.saveLicense(key.trim());
        debugPrint('LICENSE SAVED => ${key.trim()}');
        
        return LicenseResult.success(message);
      }

      // ❌ TOUTE AUTRE RÉPONSE = REFUS
      debugPrint('LICENSE REJECTED => Success: $success, Message: $message');
      return LicenseResult.error(message);
      
    } on SocketException {
      return LicenseResult.error('Impossible de vérifier la licence. Vérifiez votre connexion internet.');
    } on TimeoutException {
      return LicenseResult.error('Impossible de vérifier la licence. Vérifiez votre connexion internet.');
    } catch (e) {
      debugPrint('LICENSE ERROR => $e');
      return LicenseResult.error('Impossible de vérifier la licence. Vérifiez votre connexion internet.');
    }
  }

  /// Vérifie si une licence valide existe en local (RÈGLE D'OR)
  static Future<bool> hasValidLicense() async {
    try {
      final license = await DatabaseHelper.instance.getLicense();
      final isValid = license != null && license.isNotEmpty;
      debugPrint('LICENSE CHECK => $isValid (license: $license)');
      return isValid;
    } catch (e) {
      debugPrint('LICENSE CHECK ERROR => $e');
      return false;
    }
  }

  /// Récupère la licence stockée
  static Future<String?> getCurrentLicense() async {
    try {
      return await DatabaseHelper.instance.getLicense();
    } catch (e) {
      debugPrint('GET LICENSE ERROR => $e');
      return null;
    }
  }

  /// Désactive la licence
  static Future<void> deactivate() async {
    try {
      await DatabaseHelper.instance.clearLicense();
      debugPrint('LICENSE CLEARED');
    } catch (e) {
      debugPrint('LICENSE CLEAR ERROR => $e');
    }
  }
}

/// Résultat de l'activation de licence
class LicenseResult {
  final bool isSuccess;
  final String message;

  LicenseResult._(this.isSuccess, this.message);

  factory LicenseResult.success(String message) => LicenseResult._(true, message);
  factory LicenseResult.error(String message) => LicenseResult._(false, message);
}