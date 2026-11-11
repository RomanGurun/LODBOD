import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/utils/phone_number.dart';

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

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
      return AppStrings.invalidPhone;
    }
    return null;
  }

  /// Nepal mobile number for the phone-login tab: 10 digits starting with 9.
  static String? nepalMobile(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    if (!PhoneNumber.isValidNepalMobile(value)) {
      return AppStrings.invalidNepalPhone;
    }
    return null;
  }

  /// Six-digit SMS OTP.
  static String? otpCode(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'Enter the 6-digit code';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value.length < 6) return AppStrings.passwordTooShort;
    return null;
  }

  /// Confirm-password validator: both fields must match exactly.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return AppStrings.fieldRequired;
    if (value != password) return AppStrings.passwordMismatch;
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
