import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// ✅ OBLIGATOIRE : Stockage dans AppData (Windows)
Future<String> getDatabasePath() async {
  final dir = await getApplicationSupportDirectory();
  final path = join(dir.path, 'gestion_magasin.db');
  
  // 🔍 Log pour debug (safe en production)
  print('SQLite DB PATH => $path');
  
  return path;
}