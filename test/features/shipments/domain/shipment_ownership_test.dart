import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/features/shipments/domain/entities/shipment.dart';
import 'package:lodbod/features/shipments/domain/rules/shipment_ownership.dart';

import '../../../support/fixtures.dart';

void main() {
  test('the demo owner owns legacy seeded records without a shipperId',
      () async {
    final legacy = buildShipment(id: '1');

    expect(ShipmentOwnership.isOwnedBy(legacy, 'demo-1'), isTrue);
  });

  test('other shippers never own legacy seeded records', () async {
    final legacy = buildShipment(id: '1');

    expect(ShipmentOwnership.isOwnedBy(legacy, 'user-a'), isFalse);
    expect(ShipmentOwnership.isOwnedBy(legacy, 'user-b'), isFalse);
  });

  test('a stamped shipment belongs only to its recorded shipper', () async {
    final owned = buildShipment(id: '2').copyWith(shipperId: 'user-a');

    expect(ShipmentOwnership.isOwnedBy(owned, 'user-a'), isTrue);
    expect(ShipmentOwnership.isOwnedBy(owned, 'user-b'), isFalse);
    expect(ShipmentOwnership.isOwnedBy(owned, 'demo-1'), isFalse);
  });

  test('ownedBy filters a mixed list down to the given shipper', () async {
    final shipments = <Shipment>[
      buildShipment(id: '1'), // legacy — demo owner only
      buildShipment(id: '2').copyWith(shipperId: 'user-a'),
      buildShipment(id: '3').copyWith(shipperId: 'user-b'),
      buildShipment(id: '4'), // legacy — demo owner only
    ];

    expect(
      ShipmentOwnership.ownedBy(shipments, 'demo-1').map((s) => s.id),
      <String>['1', '4'],
    );
    expect(
      ShipmentOwnership.ownedBy(shipments, 'user-a').map((s) => s.id),
      <String>['2'],
    );
    expect(ShipmentOwnership.ownedBy(shipments, 'user-c'), isEmpty);
  });

  test('a blank shipperId is treated like a legacy record', () async {
    final blank = buildShipment(id: '5').copyWith(shipperId: '');

    expect(ShipmentOwnership.isOwnedBy(blank, 'demo-1'), isTrue);
    expect(ShipmentOwnership.isOwnedBy(blank, 'user-a'), isFalse);
  });
}
