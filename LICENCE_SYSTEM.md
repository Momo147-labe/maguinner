# 🔐 Système de Licence - Documentation

## Vue d'ensemble

Le système de licence garantit qu'une licence = 1 machine uniquement, avec persistance SQLite locale et vérification backend obligatoire.

## 🏗️ Architecture

```
lib/
├─ services/
│   └─ license_service.dart      # Service principal de licence
├─ models/
│   └─ app_settings.dart         # Modèle avec champs licence
├─ core/database/
│   └─ database_helper.dart      # Méthodes SQLite pour licence
├─ screens/
│   ├─ license_screen.dart       # Écran d'activation
│   └─ login_screen.dart         # Vérification licence avant login
```

## 🔒 Règles Métier (STRICTES)

### ✅ Autorisé
- Licence valide + même PC → OK
- Licence activée sur la même machine → OK

### ❌ Interdit
- Licence valide + autre PC → REFUS
- Licence invalide → REFUS
- Backend down → BLOQUER
- Licence non stockée → BLOQUER
- Continuer sans SQLite → BLOQUER

## 🧩 Composants Principaux

### 1. Génération Device ID
```dart
Future<String> generateDeviceId() async {
  if (Platform.isWindows) {
    final win = await info.windowsInfo;
    return 'WIN-${win.computerName}-${win.numberOfCores}';
  }
  if (Platform.isLinux) {
    final linux = await info.linuxInfo;
    return 'LINUX-${linux.machineId}';
  }
  return 'UNKNOWN-${DateTime.now().millisecondsSinceEpoch}';
}
```

### 2. Activation Licence
```dart
static Future<bool> activate(String key) async {
  final deviceId = await generateDeviceId();
  
  final response = await http.post(
    Uri.parse(_url),
    body: jsonEncode({
      'license_key': key.trim(),
      'device_id': deviceId,
    }),
  );
  
  if (response.statusCode == 200 && data['success'] == true) {
    await DatabaseHelper.instance.saveLicense(key.trim());
    return true;
  }
  
  throw Exception(data['message'] ?? 'Licence invalide');
}
```

### 3. Stockage SQLite
```sql
CREATE TABLE app_settings (
  id INTEGER PRIMARY KEY,
  license TEXT,
  activated_at TEXT,
  first_launch_done INTEGER DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

### 4. Logique de Démarrage
```dart
Future<String> _resolveInitialRoute() async {
  final hasLicense = await LicenseService.hasValidLicense();
  
  if (hasLicense) {
    final hasUsers = await _hasUsers();
    return hasUsers ? '/login' : '/first-launch';
  } else {
    return '/license';
  }
}
```

## 🔄 Flux d'Utilisation

### Premier Démarrage
1. App démarre → Vérifie licence SQLite
2. Pas de licence → Écran d'activation
3. Utilisateur saisit clé → Envoi backend
4. Backend valide → Sauvegarde SQLite
5. Redirection → Login/Setup

### Démarrage Normal
1. App démarre → Vérifie licence SQLite
2. Licence trouvée → Vérifie utilisateurs
3. Utilisateurs existent → Login
4. Pas d'utilisateurs → Setup

### Connexion
1. Utilisateur se connecte → Vérifie licence
2. Pas de licence → Redirection activation
3. Licence OK → Connexion normale

## 🛡️ Sécurité

### Points de Contrôle
- ✅ Démarrage app
- ✅ Avant connexion
- ✅ Accès routes sécurisées
- ✅ Désactivation admin

### Logs de Debug
```dart
debugPrint('DEVICE ID => $deviceId');
debugPrint('LICENSE SAVED => $license');
debugPrint('LICENSE CHECK => $isValid');
```

## 🚫 Interdictions Absolues

❌ **JAMAIS** continuer après réponse backend sans SQLite
❌ **JAMAIS** ignorer device_id
❌ **JAMAIS** licence en mémoire uniquement
❌ **JAMAIS** licence test en production
❌ **JAMAIS** bypass offline
❌ **JAMAIS** accepter licence active ailleurs

## 🔧 Configuration Backend

### Endpoint d'Activation
```
POST https://magasinlicence.onrender.com/api/license/activate
Content-Type: application/json

{
  "license_key": "XXXX-XXXX-XXXX-XXXX",
  "device_id": "WIN-DESKTOP-PC-8"
}
```

### Réponses Attendues
```json
// Succès
{
  "success": true,
  "message": "Licence activée avec succès"
}

// Échec
{
  "success": false,
  "message": "Licence déjà utilisée sur un autre appareil"
}
```

## 🎯 Fonctionnalités Bonus

### Désactivation Licence (Admin)
- Accessible via sidebar (admins uniquement)
- Confirmation obligatoire
- Suppression SQLite + redirection

### Migration Future
- Historique activations
- Vérification périodique
- Gestion multi-licences

## 🔐 Règle Finale

**SI LA LICENCE N'EST PAS DANS SQLITE → ELLE N'EXISTE PAS**

Cette règle garantit la sécurité et la fiabilité du système.