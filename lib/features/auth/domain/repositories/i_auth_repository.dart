import 'package:lodbod/features/auth/domain/entities/auth_user.dart';
import 'package:lodbod/features/auth/domain/entities/phone_verification.dart';

abstract class IAuthRepository {
  AuthUser? get currentUser;

  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signIn({required String email, required String password});

  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sends a verification email link to the current authenticated user.
  Future<void> sendEmailVerification();

  /// Refreshes the current authenticated user's state (e.g. checking if email
  /// verification link was clicked).
  Future<AuthUser> reloadUser();

  Future<void> sendPasswordResetEmail(String email);

  /// Asks Firebase to send an SMS OTP to [phoneNumber] (E.164, e.g.
  /// `+9779812345678`).
  ///
  /// On Android the platform may verify the number automatically, in which
  /// case the result carries [PhoneVerification.autoVerifiedUser] and no code
  /// entry is needed. Errors are surfaced as `AuthException` values with
  /// user-readable messages.
  Future<PhoneVerification> requestPhoneVerification({
    required String phoneNumber,
    int? resendToken,
  });

  /// Completes phone sign-in with the Firebase [verificationId] and the SMS
  /// code the user typed. The code is verified by Firebase, never locally.
  Future<AuthUser> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Signs into the email/password account on a secondary Firebase app and
  /// sends an SMS OTP that will link [phoneNumber] to that same account.
  ///
  /// Phone login uses this after registration created the account by email, so
  /// the verified phone is attached to the existing UID instead of creating a
  /// second phone-only user. The secondary session stays open only until the
  /// code is linked or the flow is cancelled; the main auth session is not
  /// touched until [verifyPhoneLink] succeeds.
  Future<PhoneVerification> requestPhoneLink({
    required String phoneNumber,
    required String email,
    required String password,
    int? resendToken,
  });

  /// Completes [requestPhoneLink] by linking the verified phone to the email
  /// account, then signing that account into the main Firebase app.
  Future<AuthUser> verifyPhoneLink({
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
    required String email,
    required String password,
  });

  /// Abandons a pending phone link and signs the secondary app out.
  Future<void> cancelPhoneLink();

  /// Deletes the currently authenticated user from auth backend.
  Future<void> deleteCurrentUser();

  Future<void> signOut();
}
