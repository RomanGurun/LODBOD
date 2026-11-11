import 'dart:math';

import 'package:lodbod/features/shipments/domain/entities/shipment.dart';

/// A carrier quote generated for demo purposes.
///
/// The prototype ships only the shipper side of the marketplace — there is
/// no carrier app to submit bids — so the "Simulate carrier bid" demo
/// control generates one of these and posts it through the real API,
/// exactly as a carrier would.
class SimulatedCarrierBid {
  const SimulatedCarrierBid({
    required this.carrierName,
    required this.carrierRating,
    required this.carrierVerified,
    required this.fare,
    required this.etaDays,
    required this.estimatedDeliveryAt,
    required this.message,
  });

  final String carrierName;
  final double carrierRating;
  final bool carrierVerified;
  final double fare;
  final int etaDays;
  final DateTime estimatedDeliveryAt;
  final String message;
}

/// Generates a random fictional carrier bid for a shipment: a plausible
/// carrier profile plus a fare anchored to the shipper's expected fare.
///
/// The [Random] and clock are injectable so tests can pin both down.
class CarrierBidFactory {
  CarrierBidFactory({Random? random, DateTime Function()? now})
      : _random = random ?? Random(),
        _now = now ?? DateTime.now;

  final Random _random;
  final DateTime Function() _now;

  static const List<String> _carriers = <String>[
    'Annapurna Logistics',
    'Sagarmatha Transport',
    'Trishuli Freight',
    'Gorkha Haulage',
    'Kathmandu Carriers',
    'Everest Roadways',
    'Kasturi Movers',
    'Terai Lines',
  ];

  static const List<String> _messages = <String>[
    'Can pick up on the scheduled date.',
    'Experienced on this route — happy to take this load.',
    'Vehicle available nearby; ready to move once confirmed.',
    'Flexible on pickup time if needed.',
  ];

  SimulatedCarrierBid generate(Shipment shipment) {
    final etaDays = _random.nextInt(4) + 1; // 1–4 days
    // Carriers deliver after pickup; never promise a date in the past.
    final departure =
        shipment.pickupAt.isAfter(_now()) ? shipment.pickupAt : _now();

    return SimulatedCarrierBid(
      carrierName: _carriers[_random.nextInt(_carriers.length)],
      // 3.6–4.9 in one-decimal steps.
      carrierRating: (36 + _random.nextInt(14)) / 10,
      carrierVerified: _random.nextBool(),
      fare: _fare(shipment),
      etaDays: etaDays,
      estimatedDeliveryAt: departure.add(Duration(days: etaDays)),
      message: _messages[_random.nextInt(_messages.length)],
    );
  }

  double _fare(Shipment shipment) {
    final double fare;
    if (shipment.hasExpectedFare) {
      // Carriers quote around the expected fare: 85%–120% of it.
      fare = shipment.expectedFare * (0.85 + _random.nextDouble() * 0.35);
    } else {
      // No expected fare on the load — fall back to a plausible range.
      fare = 12000 + _random.nextDouble() * 24000;
    }
    // Round to the nearest NPR 500, like a real quote.
    return (fare / 500).roundToDouble() * 500;
  }
}
