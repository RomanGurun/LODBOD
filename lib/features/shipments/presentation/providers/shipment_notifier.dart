import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/auth/domain/entities/auth_user.dart';
import 'package:lodbod/features/shipments/domain/entities/create_shipment_draft.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/domain/rules/shipment_limit_rule.dart';
import 'package:lodbod/features/shipments/domain/rules/shipment_ownership.dart';
import 'package:lodbod/features/auth/presentation/providers/auth_notifier.dart';
import 'package:lodbod/core/di/repository_providers.dart';

/// Single source of truth for the signed-in shipper's shipments.
///
/// The list is scoped by ownership: it watches the auth state, so a new
/// sign-in rebuilds it for that user and signing out clears it — no
/// user-specific data survives a logout.
class ShipmentNotifier extends AsyncNotifier<List<Shipment>> {
  bool _isCreating = false;
  bool _acceptInProgress = false;

  @override
  Future<List<Shipment>> build() async {
    // Awaiting the auth future (rather than reading the possibly-loading
    // state) keeps this provider's own load from racing the auth provider's
    // initial load — a mid-load auth transition would otherwise cancel the
    // in-flight shipment fetch.
    final user = await ref.watch(authNotifierProvider.future);
    if (user == null) return const <Shipment>[];

    final shipments =
        await ref.watch(shipmentRepositoryProvider).getShipments();
    return ShipmentOwnership.ownedBy(shipments, user.id);
  }

  Future<Shipment> createShipment(CreateShipmentDraft draft) async {
    if (_isCreating) {
      throw const ConflictException('A shipment is already being created.');
    }
    final current = state.valueOrNull;
    if (current == null) {
      throw const ValidationException('Shipments are still loading.');
    }
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) {
      throw const AuthException('Your session expired. Please sign in again.');
    }

    // The limit counts only this shipper's qualifying shipments.
    ShipmentLimitRule.ensureCanCreate(current);

    _isCreating = true;
    try {
      final owned = draft.ownedBy(uid: user.id, name: _shipperName(user));
      final created =
          await ref.read(shipmentRepositoryProvider).createShipment(owned);
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

    // Only the owning shipper may accept bids on a shipment.
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null ||
        !ShipmentOwnership.isOwnedBy(current[index], user.id)) {
      throw const ForbiddenException(
        'You can only accept bids on your own shipments.',
      );
    }

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
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null) {
      state = const AsyncData<List<Shipment>>(<Shipment>[]);
      return;
    }
    state = const AsyncLoading<List<Shipment>>();
    state = await AsyncValue.guard<List<Shipment>>(() async {
      final shipments =
          await ref.read(shipmentRepositoryProvider).getShipments();
      return ShipmentOwnership.ownedBy(shipments, user.id);
    });
  }

  String _shipperName(AuthUser user) {
    final name = user.displayName.trim();
    return name.isEmpty ? 'Demo Shipper' : name;
  }
}

final shipmentNotifierProvider =
    AsyncNotifierProvider<ShipmentNotifier, List<Shipment>>(
  ShipmentNotifier.new,
);
