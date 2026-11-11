import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/auth/domain/repositories/i_user_profile_repository.dart';

/// Remote-first user profile repository with an in-memory fallback.
///
/// The fallback activates only when the remote call fails (for example no
/// network), mirroring the shipment data source strategy. A profile saved
/// while the fallback is active lives only for the current session — it is
/// never reported as remotely stored.
class ResilientUserProfileRepository implements IUserProfileRepository {
  ResilientUserProfileRepository(
      {required this.remote, required this.fallback});

  final IUserProfileRepository remote;
  final IUserProfileRepository fallback;

  bool _usingFallback = false;

  /// Whether profile persistence currently runs against the in-memory store.
  bool get usingFallback => _usingFallback;

  @override
  Future<UserProfile?> getProfile(String uid) async {
    if (_usingFallback) return fallback.getProfile(uid);
    try {
      return await remote.getProfile(uid);
    } on Exception {
      _usingFallback = true;
      return fallback.getProfile(uid);
    }
  }

  @override
  Future<UserProfile?> findByPhone(String phoneNumber) async {
    if (_usingFallback) return fallback.findByPhone(phoneNumber);
    try {
      return await remote.findByPhone(phoneNumber);
    } on Exception {
      _usingFallback = true;
      return fallback.findByPhone(phoneNumber);
    }
  }

  @override
  Future<UserProfile> ensureProfile({
    required String uid,
    required String phoneNumber,
    String fullName = '',
    String email = '',
  }) async {
    if (_usingFallback) {
      return fallback.ensureProfile(
        uid: uid,
        phoneNumber: phoneNumber,
        fullName: fullName,
        email: email,
      );
    }
    try {
      return await remote.ensureProfile(
        uid: uid,
        phoneNumber: phoneNumber,
        fullName: fullName,
        email: email,
      );
    } on Exception {
      _usingFallback = true;
      return fallback.ensureProfile(
        uid: uid,
        phoneNumber: phoneNumber,
        fullName: fullName,
        email: email,
      );
    }
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    if (_usingFallback) {
      await fallback.saveProfile(profile);
      return;
    }
    try {
      await remote.saveProfile(profile);
    } on Exception {
      _usingFallback = true;
      await fallback.saveProfile(profile);
    }
  }
}
