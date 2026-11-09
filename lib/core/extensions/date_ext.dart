import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  String formatDisplay() => DateFormat('dd MMM yyyy').format(this);

  String formatWithTime() => DateFormat('dd MMM yyyy, HH:mm').format(this);

  String formatShort() => DateFormat('dd MMM').format(this);

  String formatApi() => toIso8601String();

  bool get isPast => isBefore(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  String get relativeLabel {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return formatDisplay();
  }
}
