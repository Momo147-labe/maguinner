# 🔐 Système de Licence - Résumé des Modifications

## ✅ Fichiers Créés

### 1. Service de Licence
- **`lib/services/license_service.dart`**
  - Génération Device ID (Windows/Linux)
  - Activation licence avec backend
  - Vérification licence locale
  - Désactivation licence

### 2. Écran d'Activation
- **`lib/screens/license_screen.dart`**
  - Interface moderne d'activation
  - Validation backend obligatoire
  - Gestion des erreurs
  - Redirection automatique

### 3. Documentation
- **`LICENCE_SYSTEM.md`** - Documentation complète
- **`test/license_test.dart`** - Tests unitaires

## 🔄 Fichiers Modifiés

### 1. Dépendances
- **`pubspec.yaml`**
  - Ajout `http: ^1.1.0`
  - Ajout `device_info_plus: ^10.1.0`

### 2. Modèle de Données
- **`lib/models/app_settings.dart`**
  - Ajout champs `license` et `activatedAt`
  - Mise à jour méthodes `toMap()` et `fromMap()`

### 3. Base de Données
- **`lib/core/database/database_helper.dart`**
  - Mise à jour table `app_settings` (version 6)
  - Ajout méthodes `saveLicense()`, `getLicense()`, `clearLicense()`
  - Migration automatique des champs licence

### 4. Application Principale
- **`lib/main.dart`**
  - Nouvelle logique de démarrage basée sur licence
  - Route `/license` ajoutée
  - Vérification licence dans routes sécurisées
  - Méthode `_resolveInitialRoute()` remplace `_isFirstLaunch()`

### 5. Écran de Connexion
- **`lib/screens/login_screen.dart`**
  - Vérification licence obligatoire avant connexion
  - Redirection automatique si pas de licence

### 6. Interface Utilisateur
- **`lib/widgets/animated_sidebar.dart`**
  - Option "Désactiver licence" (admins uniquement)
  - Dialog de confirmation
  - Redirection après désactivation

## 🔒 Règles Implémentées

### ✅ Sécurité Stricte
1. **Une licence = 1 machine** ✓
2. **Licence active ailleurs = REFUS** ✓
3. **Licence activée sur même machine = OK** ✓
4. **Licence valide doit être en SQLite** ✓
5. **À chaque lancement : vérification licence** ✓
6. **Si licence valide → LOGIN, sinon → activation** ✓

### ✅ Fonctionnalités
1. **Device ID automatique côté app** ✓
2. **Backend seule autorité** ✓
3. **Aucune logique hardcodée** ✓
4. **Persistance SQLite obligatoire** ✓
5. **Logs de debug** ✓

## 🚀 Flux d'Utilisation

### Premier Démarrage
```
App Start → Check SQLite → No License → License Screen → 
User Input → Backend Validation → Save SQLite → Login Screen
```

### Démarrage Normal
```
App Start → Check SQLite → License Found → Check Users → 
Users Exist → Login Screen
```

### Connexion
```
Login Attempt → Check License → License Valid → 
Authenticate User → Dashboard
```

### Désactivation (Admin)
```
Admin Menu → Deactivate License → Confirm → 
Clear SQLite → License Screen
```

## 🛡️ Points de Sécurité

### Vérifications Multiples
- ✅ Au démarrage de l'app
- ✅ Avant chaque connexion
- ✅ Dans les routes sécurisées
- ✅ Lors de la désactivation

### Logs de Debug
```dart
debugPrint('DEVICE ID => $deviceId');
debugPrint('LICENSE SAVED => $license');
debugPrint('LICENSE CHECK => $isValid');
```

## 🔧 Configuration Backend

### Endpoint Requis
```
POST https://magasinlicence.onrender.com/api/license/activate
```

### Format Requête
```json
{
  "license_key": "XXXX-XXXX-XXXX-XXXX",
  "device_id": "WIN-COMPUTER-NAME-8"
}
```

### Réponses Attendues
```json
// Succès
{"success": true, "message": "Licence activée"}

// Échec
{"success": false, "message": "Licence déjà utilisée"}
```

## 🎯 Fonctionnalités Bonus

### Implémentées
- ✅ Désactivation licence (admin)
- ✅ Logs de debug
- ✅ Interface moderne
- ✅ Gestion d'erreurs

### Futures (Optionnelles)
- 🔄 Historique activations
- 🔄 Vérification périodique
- 🔄 Migration licence
- 🔄 Gestion multi-licences

## 🔐 Règle Finale Respectée

**SI LA LICENCE N'EST PAS DANS SQLITE → ELLE N'EXISTE PAS**

Le système garantit qu'aucune licence ne peut être validée uniquement en mémoire. Toute licence valide DOIT être persistée en SQLite après validation backend.

## 🧪 Tests

Exécuter les tests :
```bash
flutter test test/license_test.dart
```

Les tests vérifient :
- Génération stable du Device ID
- Validation des licences
- Méthodes de base de données
- Cycle complet activation/désactivation