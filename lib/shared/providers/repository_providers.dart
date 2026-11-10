import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/data_source_status.dart';
import '../../data/mock/mock_auth_repository.dart';
import '../../data/mock/mock_shipment_repository.dart';
import '../../data/remote/api_shipment_repository.dart';
import '../../data/remote/firebase_auth_repository.dart';
import '../../data/remote/interceptors/data_source_interceptor.dart';
import '../../data/remote/interceptors/retry_interceptor.dart';
import '../../data/remote/interceptors/safe_log_interceptor.dart';
import '../../data/repositories/resilient_shipment_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_shipment_repository.dart';

const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

final dataSourceStatusProvider = Provider<DataSourceStatus>((ref) {
  final status = DataSourceStatus();
  ref.onDispose(status.dispose);
  return status;
});

final shipmentRepositoryProvider = Provider<IShipmentRepository>((ref) {
  if (_apiBaseUrl.isEmpty) return MockShipmentRepository();

  final status = ref.watch(dataSourceStatusProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.addAll(<Interceptor>[
    RetryInterceptor(dio: dio),
    SafeLogInterceptor(),
    DataSourceInterceptor(status),
  ]);

  final remote = ApiShipmentRepository(baseUrl: _apiBaseUrl, dio: dio);
  return ResilientShipmentRepository(remote: remote, status: status);
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final fallback = MockAuthRepository();
  ref.onDispose(fallback.dispose);

  try {
    final firebaseAuth = FirebaseAuth.instance;
    firebaseAuth.currentUser;
    final repository = FirebaseAuthRepository(
      firebaseAuth: firebaseAuth,
      fallback: fallback,
    );
    ref.onDispose(repository.dispose);
    return repository;
  } catch (_) {
    return fallback;
  }
});
