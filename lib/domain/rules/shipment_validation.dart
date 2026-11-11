import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/domain/entities/create_shipment_draft.dart';

class ShipmentValidation {
  ShipmentValidation._();

  static void validate(CreateShipmentDraft draft, {DateTime? now}) {
    final clock = now ?? DateTime.now();

    if (draft.pickupCity.trim().isEmpty || draft.pickupAddress.trim().isEmpty) {
      throw const ValidationException('Pickup city and address are required.');
    }
    if (draft.destinationCity.trim().isEmpty ||
        draft.destinationAddress.trim().isEmpty) {
      throw const ValidationException(
          'Destination city and address are required.');
    }
    if (draft.pickupCity.trim().toLowerCase() ==
        draft.destinationCity.trim().toLowerCase()) {
      throw const ValidationException(AppStrings.sameLocationError);
    }
    if (draft.cargoDescription.trim().isEmpty) {
      throw const ValidationException('Cargo description is required.');
    }
    if (draft.weight <= 0) {
      throw const ValidationException(AppStrings.invalidWeight);
    }
    if (draft.pickupAt.isBefore(clock.subtract(const Duration(hours: 1)))) {
      throw const ValidationException(AppStrings.pastDateError);
    }
  }
}
