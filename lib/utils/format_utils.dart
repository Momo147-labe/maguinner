import 'package:intl/intl.dart';
import 'constants.dart';

/// Utilitaires de formatage pour l'application
class FormatUtils {
  
  /// Formate un prix en euros
  static String formatPrice(double? price) {
    if (price == null) return '0,00 ${AppConstants.currencySymbol}';
    return '${price.toStringAsFixed(2).replaceAll('.', ',')} ${AppConstants.currencySymbol}';
  }
  
  /// Formate une quantité
  static String formatQuantity(int? quantity) {
    if (quantity == null) return '0';
    return quantity.toString();
  }
  
  /// Formate une date
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat(AppConstants.dateFormat).format(date);
    } catch (e) {
      return dateString;
    }
  }
  
  /// Formate une date et heure
  static String formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat(AppConstants.dateTimeFormat).format(date);
    } catch (e) {
      return dateString;
    }
  }
  
  /// Formate un pourcentage
  static String formatPercentage(double? percentage) {
    if (percentage == null) return '0%';
    return '${percentage.toStringAsFixed(1)}%';
  }
  
  /// Formate un numéro de téléphone
  static String formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    // Supprime tous les caractères non numériques
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length == 10) {
      // Format français: 06 12 34 56 78
      return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)} ${digits.substring(8, 10)}';
    }
    return phone; // Retourne le format original si pas 10 chiffres
  }
  
  /// Capitalise la première lettre
  static String capitalize(String? text) {
    if (text == null || text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  /// Formate un nom complet
  static String formatFullName(String? firstName, String? lastName) {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    
    if (first.isEmpty && last.isEmpty) return '';
    if (first.isEmpty) return capitalize(last);
    if (last.isEmpty) return capitalize(first);
    
    return '${capitalize(first)} ${capitalize(last)}';
  }
  
  /// Formate une adresse sur plusieurs lignes
  static String formatAddress(String? address) {
    if (address == null || address.isEmpty) return '';
    // Remplace les virgules par des retours à la ligne
    return address.replaceAll(', ', '\n');
  }
  
  /// Formate un code-barres
  static String formatBarcode(String? barcode) {
    if (barcode == null || barcode.isEmpty) return '';
    // Supprime les espaces et convertit en majuscules
    return barcode.replaceAll(' ', '').toUpperCase();
  }
  
  /// Formate un statut de stock
  static String formatStockStatus(int? quantity, int? threshold) {
    if (quantity == null || threshold == null) return 'Inconnu';
    
    if (quantity <= 0) return 'Rupture';
    if (quantity <= threshold) return 'Stock faible';
    return 'En stock';
  }
  
  /// Obtient la couleur du statut de stock
  static String getStockStatusColor(int? quantity, int? threshold) {
    if (quantity == null || threshold == null) return 'grey';
    
    if (quantity <= 0) return 'red';
    if (quantity <= threshold) return 'orange';
    return 'green';
  }
  
  /// Formate un nom de fichier avec timestamp
  static String formatFileName(String baseName, {String extension = 'txt'}) {
    final timestamp = DateFormat(AppConstants.exportDateFormat).format(DateTime.now());
    return '${baseName}_$timestamp.$extension';
  }
  
  /// Valide et formate un email
  static String? validateAndFormatEmail(String? email) {
    if (email == null || email.isEmpty) return null;
    
    final trimmed = email.trim().toLowerCase();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    
    if (emailRegex.hasMatch(trimmed)) {
      return trimmed;
    }
    return null;
  }
  
  /// Formate une durée en texte lisible
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} jour(s)';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} heure(s)';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute(s)';
    } else {
      return '${duration.inSeconds} seconde(s)';
    }
  }
  
  /// Formate un nombre avec séparateurs de milliers
  static String formatNumber(num? number) {
    if (number == null) return '0';
    return NumberFormat('#,##0', 'fr_FR').format(number);
  }
  
  /// Tronque un texte à une longueur donnée
  static String truncateText(String? text, int maxLength) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}