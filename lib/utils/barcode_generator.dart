import 'dart:math';

class BarcodeGenerator {
  /// Génère un code-barres automatique basé sur les informations du produit
  static String generateBarcode(String productName, String? category) {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Préfixe basé sur la catégorie (2 chiffres)
    String categoryPrefix = '00';
    if (category != null && category.isNotEmpty) {
      categoryPrefix = category.hashCode.abs().toString().padLeft(2, '0').substring(0, 2);
    }
    
    // Code produit basé sur le nom (4 chiffres)
    String productCode = productName.hashCode.abs().toString().padLeft(4, '0').substring(0, 4);
    
    // Timestamp tronqué (4 chiffres)
    String timeCode = (timestamp % 10000).toString().padLeft(4, '0');
    
    // Nombre aléatoire (2 chiffres)
    String randomCode = random.nextInt(100).toString().padLeft(2, '0');
    
    // Format: CCPPPPTTTRR (12 chiffres)
    return categoryPrefix + productCode + timeCode + randomCode;
  }
  
  /// Vérifie si un code-barres est valide (12 chiffres)
  static bool isValidBarcode(String barcode) {
    return RegExp(r'^\d{12}$').hasMatch(barcode);
  }
}