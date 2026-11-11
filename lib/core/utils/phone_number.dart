/// Nepal-focused phone number helpers.
///
/// The UI always shows the `+977` country code, but users may type the number
/// with spaces, a leading `0`, or even include `977` themselves. Everything
/// normalises to E.164 before it reaches Firebase.
class PhoneNumber {
  PhoneNumber._();

  static const String nepalDialCode = '+977';

  /// Internal domain for the Firebase email/password credential that gives a
  /// phone account a password. These addresses are never inboxes and are not
  /// shown to the user; Firebase only needs a unique, stable identifier.
  static const String phoneAccountDomain = 'phone.lodbod.app';

  /// Deterministic Firebase email for a phone account, e.g.
  /// `+9779812345678` → `phone9779812345678@phone.lodbod.app`.
  static String accountEmail(String raw) {
    // Normalise first so `981…`, `0981…` and `+977981…` map to one account.
    final digits = toE164(raw).replaceAll(RegExp(r'[^0-9]'), '');
    return 'phone$digits@$phoneAccountDomain';
  }

  /// True when [email] is an internal phone-account alias rather than a real
  /// address the user typed. Aliases must never be shown in the UI or saved to
  /// the MockAPI profile.
  static bool isAccountEmail(String email) {
    return email.trim().toLowerCase().endsWith('@$phoneAccountDomain');
  }

  /// Nepal mobile numbers are ten digits and start with 9.
  static bool isValidNepalMobile(String raw) {
    return RegExp(r'^9\d{9}$').hasMatch(nationalDigits(raw));
  }

  /// Strips formatting and an optional country/trunk prefix.
  static String nationalDigits(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('977') && digits.length > 10) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0') && digits.length > 10) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// Normalises to E.164 with the Nepal dial code.
  static String toE164(String raw) => '$nepalDialCode${nationalDigits(raw)}';

  /// `+977 98******78` — enough for the user to recognise the number without
  /// printing the whole thing on screen.
  static String mask(String raw) {
    final digits = nationalDigits(raw);
    if (digits.length < 4) return raw;
    final start = digits.substring(0, 2);
    final end = digits.substring(digits.length - 2);
    return '$nepalDialCode $start******$end';
  }
}
