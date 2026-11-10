import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/domain/rules/shipment_validation.dart';

import '../support/fixtures.dart';

void main() {
  test('accepts a valid draft', () {
    expect(
      () => ShipmentValidation.validate(validDraft()),
      returnsNormally,
    );
  });

  test('rejects a blank pickup city', () {
    final draft = validDraft().copyWith(pickupCity: '   ');
    expect(
      () => ShipmentValidation.validate(draft),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects a blank pickup address', () {
    final draft = validDraft().copyWith(pickupAddress: '   ');
    expect(
      () => ShipmentValidation.validate(draft),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects a blank destination city', () {
    final draft = validDraft().copyWith(destinationCity: '   ');
    expect(
      () => ShipmentValidation.validate(draft),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects a blank destination address', () {
    final draft = validDraft().copyWith(destinationAddress: '   ');
    expect(
      () => ShipmentValidation.validate(draft),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects a blank cargo description', () {
    final draft = validDraft().copyWith(cargoDescription: '   ');
    expect(
      () => ShipmentValidation.validate(draft),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects identical pickup and destination cities case-insensitively',
      () {
    final draft = validDraft().copyWith(destinationCity: '  kathmandu ');
    expect(
      () => ShipmentValidation.validate(draft),
      throwsA(isA<ValidationException>()),
    );
  });

  test('allows a pickup time within the one-hour grace period', () {
    final clock = DateTime(2026, 1, 10, 12);
    final draft = validDraft(now: clock).copyWith(
      pickupAt: clock.subtract(const Duration(minutes: 30)),
    );

    expect(
      () => ShipmentValidation.validate(draft, now: clock),
      returnsNormally,
    );
  });

  test('rejects a non-positive weight', () {
    final draft = validDraft().copyWith(weight: 0);
    expect(
      () => ShipmentValidation.validate(draft),
      throwsA(isA<ValidationException>()),
    );
  });

  test('rejects a pickup date in the past', () {
    final clock = DateTime(2026, 1, 10, 12);
    final draft = validDraft(now: clock).copyWith(
      pickupAt: DateTime(2026, 1, 1, 8),
    );

    expect(
      () => ShipmentValidation.validate(draft, now: clock),
      throwsA(isA<ValidationException>()),
    );
  });
}
