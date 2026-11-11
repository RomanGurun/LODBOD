import 'package:lodbod/features/auth/domain/entities/user_profile.dart';

/// Abstract interface for user profile persistence.
abstract class IUserProfileRepository {
  /// Get the profile for the given Firebase UID. Returns null if not found.
  Future<UserProfile?> getProfile(String uid);

  /// Find the profile that owns [phoneNumber], regardless of formatting.
  ///
  /// Phone sign-in uses this to recover the email address linked to a number so
  /// the account password can be checked before an OTP is sent. Returns null
  /// when no profile matches.
  Future<UserProfile?> findByPhone(String phoneNumber);

  /// Returns the stored profile, creating a minimal one when the user has never
  /// completed their profile. Implementations must never create a second
  /// record for the same Firebase UID.
  Future<UserProfile> ensureProfile({
    required String uid,
    required String phoneNumber,
    String fullName = '',
    String email = '',
  });

  /// Create or update a user profile.
  Future<void> saveProfile(UserProfile profile);
}
