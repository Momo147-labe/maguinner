import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'GNF',
    decimalDigits: 0,
  );
  
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }
  
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }
  
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }
  
  static String formatNumber(num number) {
    return NumberFormat('#,##0', 'fr_FR').format(number);
  }
  
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }
}