import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/network/data_source_status.dart';
import 'package:lodbod/data/mock/mock_shipment_repository.dart';
import 'package:lodbod/data/repositories/resilient_shipment_repository.dart';
import 'package:lodbod/domain/entities/create_shipment_draft.dart';

CreateShipmentDraft _draft() {
  return CreateShipmentDraft(
    pickupCity: 'Kathmandu',
    pickupAddress: 'Kalimati, Kathmandu',
    destinationCity: 'Pokhara',
    destinationAddress: 'Lakeside, Pokhara',
    cargoDescription: 'Steel pipes',
    cargoCategory: 'construction',
    weight: 10,
    weightUnit: 'tonnes',
    vehicleType: 'truck_10w',
    pickupAt: DateTime.now().add(const Duration(days: 2)),
  );
}

void main() {
  late DataSourceStatus status;

  setUp(() => status = DataSourceStatus());
  tearDown(() => status.dispose());

  test('falls back to local seed when remote reads fail', () async {
    final repository = ResilientShipmentRepository(
      remote: MockShipmentRepository(
        latency: Duration.zero,
        failReads: true,
      ),
      status: status,
    );

    final shipments = await repository.getShipments();

    expect(shipments, hasLength(4));
    expect(status.usingFallback.value, isTrue);
  });

  test('stays live when the API is healthy', () async {
    final repository = ResilientShipmentRepository(
      remote: MockShipmentRepository(latency: Duration.zero),
      status: status,
    );

    await repository.getShipments();

    expect(status.usingFallback.value, isFalse);
  });

  test('writes locally after a failure using the cached live snapshot',
      () async {
    final remote = MockShipmentRepository(latency: Duration.zero);
    final repository =
        ResilientShipmentRepository(remote: remote, status: status);

    final live = await repository.getShipments();
    expect(status.usingFallback.value, isFalse);

    remote.failWrites = true;
    final created = await repository.createShipment(_draft());

    expect(created.reference, 'LOD-1005');
    expect(status.usingFallback.value, isTrue);

    final shipments = await repository.getShipments();
    expect(shipments, hasLength(live.length + 1));
    expect(
      shipments.any((shipment) => shipment.reference == 'LOD-1005'),
      isTrue,
    );
  });

  test('falls back to seed writes when no live snapshot exists', () async {
    final repository = ResilientShipmentRepository(
      remote: MockShipmentRepository(
        latency: Duration.zero,
        failReads: true,
        failWrites: true,
      ),
      status: status,
    );

    final created = await repository.createShipment(_draft());

    expect(created.reference, 'LOD-1005');
    expect(status.usingFallback.value, isTrue);
    expect(await repository.getShipments(), hasLength(5));
  });
}
