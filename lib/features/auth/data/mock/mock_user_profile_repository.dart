import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/auth/domain/repositories/i_user_profile_repository.dart';

/// In-memory fallback when Firestore is unavailable.
class MockUserProfileRepository implements IUserProfileRepository {
  final Map<String, UserProfile> _store = <String, UserProfile>{};

  @override
  Future<UserProfile?> getProfile(String uid) async {
    return _store[uid];
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    _store[profile.uid] = profile;
  }
}

