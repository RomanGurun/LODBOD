import 'package:lodbod/core/utils/phone_number.dart';
import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/auth/domain/repositories/i_user_profile_repository.dart';

/// In-memory profile store used when the app runs without a backend and by
/// tests that do not care about MockAPI.
class MockUserProfileRepository implements IUserProfileRepository {
  final Map<String, UserProfile> _store = <String, UserProfile>{};

  @override
  Future<UserProfile?> getProfile(String uid) async {
    return _store[uid];
  }

  @override
  Future<UserProfile?> findByPhone(String phoneNumber) async {
    final wanted = PhoneNumber.nationalDigits(phoneNumber);
    if (wanted.isEmpty) return null;
    for (final profile in _store.values) {
      if (PhoneNumber.nationalDigits(profile.phone) == wanted) {
        return profile;
      }
    }
    return null;
  }

  @override
  Future<UserProfile> ensureProfile({
    required String uid,
    required String phoneNumber,
    String fullName = '',
    String email = '',
  }) async {
    final existing = _store[uid];
    if (existing != null) return existing;

    final now = DateTime.now();
    final profile = UserProfile(
      uid: uid,
      name: fullName.trim(),
      email: email.trim(),
      phone: phoneNumber.trim(),
      isPhoneVerified: false,
      createdAt: now,
      updatedAt: now,
    );
    _store[uid] = profile;
    return profile;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _store[profile.uid] = profile;
  }
}
