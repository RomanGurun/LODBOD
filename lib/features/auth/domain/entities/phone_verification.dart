import 'package:lodbod/features/auth/domain/entities/auth_user.dart';

/// Result of asking Firebase to verify a phone number.
///
/// Exactly one of [verificationId] (an SMS code is on its way) or
/// [autoVerifiedUser] (Android auto-retrieval completed the sign-in) is set.
/// The verification ID is a short-lived Firebase token; it is never persisted
/// to MockAPI, local storage or the user profile.
class PhoneVerification {
  const PhoneVerification({
    this.verificationId,
    this.resendToken,
    this.autoVerifiedUser,
  });

  final String? verificationId;
  final int? resendToken;
  final AuthUser? autoVerifiedUser;

  bool get isAutoVerified => autoVerifiedUser != null;
}
