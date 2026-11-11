class AuthUser {
  final String id;
  final String email;
  final String displayName;

  /// Verified phone number in E.164 form (e.g. `+9779812345678`) when the
  /// session was created with Firebase Phone Auth. Empty for email accounts.
  final String phoneNumber;

  /// Whether the email address has been verified (e.g. via email link).
  final bool isEmailVerified;

  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.phoneNumber = '',
    this.isEmailVerified = false,
  });

  bool get isPhoneAccount => phoneNumber.trim().isNotEmpty;

  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phoneNumber,
    bool? isEmailVerified,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
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
            phoneNumber == other.phoneNumber &&
            isEmailVerified == other.isEmailVerified;
  }

  @override
  int get hashCode =>
      Object.hash(id, email, displayName, phoneNumber, isEmailVerified);

  @override
  String toString() =>
      'AuthUser($id, ${email.isEmpty ? phoneNumber : email}, verified: $isEmailVerified)';
}
