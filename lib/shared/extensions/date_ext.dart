import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  String formatDisplay() => DateFormat('dd MMM yyyy').format(this);

  String formatWithTime() => DateFormat('dd MMM yyyy, HH:mm').format(this);

  String formatShort() => DateFormat('dd MMM').format(this);

  String formatShortWithTime() => DateFormat('dd MMM, HH:mm').format(this);

  String timeAgo() {
    final difference = DateTime.now().difference(this);
    if (difference.inSeconds < 45) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return formatShort();
  }

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
