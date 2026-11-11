import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lodbod/core/theme/tokens.dart';
import 'package:lodbod/core/constants/app_strings.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/shared/extensions/date_ext.dart';
import 'package:lodbod/shared/extensions/num_ext.dart';
import 'package:lodbod/shared/widgets/app_text_field.dart';
import 'package:lodbod/core/routing/app_router.dart';
import 'package:lodbod/features/shipments/domain/entities/create_shipment_draft.dart';
import 'package:lodbod/features/shipments/domain/enums/cargo_category.dart';
import 'package:lodbod/features/shipments/domain/enums/vehicle_type.dart';
import 'package:lodbod/features/shipments/domain/rules/shipment_validation.dart';
import 'package:lodbod/features/shipments/presentation/providers/shipment_notifier.dart';

class CreateShipmentScreen extends ConsumerStatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  ConsumerState<CreateShipmentScreen> createState() =>
      _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends ConsumerState<CreateShipmentScreen> {
  static const int _stepCount = 5;
  static const List<String> _stepTitles = <String>[
    AppStrings.step1Title,
    AppStrings.step2Title,
    AppStrings.step3Title,
    AppStrings.step4Title,
    AppStrings.step5Title,
  ];
  static const List<String> _weightUnits = <String>['tonnes', 'kg'];

  final PageController _pageController = PageController();
  final GlobalKey<FormState> _routeFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _cargoFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _fareFormKey = GlobalKey<FormState>();

  final TextEditingController _pickupCity = TextEditingController();
  final TextEditingController _pickupAddress = TextEditingController();
  final TextEditingController _destinationCity = TextEditingController();
  final TextEditingController _destinationAddress = TextEditingController();
  final TextEditingController _cargoDescription = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _expectedFare = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  int _step = 0;
  bool _submitting = false;
  CargoCategory _category = CargoCategory.construction;
  VehicleType _vehicle = VehicleType.truck10w;
  String _weightUnit = _weightUnits.first;
  DateTime _pickupAt = _defaultPickupAt();

  static DateTime _defaultPickupAt() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 9);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pickupCity.dispose();
    _pickupAddress.dispose();
    _destinationCity.dispose();
    _destinationAddress.dispose();
    _cargoDescription.dispose();
    _weight.dispose();
    _expectedFare.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createShipment),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _StepHeader(
            step: _step,
            stepCount: _stepCount,
            title: _stepTitles[_step],
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                for (var i = 0; i < _stepCount; i++) _buildStep(i),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenHorizontal,
            AppSizes.sm,
            AppSizes.screenHorizontal,
            AppSizes.sm,
          ),
          child: Row(
            children: [
              if (_step > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : _back,
                    child: const Text(AppStrings.previous),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
              ],
              Expanded(
                flex: _step > 0 ? 1 : 2,
                // FilledButton.icon (rather than a hand-built Row) wraps
                // the label in a Flexible, so "Submitting..." can shrink
                // inside the tight button width on narrow screens instead
                // of overflowing.
                child: _submitting
                    ? FilledButton.icon(
                        onPressed: null,
                        icon: const SizedBox(
                          width: AppSizes.iconSm,
                          height: AppSizes.iconSm,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                        label: const Text(AppStrings.submitting),
                      )
                    : FilledButton(
                        onPressed: _next,
                        child: Text(
                          _step == _stepCount - 1
                              ? AppStrings.submit
                              : AppStrings.next,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int index) {
    switch (index) {
      case 0:
        return _routeStep();
      case 1:
        return _cargoStep();
      case 2:
        return _scheduleStep();
      case 3:
        return _vehicleStep();
      default:
        return _reviewStep();
    }
  }

  Widget _routeStep() {
    return _StepScroll(
      child: Form(
        key: _routeFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(AppStrings.pickupLocation),
            const SizedBox(height: AppSizes.sm),
            _textField(
              controller: _pickupCity,
              label: 'City',
              hint: 'Kathmandu',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSizes.md),
            _textField(
              controller: _pickupAddress,
              label: 'Address',
              hint: 'Kalimati, Kathmandu',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSizes.lg),
            _sectionTitle(AppStrings.destination),
            const SizedBox(height: AppSizes.sm),
            _textField(
              controller: _destinationCity,
              label: 'City',
              hint: 'Pokhara',
              textInputAction: TextInputAction.next,
              validator: _destinationCityValidator,
            ),
            const SizedBox(height: AppSizes.md),
            _textField(
              controller: _destinationAddress,
              label: 'Address',
              hint: 'Lakeside, Pokhara',
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cargoStep() {
    return _StepScroll(
      child: Form(
        key: _cargoFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(AppStrings.cargo),
            const SizedBox(height: AppSizes.sm),
            _textField(
              controller: _cargoDescription,
              label: AppStrings.cargoDescription,
              hint: 'Steel pipes, cement bags, furniture...',
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSizes.md),
            _SelectField<CargoCategory>(
              label: AppStrings.cargoCategory,
              value: _category,
              items: <(CargoCategory, String)>[
                for (final category in CargoCategory.values)
                  (category, category.label),
              ],
              onSelected: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _textField(
                    controller: _weight,
                    label: AppStrings.weight,
                    hint: '10',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    validator: _weightValidator,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                SizedBox(
                  width: 120,
                  child: _SelectField<String>(
                    label: AppStrings.weightUnit,
                    value: _weightUnit,
                    items: <(String, String)>[
                      for (final unit in _weightUnits) (unit, unit),
                    ],
                    onSelected: (value) => setState(() => _weightUnit = value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleStep() {
    return _StepScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(AppStrings.schedule),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: _PickerField(
                  label: AppStrings.pickupDate,
                  icon: Icons.calendar_today_outlined,
                  value: _pickupAt.formatDisplay(),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _PickerField(
                  label: AppStrings.pickupTime,
                  icon: Icons.schedule_outlined,
                  value: TimeOfDay.fromDateTime(_pickupAt).format(context),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _textField(
            controller: _notes,
            label: AppStrings.notes,
            hint: 'Loading instructions, contact notes...',
            maxLines: 3,
            textInputAction: TextInputAction.newline,
          ),
        ],
      ),
    );
  }

  Widget _vehicleStep() {
    return _StepScroll(
      child: Form(
        key: _fareFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(AppStrings.vehicleType),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: <Widget>[
                for (final type in VehicleType.values)
                  ChoiceChip(
                    label: Text(type.label),
                    selected: _vehicle == type,
                    onSelected: (selected) {
                      if (selected) setState(() => _vehicle = type);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            _textField(
              controller: _expectedFare,
              label: AppStrings.expectedFare,
              hint: '18000',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              validator: _fareValidator,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewStep() {
    final fare = _fareValue;
    return _StepScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryCard(
            title: AppStrings.step1Title,
            rows: <(String, String)>[
              (
                'Pickup',
                '${_pickupCity.text.trim()} · ${_pickupAddress.text.trim()}'
              ),
              (
                'Destination',
                '${_destinationCity.text.trim()} · '
                    '${_destinationAddress.text.trim()}',
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _SummaryCard(
            title: AppStrings.step2Title,
            rows: <(String, String)>[
              ('Description', _cargoDescription.text.trim()),
              ('Category', _category.label),
              ('Weight', _weightValue.toWeight(_weightUnit)),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _SummaryCard(
            title: AppStrings.step3Title,
            rows: <(String, String)>[
              (AppStrings.pickupDate, _pickupAt.formatWithTime()),
              if (_notes.text.trim().isNotEmpty)
                (AppStrings.notes, _notes.text.trim()),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _SummaryCard(
            title: AppStrings.step4Title,
            rows: <(String, String)>[
              (AppStrings.vehicleType, _vehicle.label),
              (
                AppStrings.expectedFare,
                fare > 0 ? fare.toNPR() : 'Not set',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    // Every single-line field goes through the same shared widget so text
    // fields, pickers and selects all render at the identical 50px height.
    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      // Multiline fields are taller by design; keep their label and cursor
      // anchored to the top instead of floating in the middle.
      textAlignVertical: maxLines > 1 ? TextAlignVertical.top : null,
      alignLabelWithHint: maxLines > 1,
      validator: validator ?? _requiredValidator,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
    return null;
  }

  String? _destinationCityValidator(String? value) {
    final required = _requiredValidator(value);
    if (required != null) return required;
    final pickup = _pickupCity.text.trim().toLowerCase();
    if (value!.trim().toLowerCase() == pickup) {
      return AppStrings.sameLocationError;
    }
    return null;
  }

  String? _weightValidator(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) return AppStrings.invalidWeight;
    return null;
  }

  String? _fareValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) return 'Enter a valid amount';
    return null;
  }

  double get _weightValue => double.tryParse(_weight.text.trim()) ?? 0;

  double get _fareValue => double.tryParse(_expectedFare.text.trim()) ?? 0;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupAt,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      _pickupAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _pickupAt.hour,
        _pickupAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_pickupAt),
    );
    if (picked == null) return;
    setState(() {
      _pickupAt = DateTime(
        _pickupAt.year,
        _pickupAt.month,
        _pickupAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _back() {
    if (_step == 0) return;
    FocusScope.of(context).unfocus();
    setState(() => _step -= 1);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _next() {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_validateCurrentStep()) return;
    if (_step == _stepCount - 1) {
      _submit();
      return;
    }
    setState(() => _step += 1);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        _step,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        return _routeFormKey.currentState?.validate() ?? false;
      case 1:
        return _cargoFormKey.currentState?.validate() ?? false;
      case 2:
        final earliest = DateTime.now().subtract(const Duration(hours: 1));
        if (_pickupAt.isBefore(earliest)) {
          _showSnack(AppStrings.pastDateError);
          return false;
        }
        return true;
      case 3:
        return _fareFormKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  CreateShipmentDraft _buildDraft() {
    return CreateShipmentDraft(
      pickupCity: _pickupCity.text.trim(),
      pickupAddress: _pickupAddress.text.trim(),
      destinationCity: _destinationCity.text.trim(),
      destinationAddress: _destinationAddress.text.trim(),
      cargoDescription: _cargoDescription.text.trim(),
      cargoCategory: _category.wire,
      weight: _weightValue,
      weightUnit: _weightUnit,
      vehicleType: _vehicle.wire,
      pickupAt: _pickupAt,
      expectedFare: _fareValue,
      notes: _notes.text.trim(),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final draft = _buildDraft();
    setState(() => _submitting = true);
    try {
      ShipmentValidation.validate(draft);
      await ref.read(shipmentNotifierProvider.future);
      if (!mounted) return;
      final created = await ref
          .read(shipmentNotifierProvider.notifier)
          .createShipment(draft);
      if (!mounted) return;
      setState(() => _submitting = false);
      // Only reset the form after the submission actually persisted.
      _resetForm();
      context.go(AppRoutes.orderPlaced, extra: created);
    } on LimitException {
      if (!mounted) return;
      setState(() => _submitting = false);
      // The limit dialog keeps every entered value — nothing is cleared.
      await _showLimitDialog();
    } on AppException catch (error) {
      if (!mounted) return;
      _showSnack(error.message);
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppStrings.genericError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showLimitDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.requestLimitTitle),
          content: const Text(AppStrings.requestLimitMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppStrings.gotIt),
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    setState(() {
      _pickupCity.clear();
      _pickupAddress.clear();
      _destinationCity.clear();
      _destinationAddress.clear();
      _cargoDescription.clear();
      _weight.clear();
      _expectedFare.clear();
      _notes.clear();
      _category = CargoCategory.construction;
      _vehicle = VehicleType.truck10w;
      _weightUnit = _weightUnits.first;
      _pickupAt = _defaultPickupAt();
      _step = 0;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.stepCount,
    required this.title,
  });

  final int step;
  final int stepCount;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenHorizontal,
        AppSizes.md,
        AppSizes.screenHorizontal,
        AppSizes.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Step ${step + 1} of $stepCount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: LinearProgressIndicator(
              value: (step + 1) / stepCount,
              minHeight: 6,
              backgroundColor: AppColors.surfaceVariant,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepScroll extends StatelessWidget {
  const _StepScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenHorizontal,
        AppSizes.sm,
        AppSizes.screenHorizontal,
        AppSizes.lg,
      ),
      child: child,
    );
  }
}

class _SelectField<T> extends StatelessWidget {
  const _SelectField({
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
  });

  final String label;
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onSelected;
  String get _valueLabel {
    for (final item in items) {
      if (item.$1 == value) return item.$2;
    }
    return items.first.$2;
  }

  Future<void> _open(BuildContext context) async {
    final selected = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenHorizontal,
                  0,
                  AppSizes.screenHorizontal,
                  AppSizes.sm,
                ),
                child: Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  children: <Widget>[
                    for (final item in items)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.screenHorizontal,
                        ),
                        title: Text(item.$2),
                        trailing: item.$1 == value
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () => Navigator.of(sheetContext).pop(item.$1),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null && selected != value) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    // Rendered through the same AppTextField as every text input so the
    // select is pixel-identical in height and typography. A DropdownButton
    // inside an InputDecorator adds its own 48px min height and made the form
    // jump by ~30px — that was the "up and down" misalignment.
    return ExcludeFocus(
      child: AppTextField(
        key: ValueKey<T>(value),
        initialValue: _valueLabel,
        label: label,
        readOnly: true,
        textInputAction: TextInputAction.none,
        suffixIcon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: AppSizes.iconMd,
        ),
        onTap: () => _open(context),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Same AppTextField shell as the text inputs so date/time fields line up
    // exactly with the text fields around them.
    return ExcludeFocus(
      child: AppTextField(
        key: ValueKey<String>(value),
        initialValue: value,
        label: label,
        readOnly: true,
        textInputAction: TextInputAction.none,
        suffixIcon: Icon(icon, size: AppSizes.iconMd),
        onTap: onTap,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSizes.sm),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      row.$1,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
