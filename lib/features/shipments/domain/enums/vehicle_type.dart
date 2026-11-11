enum VehicleType {
  miniTruck('mini_truck', 'Mini Truck'),
  truck6w('truck_6w', '6-Wheeler Truck'),
  truck10w('truck_10w', '10-Wheeler Truck'),
  truck12w('truck_12w', '12-Wheeler Truck'),
  container('container', 'Container Truck');

  const VehicleType(this.wire, this.label);

  final String wire;
  final String label;

  static VehicleType fromWire(String? value) {
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return VehicleType.truck10w;
  }
}
