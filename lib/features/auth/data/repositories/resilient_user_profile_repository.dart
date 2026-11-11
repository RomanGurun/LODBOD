import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/auth/domain/repositories/i_user_profile_repository.dart';

/// Remote-first user profile repository with an in-memory fallback.
///
/// Firestore is always attempted first. The fallback activates only when
/// the remote call fails (for example no network), mirroring the shipment
/// data source strategy. A profile saved while the fallback is active lives
/// only for the current session — it is never reported as remotely stored.
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
