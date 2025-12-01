import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      final value = amount / 1000000000;
      // Untuk milyar, tampilkan sampai 2 desimal jika ada
      if (value % 1 == 0) {
        return 'Rp ${value.toStringAsFixed(0)}M';
      } else if ((value * 10) % 1 == 0) {
        return 'Rp ${value.toStringAsFixed(1)}M';
      } else {
        return 'Rp ${value.toStringAsFixed(2)}M';
      }
    } else if (amount >= 1000000) {
      final value = amount / 1000000;
      // Untuk jutaan, tampilkan sampai 2 desimal jika ada
      if (value % 1 == 0) {
        return 'Rp ${value.toStringAsFixed(0)}jt';
      } else if ((value * 10) % 1 == 0) {
        return 'Rp ${value.toStringAsFixed(1)}jt';
      } else {
        return 'Rp ${value.toStringAsFixed(2)}jt';
      }
    } else if (amount >= 1000) {
      final value = amount / 1000;
      // Untuk ribuan, tampilkan sampai 2 desimal jika ada
      if (value % 1 == 0) {
        return 'Rp ${value.toStringAsFixed(0)}rb';
      } else if ((value * 10) % 1 == 0) {
        return 'Rp ${value.toStringAsFixed(1)}rb';
      } else {
        return 'Rp ${value.toStringAsFixed(2)}rb';
      }
    }
    return format(amount);
  }
}
