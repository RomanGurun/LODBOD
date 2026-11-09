enum CargoCategory {
  construction('construction', 'Construction'),
  agriculture('agriculture', 'Agriculture'),
  household('household', 'Household'),
  electronics('electronics', 'Electronics'),
  textiles('textiles', 'Textiles'),
  perishable('perishable', 'Perishable'),
  other('other', 'Other');

  const CargoCategory(this.wire, this.label);

  final String wire;
  final String label;

  static CargoCategory fromWire(String? value) {
    for (final category in values) {
      if (category.wire == value) return category;
    }
    return CargoCategory.other;
  }
}
