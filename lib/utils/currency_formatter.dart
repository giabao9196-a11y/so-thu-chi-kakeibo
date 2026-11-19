import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _vnFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final NumberFormat _numberOnlyFormat = NumberFormat.decimalPattern('vi_VN');

  static String format(double amount) {
    return _vnFormat.format(amount);
  }

  static String formatNumber(double amount) {
    return _numberOnlyFormat.format(amount);
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      return '${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 1)}tr';
    } else if (amount >= 1000) {
      final k = amount / 1000;
      return '${k.toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }
}
