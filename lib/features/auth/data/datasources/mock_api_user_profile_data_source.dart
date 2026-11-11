import 'package:dio/dio.dart';

import 'package:lodbod/core/constants/api_endpoints.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/core/utils/phone_number.dart';
import 'package:lodbod/features/auth/data/models/user_profile_model.dart';

/// Dio-backed access to MockAPI `/users`.
///
/// The collection is queried by `firebaseUid`. MockAPI answers a filtered read
/// that matches nothing with 404, so that case is mapped to `null` instead of
/// an error.
class MockApiUserProfileDataSource {
  MockApiUserProfileDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<UserProfileModel?> fetchByFirebaseUid(String uid) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.users,
        queryParameters: <String, dynamic>{'firebaseUid': uid},
      );
      return _firstMatching(response.data, uid);
    } on DioException catch (error) {
      if (error.type == DioExceptionType.badResponse &&
          error.response?.statusCode == 404) {
        return null;
      }
      throw _mapDioError(error);
    } on FormatException {
      throw const ServerException(
        'The profile API returned invalid date data.',
      );
    } on TypeError {
      throw const ServerException(
        'The profile API returned an unexpected response.',
      );
    }
  }

  /// Finds a profile by phone number.
  ///
  /// MockAPI filters are exact matches, so the national digits and the E.164
  /// form are both tried; older records may contain either shape.
  Future<UserProfileModel?> fetchByPhoneNumber(String phoneNumber) async {
    final national = PhoneNumber.nationalDigits(phoneNumber);
    if (national.isEmpty) return null;

    final candidates = <String>{
      phoneNumber.trim(),
      national,
      PhoneNumber.toE164(national),
    }..removeWhere((value) => value.isEmpty);

    for (final candidate in candidates) {
      try {
        final response = await _dio.get<dynamic>(
          ApiEndpoints.users,
          queryParameters: <String, dynamic>{'phoneNumber': candidate},
        );
        final match = _firstMatchingPhone(response.data, national);
        if (match != null) return match;
      } on DioException catch (error) {
        // MockAPI returns 404 for a filtered read with zero matches.
        if (error.type == DioExceptionType.badResponse &&
            error.response?.statusCode == 404) {
          continue;
        }
        throw _mapDioError(error);
      } on FormatException {
        throw const ServerException(
          'The profile API returned invalid date data.',
        );
      } on TypeError {
        throw const ServerException(
          'The profile API returned an unexpected response.',
        );
      }
    }
    return null;
  }

  Future<UserProfileModel> create(UserProfileModel model) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.users,
        data: model.toJson(),
      );
      return _parseOne(response.data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<UserProfileModel> update(
      String recordId, UserProfileModel model) async {
    try {
      final response = await _dio.patch<dynamic>(
        '${ApiEndpoints.users}/$recordId',
        data: model.toJson(),
      );
      return _parseOne(response.data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  UserProfileModel? _firstMatchingPhone(dynamic data, String national) {
    final items = data is List<dynamic>
        ? data
        : data is Map<String, dynamic>
            ? <dynamic>[data]
            : const <dynamic>[];

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final model = UserProfileModel.fromJson(item);
      if (PhoneNumber.nationalDigits(model.phoneNumber) == national) {
        return model;
      }
    }
    return null;
  }

  UserProfileModel? _firstMatching(dynamic data, String uid) {
    // MockAPI returns a JSON array for filtered reads. Accept a single object
    // too so the code survives a proxy that unwraps single matches.
    final items = data is List<dynamic>
        ? data
        : data is Map<String, dynamic>
            ? <dynamic>[data]
            : const <dynamic>[];

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final model = UserProfileModel.fromJson(item);
      if (model.firebaseUid == uid) return model;
    }
    return null;
  }

  UserProfileModel _parseOne(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ServerException(
        'The profile API returned an unexpected response.',
      );
    }
    return UserProfileModel.fromJson(data);
  }

  AppException _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode == 404) return const NotFoundException();
        if (statusCode == 409) return const ConflictException();
        if (statusCode == 400 || statusCode == 422) {
          return ValidationException(
            'The profile API rejected the request ($statusCode).',
          );
        }
        return ServerException('Server error ($statusCode).', statusCode);
      case DioExceptionType.cancel:
        return const ServerException('The request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkException(
          'The server certificate could not be verified.',
        );
      case DioExceptionType.unknown:
        return const NetworkException();
    }
  }
}
