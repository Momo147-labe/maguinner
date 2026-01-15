import 'package:intl/intl.dart';

/// Utilitaire pour formater les montants en GNF (Franc Guinéen)
class CurrencyFormatter {
  static final NumberFormat _gnfFormatter = NumberFormat.currency(
    locale: 'fr_GN',
    symbol: 'GNF',
    decimalDigits: 0,
  );

  /// Formate un montant en GNF
  static String formatGNF(double? amount) {
    if (amount == null) return '0 GNF';
    return _gnfFormatter.format(amount);
  }
}