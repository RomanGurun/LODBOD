import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lodbod/domain/entities/user_profile.dart';
import 'package:lodbod/domain/repositories/i_user_profile_repository.dart';

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
  Future<void> saveProfile(UserProfile profile) async {
    await _users.doc(profile.uid).set(
          profile.toFirestore(),
          SetOptions(merge: true),
        );
  }
}
