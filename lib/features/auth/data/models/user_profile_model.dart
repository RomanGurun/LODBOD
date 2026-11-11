import 'package:lodbod/features/auth/domain/entities/user_profile.dart';

/// MockAPI `/users` record.
///
/// [recordId] is MockAPI's own identifier and is only needed for PATCH/DELETE
/// calls. Domain code keys profiles by Firebase UID instead.
class UserProfileModel {
  const UserProfileModel({
    this.recordId,
    required this.firebaseUid,
    required this.phoneNumber,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isPhoneVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  final String? recordId;
  final String firebaseUid;
  final String phoneNumber;
  final String fullName;
  final String email;
  final String role;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      recordId: json['id']?.toString(),
      firebaseUid: (json['firebaseUid'] ?? json['uid'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? json['phone'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: UserProfile.normalizeRole(json['role']?.toString()),
      isPhoneVerified: _parseBool(json['isPhoneVerified']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  factory UserProfileModel.fromEntity(UserProfile profile) {
    return UserProfileModel(
      firebaseUid: profile.uid,
      phoneNumber: profile.phone,
      fullName: profile.name,
      email: profile.email,
      role: profile.role,
      isPhoneVerified: profile.isPhoneVerified,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      uid: firebaseUid,
      name: fullName,
      email: email,
      phone: phoneNumber,
      role: role,
      isPhoneVerified: isPhoneVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Body for POST/PATCH. MockAPI's `id` is never part of the payload.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'firebaseUid': firebaseUid,
        'phoneNumber': phoneNumber,
        'fullName': fullName,
        'email': email,
        'role': role,
        'isPhoneVerified': isPhoneVerified,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static bool _parseBool(Object? value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
