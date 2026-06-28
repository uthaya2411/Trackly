import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats a double value into a beautiful currency string.
  /// Example: 12500.50 with '$' -> "$12,500.50"
  static String format(double amount, {required String symbol}) {
    final isNegative = amount < 0;
    final absoluteAmount = amount.abs();

    // Setup standard double decimal formatting
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
      customPattern: symbol == '₹' ? '¤##,##,##0.00' : '¤#,##0.00',
    );

    final formatted = formatter.format(absoluteAmount);
    return isNegative ? '-$formatted' : formatted;
  }

  /// Formats large currency numbers into compact values.
  /// Example: 1,500,000 -> "$1.5M"
  static String formatCompact(double amount, {required String symbol}) {
    final isNegative = amount < 0;
    final absoluteAmount = amount.abs();

    final formatter = NumberFormat.compactSimpleCurrency(
      name: _getCurrencyCode(symbol),
    );

    // Fallback if compact fails or symbol doesn't have direct simple compact name
    try {
      final formatted = formatter.format(absoluteAmount);
      return isNegative ? '-$formatted' : formatted;
    } catch (_) {
      // Manual compact formatting as fallback
      if (absoluteAmount >= 1000000) {
        return '${isNegative ? '-' : ''}$symbol${(absoluteAmount / 1000000).toStringAsFixed(1)}M';
      } else if (absoluteAmount >= 1000) {
        return '${isNegative ? '-' : ''}$symbol${(absoluteAmount / 1000).toStringAsFixed(1)}K';
      }
      return format(amount, symbol: symbol);
    }
  }

  static String _getCurrencyCode(String symbol) {
    switch (symbol) {
      case '€':
        return 'EUR';
      case '£':
        return 'GBP';
      case '₹':
        return 'INR';
      case '¥':
        return 'JPY';
      case '\$':
      default:
        return 'USD';
    }
  }
}
