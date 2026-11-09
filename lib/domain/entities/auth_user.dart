class AuthUser {
  final String id;
  final String email;
  final String displayName;

  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthUser &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            email == other.email &&
            displayName == other.displayName;
  }

  @override
  int get hashCode => Object.hash(id, email, displayName);

  @override
  String toString() => 'AuthUser($id, $email)';
}
