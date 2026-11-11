import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/core/utils/phone_number.dart';
import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/auth/domain/repositories/i_user_profile_repository.dart';

/// In-memory [IUserProfileRepository] that records calls so tests can assert
/// "retrieve instead of duplicate" and "update instead of create" behaviour.
class FakeUserProfileRepository implements IUserProfileRepository {
  FakeUserProfileRepository({Map<String, UserProfile>? profiles})
      : _store = <String, UserProfile>{...?profiles};

  final Map<String, UserProfile> _store;

  int getCalls = 0;
  int findCalls = 0;
  int ensureCalls = 0;
  int saveCalls = 0;

  /// When true every operation throws, modelling an unreachable MockAPI.
  bool failRequests = false;

  UserProfile? stored(String uid) => _store[uid];

  @override
  Future<UserProfile?> getProfile(String uid) async {
    getCalls += 1;
    _throwIfFailing();
    return _store[uid];
  }

  @override
  Future<UserProfile?> findByPhone(String phoneNumber) async {
    findCalls += 1;
    _throwIfFailing();
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
    ensureCalls += 1;
    _throwIfFailing();

    final existing = _store[uid];
    if (existing != null) return existing;

    final now = DateTime.utc(2026, 1, 1);
    final profile = UserProfile(
      uid: uid,
      name: fullName.trim(),
      email: email.trim(),
      phone: phoneNumber.trim(),
      role: UserProfile.roleShipper,
      isPhoneVerified: false,
      createdAt: now,
      updatedAt: now,
    );
    _store[uid] = profile;
    return profile;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    saveCalls += 1;
    _throwIfFailing();
    _store[profile.uid] = profile;
  }

  void _throwIfFailing() {
    if (failRequests) {
      throw const NetworkException('Profile API is unreachable in this test.');
    }
  }
}
