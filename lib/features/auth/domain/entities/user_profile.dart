/// Profile record stored in MockAPI `/users`, keyed by Firebase UID.
///
/// The wire shape is owned by [toJson]/[fromJson]. The Firebase UID is kept in
/// [uid]; MockAPI's own record id is handled by the data layer and is not part
/// of the domain entity.
class UserProfile {
  static const String roleShipper = 'shipper';
  static const String roleCarrier = 'carrier';

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.role = roleShipper,
    this.isPhoneVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isShipper => role == roleShipper;

  bool get isCarrier => role == roleCarrier;

  /// A profile counts as complete once the user has supplied a full name.
  /// Phone verification is already guaranteed by the OTP login itself.
  bool get isComplete => name.trim().isNotEmpty;

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? isPhoneVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// MockAPI `/users` wire format.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'firebaseUid': uid,
        'phoneNumber': phone,
        'fullName': name,
        'email': email,
        'role': role,
        'isPhoneVerified': isPhoneVerified,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> data) {
    final role = _normalizeRole(data['role']);
    return UserProfile(
      uid: (data['firebaseUid'] ?? data['uid'] ?? '').toString(),
      name: (data['fullName'] ?? data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      phone: (data['phoneNumber'] ?? data['phone'] ?? '').toString(),
      role: role,
      isPhoneVerified: _parseBool(data['isPhoneVerified']),
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Legacy Firestore shape kept so the existing Firestore repository still
  /// compiles; the app now reads profiles from MockAPI.
  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'isPhoneVerified': isPhoneVerified,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile.fromJson(<String, dynamic>{
      'firebaseUid': data['uid'],
      ...data,
    });
  }

  static String normalizeRole(String? value) => _normalizeRole(value);

  static String _normalizeRole(Object? value) {
    return value?.toString().trim().toLowerCase() == roleCarrier
        ? roleCarrier
        : roleShipper;
  }

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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserProfile &&
            runtimeType == other.runtimeType &&
            uid == other.uid &&
            name == other.name &&
            email == other.email &&
            phone == other.phone &&
            role == other.role &&
            isPhoneVerified == other.isPhoneVerified;
  }

  @override
  int get hashCode =>
      Object.hash(uid, name, email, phone, role, isPhoneVerified);

  @override
  String toString() => 'UserProfile($uid, $name, $role)';
}
