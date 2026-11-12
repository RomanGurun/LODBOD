import 'package:lodbod/features/auth/data/datasources/mock_api_user_profile_data_source.dart';
import 'package:lodbod/features/auth/data/models/user_profile_model.dart';
import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/auth/domain/repositories/i_user_profile_repository.dart';

/// MockAPI-backed profile store.
///
/// Lookups go through `firebaseUid`, so signing in again always resolves the
/// existing record instead of creating a duplicate. The MockAPI record id is
/// cached in memory only to make subsequent PATCHes cheap.
class MockApiUserProfileRepository implements IUserProfileRepository {
  MockApiUserProfileRepository({required MockApiUserProfileDataSource remote})
      : _remote = remote;

  final MockApiUserProfileDataSource _remote;
  final Map<String, String> _recordIds = <String, String>{};

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final model = await _remote.fetchByFirebaseUid(uid);
    if (model == null) return null;
    _remember(uid, model.recordId);
    return model.toEntity();
  }

  @override
  Future<UserProfile?> findByPhone(String phoneNumber) async {
    final matches = await findAllByPhone(phoneNumber);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<List<UserProfile>> findAllByPhone(String phoneNumber) async {
    final models = await _remote.fetchAllByPhoneNumber(phoneNumber);
    for (final model in models) {
      _remember(model.firebaseUid, model.recordId);
    }
    final profiles = models.map((model) => model.toEntity()).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return profiles;
  }

  @override
  Future<UserProfile> ensureProfile({
    required String uid,
    required String phoneNumber,
    String fullName = '',
    String email = '',
  }) async {
    final existing = await getProfile(uid);
    if (existing != null) return existing;

    final now = DateTime.now();
    final draft = UserProfile(
      uid: uid,
      name: fullName.trim(),
      email: email.trim(),
      phone: phoneNumber.trim(),
      role: UserProfile.roleShipper,
      // Email registration collects a phone, but only Firebase phone OTP
      // verifies it later. Never claim a number is verified on creation.
      isPhoneVerified: false,
      createdAt: now,
      updatedAt: now,
    );
    final created = await _remote.create(UserProfileModel.fromEntity(draft));
    _remember(uid, created.recordId);
    return created.toEntity();
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    var recordId = _recordIds[profile.uid];
    if (recordId == null) {
      final existing = await _remote.fetchByFirebaseUid(profile.uid);
      recordId = existing?.recordId;
      _remember(profile.uid, recordId);
    }

    final model = UserProfileModel.fromEntity(profile);
    if (recordId == null) {
      final created = await _remote.create(model);
      _remember(profile.uid, created.recordId);
    } else {
      await _remote.update(recordId, model);
    }
  }

  void _remember(String uid, String? recordId) {
    if (recordId == null || recordId.isEmpty) return;
    _recordIds[uid] = recordId;
  }
}
