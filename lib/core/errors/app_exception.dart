sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(
      [super.message = 'No internet connection. Please check your network.']);
}

class AuthException extends AppException {
  const AuthException(
      [super.message = 'Authentication failed. Please sign in again.']);
}

/// Firebase Auth could not be reached at all (network down, API key rejected,
/// provider disabled). The email login flow uses this to fall back to the
/// local demo account; phone OTP failures are surfaced to the user instead.
class AuthServiceUnavailableException extends AuthException {
  const AuthServiceUnavailableException([
    super.message = 'Authentication service is unavailable. Please try again.',
  ]);
}

class LimitException extends AppException {
  const LimitException([
    super.message = 'You have reached the mobile request limit of 3. '
        'Please use the LODBOD web platform to create additional requests.',
  ]);
}

class ValidationException extends AppException {
  const ValidationException(
      [super.message = 'Please check your input and try again.']);
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException([
    super.message = 'Something went wrong on the server. Please try again.',
    this.statusCode,
  ]);
}

class NotFoundException extends AppException {
  const NotFoundException(
      [super.message = 'The requested resource was not found.']);
}

class ConflictException extends AppException {
  const ConflictException(
      [super.message = 'This action has already been performed.']);
}

class ForbiddenException extends AppException {
  const ForbiddenException(
      [super.message = 'You do not have permission to do this.']);
}
