import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/domain/enums/shipment_status.dart';
import 'package:lodbod/domain/rules/shipment_limit_rule.dart';

import '../support/fixtures.dart';

void main() {
  group('ShipmentStatus limit membership', () {
    test('active statuses count toward the limit', () {
      const active = <ShipmentStatus>[
        ShipmentStatus.open,
        ShipmentStatus.awaitingBids,
        ShipmentStatus.scheduled,
        ShipmentStatus.confirmed,
        ShipmentStatus.inTransit,
      ];
      for (final status in active) {
        expect(status.countsTowardsLimit, isTrue, reason: status.wire);
      }
    });

    test('completed statuses do not count toward the limit', () {
      const completed = <ShipmentStatus>[
        ShipmentStatus.delivered,
        ShipmentStatus.cancelled,
        ShipmentStatus.expired,
      ];
      for (final status in completed) {
        expect(status.countsTowardsLimit, isFalse, reason: status.wire);
      }
    });
  });

  group('ShipmentLimitRule', () {
    test('counts only active shipments', () {
      final shipments = [
        buildShipment(id: '1', status: ShipmentStatus.open),
        buildShipment(id: '2', status: ShipmentStatus.delivered),
        buildShipment(id: '3', status: ShipmentStatus.inTransit),
      ];

      expect(ShipmentLimitRule.countActive(shipments), 2);
      expect(ShipmentLimitRule.isAtLimit(shipments), isFalse);
    });

    test('reports at limit with three active shipments', () {
      final shipments = [
        buildShipment(id: '1', status: ShipmentStatus.open),
        buildShipment(id: '2', status: ShipmentStatus.scheduled),
        buildShipment(id: '3', status: ShipmentStatus.confirmed),
      ];

      expect(ShipmentLimitRule.isAtLimit(shipments), isTrue);
      expect(
        () => ShipmentLimitRule.ensureCanCreate(shipments),
        throwsA(isA<LimitException>()),
      );
    });

    test('allows creation below the limit', () {
      final shipments = [
        buildShipment(id: '1', status: ShipmentStatus.open),
      ];

      expect(
        () => ShipmentLimitRule.ensureCanCreate(shipments),
        returnsNormally,
      );
    });
  });
}
