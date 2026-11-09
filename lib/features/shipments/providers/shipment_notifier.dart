import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../domain/entities/create_shipment_draft.dart';
import '../../../domain/entities/shipment.dart';
import '../../../domain/rules/shipment_limit_rule.dart';
import '../../../shared/providers/repository_providers.dart';

class ShipmentNotifier extends AsyncNotifier<List<Shipment>> {
  bool _isCreating = false;
  bool _acceptInProgress = false;

  @override
  Future<List<Shipment>> build() {
    return ref.watch(shipmentRepositoryProvider).getShipments();
  }

  Future<Shipment> createShipment(CreateShipmentDraft draft) async {
    if (_isCreating) {
      throw const ConflictException('A shipment is already being created.');
    }
    final current = state.valueOrNull;
    if (current == null) {
      throw const ValidationException('Shipments are still loading.');
    }

    ShipmentLimitRule.ensureCanCreate(current);

    _isCreating = true;
    try {
      final created =
          await ref.read(shipmentRepositoryProvider).createShipment(draft);
      state = AsyncData<List<Shipment>>(<Shipment>[created, ...current]);
      return created;
    } finally {
      _isCreating = false;
    }
  }

  Future<Shipment> acceptBid({
    required String shipmentId,
    required String bidId,
  }) async {
    if (_acceptInProgress) {
      throw const ConflictException('A bid is already being accepted.');
    }
    final current = state.valueOrNull;
    if (current == null) {
      throw const ValidationException('Shipments are still loading.');
    }

    final index = current.indexWhere((shipment) => shipment.id == shipmentId);
    if (index == -1) throw const NotFoundException();

    _acceptInProgress = true;
    try {
      final updated = await ref.read(shipmentRepositoryProvider).acceptBid(
            shipmentId: shipmentId,
            bidId: bidId,
          );
      final next = List<Shipment>.of(current)..[index] = updated;
      state = AsyncData<List<Shipment>>(next);
      return updated;
    } finally {
      _acceptInProgress = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading<List<Shipment>>();
    state = await AsyncValue.guard<List<Shipment>>(
      () => ref.read(shipmentRepositoryProvider).getShipments(),
    );
  }
}

final shipmentNotifierProvider =
    AsyncNotifierProvider<ShipmentNotifier, List<Shipment>>(
  ShipmentNotifier.new,
);
