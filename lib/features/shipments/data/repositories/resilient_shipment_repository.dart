import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/core/network/data_source_status.dart';
import 'package:lodbod/features/shipments/domain/entities/bid.dart';
import 'package:lodbod/features/shipments/domain/entities/create_shipment_draft.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';
import 'package:lodbod/features/shipments/domain/repositories/i_shipment_repository.dart';
import 'package:lodbod/features/shipments/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/features/shipments/data/models/bid_model.dart';
import 'package:lodbod/features/shipments/data/models/shipment_model.dart';

class ResilientShipmentRepository implements IShipmentRepository {
  ResilientShipmentRepository({
    required IShipmentRepository remote,
    required DataSourceStatus status,
    MockShipmentRepository Function(
      List<ShipmentModel> shipments,
      List<BidModel> bids,
    )? localFactory,
  })  : _remote = remote,
        _status = status,
        _localFactory = localFactory ?? _defaultLocalFactory;

  final IShipmentRepository _remote;
  final DataSourceStatus _status;
  final MockShipmentRepository Function(
    List<ShipmentModel> shipments,
    List<BidModel> bids,
  ) _localFactory;

  IShipmentRepository? _local;
  List<Shipment>? _snapshot;
  bool _usingFallback = false;

  bool get usingFallback => _usingFallback;

  static MockShipmentRepository _defaultLocalFactory(
    List<ShipmentModel> shipments,
    List<BidModel> bids,
  ) {
    if (shipments.isEmpty) {
      return MockShipmentRepository(latency: Duration.zero);
    }
    return MockShipmentRepository(
      shipments: shipments,
      bids: bids,
      latency: Duration.zero,
    );
  }

  @override
  Future<List<Shipment>> getShipments({
    String? search,
    ShipmentStatus? status,
  }) {
    return _run<List<Shipment>>(
      remote: () => _remote.getShipments(search: search, status: status),
      local: (repository) => repository.getShipments(
        search: search,
        status: status,
      ),
      onRemoteSuccess: (shipments) => _snapshot = shipments,
    );
  }

  @override
  Future<Shipment> getShipmentById(String id) {
    return _run<Shipment>(
      remote: () => _remote.getShipmentById(id),
      local: (repository) => repository.getShipmentById(id),
      onRemoteSuccess: (shipment) => _replaceInSnapshot(shipment),
    );
  }

  @override
  Future<List<Bid>> getBids(String shipmentId) {
    return _run<List<Bid>>(
      remote: () => _remote.getBids(shipmentId),
      local: (repository) => repository.getBids(shipmentId),
      onRemoteSuccess: (bids) => _replaceBidsInSnapshot(shipmentId, bids),
    );
  }

  @override
  Future<Shipment> createShipment(CreateShipmentDraft draft) {
    return _run<Shipment>(
      remote: () => _remote.createShipment(draft),
      local: (repository) => repository.createShipment(draft),
      onRemoteSuccess: (shipment) {
        final snapshot = _snapshot;
        if (snapshot != null) {
          _snapshot = <Shipment>[shipment, ...snapshot];
        }
      },
    );
  }

  @override
  Future<Shipment> acceptBid({
    required String shipmentId,
    required String bidId,
  }) {
    return _run<Shipment>(
      remote: () => _remote.acceptBid(shipmentId: shipmentId, bidId: bidId),
      local: (repository) => repository.acceptBid(
        shipmentId: shipmentId,
        bidId: bidId,
      ),
      onRemoteSuccess: (shipment) => _replaceInSnapshot(shipment),
    );
  }

  @override
  Future<Shipment> simulateCarrierBid(String shipmentId) {
    return _run<Shipment>(
      remote: () => _remote.simulateCarrierBid(shipmentId),
      local: (repository) => repository.simulateCarrierBid(shipmentId),
      onRemoteSuccess: _replaceInSnapshot,
    );
  }

  @override
  Future<Shipment> advanceShipmentStatus(String shipmentId) {
    return _run<Shipment>(
      remote: () => _remote.advanceShipmentStatus(shipmentId),
      local: (repository) => repository.advanceShipmentStatus(shipmentId),
      onRemoteSuccess: _replaceInSnapshot,
    );
  }

  Future<T> _run<T>({
    required Future<T> Function() remote,
    required Future<T> Function(IShipmentRepository repository) local,
    void Function(T result)? onRemoteSuccess,
  }) async {
    if (_usingFallback) {
      return local(_ensureLocal());
    }

    try {
      final result = await remote();
      _status.markLive();
      onRemoteSuccess?.call(result);
      return result;
    } on NetworkException {
      return _activateFallback(local);
    } on ServerException {
      return _activateFallback(local);
    }
  }

  Future<T> _activateFallback<T>(
    Future<T> Function(IShipmentRepository repository) local,
  ) {
    _usingFallback = true;
    _status.markFallback();
    return local(_ensureLocal());
  }

  IShipmentRepository _ensureLocal() {
    return _local ??= _buildLocalFromSnapshot();
  }

  MockShipmentRepository _buildLocalFromSnapshot() {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return _localFactory(const <ShipmentModel>[], const <BidModel>[]);
    }

    final shipments = <ShipmentModel>[];
    final bids = <BidModel>[];
    for (final shipment in snapshot) {
      shipments.add(ShipmentModel.fromEntity(shipment));
      for (final bid in shipment.bids) {
        bids.add(BidModel.fromEntity(bid));
      }
    }
    return _localFactory(shipments, bids);
  }

  void _replaceInSnapshot(Shipment shipment) {
    final snapshot = _snapshot;
    if (snapshot == null) return;
    _snapshot = snapshot
        .map((item) => item.id == shipment.id ? shipment : item)
        .toList();
  }

  void _replaceBidsInSnapshot(String shipmentId, List<Bid> bids) {
    final snapshot = _snapshot;
    if (snapshot == null) return;
    _snapshot = snapshot
        .map(
          (shipment) => shipment.id == shipmentId
              ? shipment.copyWith(bids: bids)
              : shipment,
        )
        .toList();
  }
}
