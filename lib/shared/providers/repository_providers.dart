import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_auth_repository.dart';
import '../../data/mock/mock_shipment_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_shipment_repository.dart';

final shipmentRepositoryProvider = Provider<IShipmentRepository>((ref) {
  return MockShipmentRepository();
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final repository = MockAuthRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
