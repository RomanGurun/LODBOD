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

  test('rejects identical pickup and destination cities', () {
    final draft = validDraft().copyWith(destinationCity: 'Kathmandu');
    expect(
      () => ShipmentValidation.validate(draft),
      throwsA(isA<ValidationException>()),
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
