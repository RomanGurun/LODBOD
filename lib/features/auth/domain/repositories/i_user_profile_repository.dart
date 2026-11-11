import 'package:lodbod/features/auth/domain/entities/user_profile.dart';

/// Abstract interface for user profile persistence.
abstract class IUserProfileRepository {
  /// Get the profile for the given Firebase UID. Returns null if not found.
  Future<UserProfile?> getProfile(String uid);

  /// Create or update a user profile.
  Future<void> saveProfile(UserProfile profile);
}
