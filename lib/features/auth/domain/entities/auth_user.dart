class AuthUser {
  final String id;
  final String email;
  final String displayName;

  /// Verified phone number in E.164 form (e.g. `+9779812345678`) when the
  /// session was created with Firebase Phone Auth. Empty for email accounts.
  final String phoneNumber;

  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.phoneNumber = '',
  });

  bool get isPhoneAccount => phoneNumber.trim().isNotEmpty;

  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthUser &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            email == other.email &&
            displayName == other.displayName &&
            phoneNumber == other.phoneNumber;
  }

  @override
  int get hashCode => Object.hash(id, email, displayName, phoneNumber);

  @override
  String toString() => 'AuthUser($id, ${email.isEmpty ? phoneNumber : email})';
}
