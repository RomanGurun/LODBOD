import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_auth_repository.dart';
import '../../data/mock/mock_shipment_repository.dart';
import '../../data/remote/api_shipment_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_shipment_repository.dart';

const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

final shipmentRepositoryProvider = Provider<IShipmentRepository>((ref) {
  if (_apiBaseUrl.isEmpty) return MockShipmentRepository();
  return ApiShipmentRepository(baseUrl: _apiBaseUrl);
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final repository = MockAuthRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
