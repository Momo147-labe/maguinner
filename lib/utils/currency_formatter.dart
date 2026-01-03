import 'package:intl/intl.dart';

/// Utilitaire pour le formatage monétaire en GNF
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'fr_FR');
  
  /// Formate un montant en GNF avec séparateur de milliers
  static String formatGNF(double amount) {
    return '${_formatter.format(amount)} GNF';
  }
  
  /// Formate un montant en GNF sans décimales
  static String formatGNFInt(int amount) {
    return '${_formatter.format(amount)} GNF';
  }
  
  /// Formate un montant avec séparateur de milliers seulement
  static String formatNumber(double amount) {
    return _formatter.format(amount);
  }
}