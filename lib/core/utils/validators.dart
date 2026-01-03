class Validators {
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    return null;
  }
  
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Adresse email invalide';
    }
    return null;
  }
  
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final phoneRegex = RegExp(r'^\+?[0-9\s\-\(\)]{8,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }
  
  static String? minLength(String? value, int minLength, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length < minLength) {
      return '${fieldName ?? 'Ce champ'} doit contenir au moins $minLength caractères';
    }
    return null;
  }
  
  static String? maxLength(String? value, int maxLength, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length > maxLength) {
      return '${fieldName ?? 'Ce champ'} ne peut pas dépasser $maxLength caractères';
    }
    return null;
  }
  
  static String? positiveNumber(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    
    final number = double.tryParse(value);
    if (number == null) {
      return '${fieldName ?? 'Ce champ'} doit être un nombre valide';
    }
    
    if (number < 0) {
      return '${fieldName ?? 'Ce champ'} doit être positif';
    }
    return null;
  }
  
  static String? positiveInteger(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) return null;
    
    final number = int.tryParse(value);
    if (number == null) {
      return '${fieldName ?? 'Ce champ'} doit être un nombre entier valide';
    }
    
    if (number < 0) {
      return '${fieldName ?? 'Ce champ'} doit être positif';
    }
    return null;
  }
  
  static String? barcode(String? value) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length < 8 || value.length > 13) {
      return 'Le code-barres doit contenir entre 8 et 13 chiffres';
    }
    
    final barcodeRegex = RegExp(r'^\d+$');
    if (!barcodeRegex.hasMatch(value)) {
      return 'Le code-barres ne doit contenir que des chiffres';
    }
    return null;
  }
  
  static String? Function(String?) combine(List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}