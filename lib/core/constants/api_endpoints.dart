/// Backend base URLs used by the app.
///
/// Shipments/bids and user profiles intentionally live in two different
/// MockAPI projects: the free plan limits how many resources a single project
/// can hold. Each project gets its own base URL and its own Dio client.
class ApiEndpoints {
  ApiEndpoints._();

  /// Project that hosts `/shipments` and `/bids`.
  ///
  /// Override with `--dart-define=API_BASE_URL=https://…`.
  static const String shipmentsBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://6af2103d42c6561ced38f683.mockapi.io',
  );

  /// Separate project that hosts only `/users`.
  ///
  /// Override with
  /// `--dart-define=USERS_API_BASE_URL=https://…`.
  static const String usersBaseUrl = String.fromEnvironment(
    'USERS_API_BASE_URL',
    defaultValue: 'https://6af4414b55a1de7dcf03c6dc.mockapi.io',
  );

  /// Path of the profile collection inside [usersBaseUrl].
  static const String users = '/users';
}
