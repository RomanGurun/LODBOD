import '../../core/errors/app_exception.dart';
import '../../domain/entities/bid.dart';
import '../../domain/entities/create_shipment_draft.dart';
import '../../domain/entities/shipment.dart';
import '../../domain/enums/bid_status.dart';
import '../../domain/enums/shipment_status.dart';
import '../../domain/repositories/i_shipment_repository.dart';
import '../../domain/rules/bid_acceptance_rule.dart';
import '../../domain/rules/shipment_validation.dart';
import '../models/bid_model.dart';
import '../models/shipment_model.dart';
import 'seed_data.dart';

class MockShipmentRepository implements IShipmentRepository {
  MockShipmentRepository({
    List<ShipmentModel>? shipments,
    List<BidModel>? bids,
    this.latency = const Duration(milliseconds: 400),
    this.failReads = false,
    this.failWrites = false,
  })  : _shipments = List<ShipmentModel>.of(shipments ?? buildSeedShipments()),
        _bids = List<BidModel>.of(bids ?? buildSeedBids());

  final Duration latency;
  bool failReads;
  bool failWrites;

  final List<ShipmentModel> _shipments;
  final List<BidModel> _bids;

  @override
  Future<List<Shipment>> getShipments({
    String? search,
    ShipmentStatus? status,
  }) async {
    await _simulateRead();

    Iterable<ShipmentModel> models = _shipments;

    if (status != null) {
      models = models.where(
        (model) => ShipmentStatus.fromWire(model.status) == status,
      );
    }

    final query = search?.trim().toLowerCase() ?? '';
    if (query.isNotEmpty) {
      models = models.where((model) {
        final shipment = model.toEntity();
        return shipment.reference.toLowerCase().contains(query) ||
            shipment.pickupCity.toLowerCase().contains(query) ||
            shipment.destinationCity.toLowerCase().contains(query) ||
            shipment.routeLabel.toLowerCase().contains(query);
      });
    }

    final results = models
        .map((model) => model.toEntity(bids: _bidsFor(model.id)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Future<Shipment> getShipmentById(String id) async {
    await _simulateRead();
    final index = _shipments.indexWhere((shipment) => shipment.id == id);
    if (index == -1) throw const NotFoundException();
    return _shipments[index].toEntity(bids: _bidsFor(id));
  }

  @override
  Future<List<Bid>> getBids(String shipmentId) async {
    await _simulateRead();
    return _bidsFor(shipmentId);
  }

  @override
  Future<Shipment> createShipment(CreateShipmentDraft draft) async {
    await _simulateWrite();
    ShipmentValidation.validate(draft);

    final now = DateTime.now();
    final model = ShipmentModel(
      id: _nextId(),
      reference: _nextReference(),
      shipperName: draft.shipperName,
      shipperId: draft.shipperId,
      pickupCity: draft.pickupCity.trim(),
      pickupAddress: draft.pickupAddress.trim(),
      destinationCity: draft.destinationCity.trim(),
      destinationAddress: draft.destinationAddress.trim(),
      cargoDescription: draft.cargoDescription.trim(),
      cargoCategory: draft.cargoCategory,
      weight: draft.weight,
      weightUnit: draft.weightUnit,
      vehicleType: draft.vehicleType,
      pickupAt: draft.pickupAt,
      expectedFare: draft.expectedFare,
      currency: draft.currency,
      status: ShipmentStatus.open.wire,
      notes: draft.notes.trim(),
      createdAt: now,
      updatedAt: now,
    );

    _shipments.add(model);
    return model.toEntity();
  }

  @override
  Future<Shipment> acceptBid({
    required String shipmentId,
    required String bidId,
  }) async {
    await _simulateWrite();

    final shipmentIndex =
        _shipments.indexWhere((shipment) => shipment.id == shipmentId);
    if (shipmentIndex == -1) {
      throw const NotFoundException('Shipment not found.');
    }

    final bidIndex = _bids.indexWhere(
      (bid) => bid.id == bidId && bid.shipmentId == shipmentId,
    );
    if (bidIndex == -1) throw const NotFoundException('Bid not found.');

    final acceptedBid = _bids[bidIndex];
    final shipment = _shipments[shipmentIndex];
    BidAcceptanceRule.ensureCanAccept(
      shipment.toEntity(),
      acceptedBid.toEntity(),
    );

    for (var i = 0; i < _bids.length; i++) {
      final candidate = _bids[i];
      if (candidate.shipmentId != shipmentId) continue;
      if (i == bidIndex) {
        _bids[i] = candidate.copyWith(status: BidStatus.accepted.wire);
      } else if (candidate.status == BidStatus.pending.wire) {
        _bids[i] = candidate.copyWith(status: BidStatus.rejected.wire);
      }
    }

    final updated = shipment.copyWith(
      status: ShipmentStatus.confirmed.wire,
      acceptedBidId: acceptedBid.id,
      assignedCarrier: acceptedBid.carrierName,
      updatedAt: DateTime.now(),
    );
    _shipments[shipmentIndex] = updated;

    return updated.toEntity(bids: _bidsFor(shipmentId));
  }

  Future<void> _simulateRead() async {
    await Future<void>.delayed(latency);
    if (failReads) throw const NetworkException();
  }

  Future<void> _simulateWrite() async {
    await Future<void>.delayed(latency);
    if (failWrites) throw const ServerException();
  }

  List<Bid> _bidsFor(String shipmentId) {
    final results = _bids
        .where((bid) => bid.shipmentId == shipmentId)
        .map((bid) => bid.toEntity())
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  String _nextId() {
    var max = 0;
    for (final shipment in _shipments) {
      final number = int.tryParse(shipment.id) ?? 0;
      if (number > max) max = number;
    }
    return '${max + 1}';
  }

  String _nextReference() {
    var max = 1000;
    for (final shipment in _shipments) {
      final match = RegExp(r'^LOD-(\d+)$').firstMatch(shipment.reference);
      if (match == null) continue;
      final number = int.tryParse(match.group(1) ?? '') ?? 0;
      if (number > max) max = number;
    }
    return 'LOD-${max + 1}';
  }
}
