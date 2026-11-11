import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lodbod/core/constants/api_endpoints.dart';
import 'package:lodbod/core/network/data_source_status.dart';
import 'package:lodbod/core/network/interceptors/data_source_interceptor.dart';
import 'package:lodbod/core/network/interceptors/retry_interceptor.dart';
import 'package:lodbod/core/network/interceptors/safe_log_interceptor.dart';
import 'package:lodbod/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:lodbod/features/auth/data/datasources/mock_api_user_profile_data_source.dart';
import 'package:lodbod/features/auth/data/mock/mock_auth_repository.dart';
import 'package:lodbod/features/auth/data/mock/mock_user_profile_repository.dart';
import 'package:lodbod/features/auth/data/remote/firebase_auth_repository.dart';
import 'package:lodbod/features/auth/data/remote/mock_api_user_profile_repository.dart';
import 'package:lodbod/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:lodbod/features/auth/domain/repositories/i_user_profile_repository.dart';
import 'package:lodbod/features/shipments/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/features/shipments/data/remote/api_shipment_repository.dart';
import 'package:lodbod/features/shipments/data/repositories/resilient_shipment_repository.dart';
import 'package:lodbod/features/shipments/domain/repositories/i_shipment_repository.dart';

final dataSourceStatusProvider = Provider<DataSourceStatus>((ref) {
  final status = DataSourceStatus();
  ref.onDispose(status.dispose);
  return status;
});

Dio _createDio({
  DataSourceStatus? status,
  String baseUrl = ApiEndpoints.shipmentsBaseUrl,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.addAll(<Interceptor>[
    RetryInterceptor(dio: dio),
    SafeLogInterceptor(),
    if (status != null) DataSourceInterceptor(status),
  ]);
  return dio;
}

final shipmentRepositoryProvider = Provider<IShipmentRepository>((ref) {
  if (ApiEndpoints.shipmentsBaseUrl.isEmpty) return MockShipmentRepository();

  final status = ref.watch(dataSourceStatusProvider);
  final dio = _createDio(status: status);

  final remote = ApiShipmentRepository(
    baseUrl: ApiEndpoints.shipmentsBaseUrl,
    dio: dio,
  );
  return ResilientShipmentRepository(remote: remote, status: status);
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final fallback = MockAuthRepository();
  ref.onDispose(fallback.dispose);

  try {
    final dataSource = FirebaseAuthDataSourceImpl(
      firebaseAuth: FirebaseAuth.instance,
    );
    final repository = FirebaseAuthRepository(
      dataSource: dataSource,
      fallback: fallback,
    );
    ref.onDispose(repository.dispose);
    return repository;
  } catch (_) {
    // Firebase is not initialised on this platform/build — email demo only.
    return fallback;
  }
});

/// MockAPI `/users` profile store, keyed by Firebase UID.
///
/// Profiles use their own MockAPI project (see [ApiEndpoints.usersBaseUrl]),
/// separate from shipments/bids. Unlike shipments there is no silent local
/// fallback: if the profile cannot be read or created after a successful OTP,
/// the app routes to a retry screen rather than pretending the profile was
/// saved.
final userProfileRepositoryProvider = Provider<IUserProfileRepository>((ref) {
  if (ApiEndpoints.usersBaseUrl.isEmpty) return MockUserProfileRepository();

  // Profile traffic intentionally does not share the shipment data-source
  // status: a `/users` outage must never mark shipments as running on their
  // local fallback.
  final dio = _createDio(baseUrl: ApiEndpoints.usersBaseUrl);
  return MockApiUserProfileRepository(
    remote: MockApiUserProfileDataSource(dio: dio),
  );
});
