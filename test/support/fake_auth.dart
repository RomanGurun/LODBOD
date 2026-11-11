import 'dart:async';

import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/auth/domain/entities/auth_user.dart';
import 'package:lodbod/features/auth/domain/entities/phone_verification.dart';
import 'package:lodbod/features/auth/domain/repositories/i_auth_repository.dart';

/// Test double for [IAuthRepository] that starts signed in as [user].
///
/// Defaults to the demo owner (`demo-1`) that owns the seeded sample
/// shipments, matching [ShipmentOwnership.demoOwnerUid]. Use
/// [FakeAuthRepository.signedOut] to model an unauthenticated session.
class FakeAuthRepository implements IAuthRepository {
  FakeAuthRepository({AuthUser? user}) : _user = user ?? demoOwner;

  FakeAuthRepository.signedOut() : _user = null;

  static const AuthUser demoOwner = AuthUser(
    id: 'demo-1',
    email: 'demo@lodbod.com',
    displayName: 'Aarav Shrestha',
  );

  /// Code accepted by [verifyPhoneOtp]. Test-only value; production code must
  /// never contain a hardcoded OTP.
  static const String validTestCode = '123456';

  AuthUser? _user;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  String? _verificationId;
  String? lastPhoneNumber;
  int? lastResendToken;
  int resendCount = 0;

  /// Credentials attached after phone verification in the registration flow.
  String? linkedPassword;
  String? linkedPhoneNumber;
  String? linkedEmail;
  String? linkedDisplayName;

  /// When true the next [requestPhoneVerification] behaves like Android
  /// auto-retrieval and signs the user in immediately.
  bool autoVerifyNext = false;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    if (_user == null) {
      throw const AuthException('No user signed in to the fake repository.');
    }
    return _user!;
  }

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _user = AuthUser(id: 'new-uid', email: email, displayName: displayName);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<PhoneVerification> requestPhoneVerification({
    required String phoneNumber,
    int? resendToken,
    String? linkPassword,
    String? linkEmail,
    String? linkDisplayName,
  }) async {
    lastPhoneNumber = phoneNumber;
    if (resendToken != null) {
      resendCount += 1;
      lastResendToken = resendToken;
    }

    if (autoVerifyNext) {
      autoVerifyNext = false;
      linkedPassword = linkPassword;
      linkedEmail = linkEmail;
      linkedDisplayName = linkDisplayName;
      linkedPhoneNumber = linkPassword == null ? null : phoneNumber;
      final user = AuthUser(
        id: 'phone-uid',
        email: linkEmail ?? '',
        displayName: linkDisplayName ?? '',
        phoneNumber: phoneNumber,
      );
      _setUser(user);
      return PhoneVerification(autoVerifiedUser: user);
    }

    _verificationId = 'test-verification-$phoneNumber';
    return PhoneVerification(
      verificationId: _verificationId,
      resendToken: 42,
    );
  }

  @override
  Future<AuthUser> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? linkPassword,
    String? linkEmail,
    String? linkDisplayName,
  }) async {
    if (_verificationId == null || verificationId != _verificationId) {
      throw const AuthException(
        'This verification has expired. Request a new code.',
      );
    }
    if (smsCode != validTestCode) {
      throw const AuthException(
          'That code is incorrect. Check it and try again.');
    }
    linkedPassword = linkPassword;
    linkedEmail = linkEmail;
    linkedDisplayName = linkDisplayName;
    linkedPhoneNumber = linkPassword == null ? null : lastPhoneNumber;
    final user = AuthUser(
      id: 'phone-uid',
      email: linkEmail ?? '',
      displayName: linkDisplayName ?? '',
      phoneNumber: lastPhoneNumber ?? '',
    );
    _setUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  void _setUser(AuthUser? user) {
    _user = user;
    _controller.add(user);
  }
}
