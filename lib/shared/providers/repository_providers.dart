import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lodbod/core/network/data_source_status.dart';
import 'package:lodbod/data/mock/mock_auth_repository.dart';
import 'package:lodbod/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/data/mock/mock_user_profile_repository.dart';
import 'package:lodbod/data/remote/api_shipment_repository.dart';
import 'package:lodbod/data/remote/firebase_auth_repository.dart';
import 'package:lodbod/data/remote/firestore_user_profile_repository.dart';
import 'package:lodbod/data/remote/interceptors/data_source_interceptor.dart';
import 'package:lodbod/data/remote/interceptors/retry_interceptor.dart';
import 'package:lodbod/data/remote/interceptors/safe_log_interceptor.dart';
import 'package:lodbod/data/repositories/resilient_shipment_repository.dart';
import 'package:lodbod/data/repositories/resilient_user_profile_repository.dart';
import 'package:lodbod/domain/repositories/i_auth_repository.dart';
import 'package:lodbod/domain/repositories/i_shipment_repository.dart';
import 'package:lodbod/domain/repositories/i_user_profile_repository.dart';

/// Primary MockAPI base URL. Override with
/// `--dart-define=API_BASE_URL=https://…` to point the app at another
/// backend while keeping the same repository contract.
const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://6af2103d42c6561ced38f683.mockapi.io',
);

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

/// Remote-first user profile repository (Firestore `users/{uid}`) with an
/// in-memory fallback when Firestore cannot be reached.
final userProfileRepositoryProvider = Provider<IUserProfileRepository>((ref) {
  final fallback = MockUserProfileRepository();

  try {
    final firestore = FirebaseFirestore.instance;
    final remote = FirestoreUserProfileRepository(firestore: firestore);
    return ResilientUserProfileRepository(remote: remote, fallback: fallback);
  } catch (_) {
    // Firebase is not available on this platform/build — in-memory only.
    return fallback;
  }
});
