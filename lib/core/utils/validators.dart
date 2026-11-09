import '../constants/app_strings.dart';

class Validators {
  Validators._();

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(value.trim())) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  static String? emailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final v = value.trim();
    if (v.contains('@')) {
      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(v)) {
        return AppStrings.invalidEmail;
      }
    } else {
      if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) {
        return AppStrings.invalidPhone;
      }
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value.length < 6) return AppStrings.passwordTooShort;
    return null;
  }

  static String? weight(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    final n = double.tryParse(value.trim());
    if (n == null || n <= 0) return AppStrings.invalidWeight;
    return null;
  }

  static String? pickupDate(DateTime? date) {
    if (date == null) return AppStrings.fieldRequired;
    if (date.isBefore(DateTime.now().subtract(const Duration(hours: 1)))) {
      return AppStrings.pastDateError;
    }
    return null;
  }

  static String? sameLocation(String? pickup, String? destination) {
    if (pickup == null || destination == null) return null;
    if (pickup.trim().toLowerCase() == destination.trim().toLowerCase()) {
      return AppStrings.sameLocationError;
    }
    return null;
  }
}
