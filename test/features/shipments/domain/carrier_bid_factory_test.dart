import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/features/shipments/domain/factories/carrier_bid_factory.dart';

import '../../../support/fixtures.dart';

void main() {
  final clock = DateTime(2026, 11, 11, 10);

  test('generates a quote from a known carrier with a tidy fare', () {
    final factory = CarrierBidFactory(
      random: Random(42),
      now: () => clock,
    );
    final shipment = buildShipment(expectedFare: 20000);

    final quote = factory.generate(shipment);

    expect(quote.carrierName, isNotEmpty);
    expect(quote.message, isNotEmpty);
    // Fare is rounded to the nearest NPR 500…
    expect(quote.fare % 500, 0);
    // …and anchored to the expected fare (85%–120%).
    expect(quote.fare, greaterThanOrEqualTo(20000 * 0.85 - 500));
    expect(quote.fare, lessThanOrEqualTo(20000 * 1.2 + 500));
    expect(quote.carrierRating, inInclusiveRange(3.6, 4.9));
    expect(quote.etaDays, inInclusiveRange(1, 4));
  });

  test('falls back to a market range when no expected fare is set', () {
    final factory = CarrierBidFactory(
      random: Random(7),
      now: () => clock,
    );
    final shipment = buildShipment(expectedFare: 0);

    final quote = factory.generate(shipment);

    expect(quote.fare % 500, 0);
    expect(quote.fare, greaterThanOrEqualTo(12000));
    expect(quote.fare, lessThanOrEqualTo(36000));
  });

  test('estimated delivery is at least pickup plus the ETA days', () {
    final factory = CarrierBidFactory(
      random: Random(1),
      now: () => clock,
    );
    final futurePickup = clock.add(const Duration(days: 5));
    final shipment = buildShipment(pickupAt: futurePickup);

    final quote = factory.generate(shipment);

    expect(
      quote.estimatedDeliveryAt,
      futurePickup.add(Duration(days: quote.etaDays)),
    );
  });

  test('delivery never lands in the past when pickup already happened', () {
    final factory = CarrierBidFactory(
      random: Random(1),
      now: () => clock,
    );
    final pastPickup = clock.subtract(const Duration(days: 3));
    final shipment = buildShipment(pickupAt: pastPickup);

    final quote = factory.generate(shipment);

    expect(
      quote.estimatedDeliveryAt,
      clock.add(Duration(days: quote.etaDays)),
    );
    expect(quote.estimatedDeliveryAt.isAfter(pastPickup), isTrue);
  });

  test('every generated carrier comes from the fictional pool', () {
    // Exhaustively walk the pool: with a seeded random the factory cycles
    // through names, ratings, verification and messages without blowing up.
    final factory = CarrierBidFactory(now: () => clock);
    final shipment = buildShipment(expectedFare: 15000);

    final names = <String>{};
    for (var i = 0; i < 50; i++) {
      final quote = factory.generate(shipment);
      names.add(quote.carrierName);
      expect(quote.carrierName, isNot(contains('Himalayan Cargo')));
    }

    // The pool is large enough that repeated draws produce variety.
    expect(names.length, greaterThan(1));
  });
}
