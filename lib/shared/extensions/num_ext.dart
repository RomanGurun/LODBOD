import 'package:intl/intl.dart';

extension NumExt on num {
  String toNPR() {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs. ',
      decimalDigits: 0,
    );
    return formatter.format(this);
  }

  String toWeight(String unit) =>
      '${toStringAsFixed(toInt() == this ? 0 : 1)} $unit';

  String toRating() => toStringAsFixed(1);
}
