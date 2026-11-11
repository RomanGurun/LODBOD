import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lodbod/features/auth/domain/entities/user_profile.dart';
import 'package:lodbod/features/auth/domain/repositories/i_user_profile_repository.dart';

/// Firestore-backed user profile repository.
///
/// Documents are stored at `users/{uid}`. Errors propagate to the caller so
/// the resilient wrapper can fall back to the in-memory store when Firestore
/// is unavailable.
class FirestoreUserProfileRepository implements IUserProfileRepository {
  FirestoreUserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromFirestore(doc.data()!);
  }

  @override
  Future<UserProfile?> findByPhone(String phoneNumber) async {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) return null;
    for (final field in const <String>['phone', 'phoneNumber']) {
      final query =
          await _users.where(field, isEqualTo: trimmed).limit(1).get();
      if (query.docs.isNotEmpty) {
        return UserProfile.fromFirestore(query.docs.first.data());
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
    final existing = await getProfile(uid);
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
    await saveProfile(profile);
    return profile;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _users.doc(profile.uid).set(
          profile.toFirestore(),
          SetOptions(merge: true),
        );
  }
}
