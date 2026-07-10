import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_member_entity.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_formatters.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_stepper.dart';

/// Result returned by the add/edit meal form when the manager saves.
class MemberMealFormResult {
  const MemberMealFormResult({required this.memberId, required this.date, required this.breakfast, required this.lunch, required this.dinner});

  final String memberId;
  final DateTime date;
  final double breakfast;
  final double lunch;
  final double dinner;
}

/// Shows the add/edit meal bottom sheet and resolves to the saved values, or
/// `null` if dismissed.
///
/// When [existing] is provided the form is in edit mode: the member and date
/// are locked (they identify the record) and only the counts can change.
Future<MemberMealFormResult?> showMemberMealForm(BuildContext context, {required List<MealMemberEntity> members, MemberMealEntity? existing, String? presetMemberId, DateTime? presetDate, bool mealOnlyEdit = false}) {
  return context.showAdaptiveSheet<MemberMealFormResult>(
    child: _MemberMealFormSheet(members: members, existing: existing, presetMemberId: presetMemberId, presetDate: presetDate, mealOnlyEdit: mealOnlyEdit),
  );
}

class _MemberMealFormSheet extends StatefulWidget {
  const _MemberMealFormSheet({required this.members, this.existing, this.presetMemberId, this.presetDate, this.mealOnlyEdit = false});

  final List<MealMemberEntity> members;
  final MemberMealEntity? existing;
  final String? presetMemberId;
  final DateTime? presetDate;
  final bool mealOnlyEdit;

  @override
  State<_MemberMealFormSheet> createState() => _MemberMealFormSheetState();
}

class _MemberMealFormSheetState extends State<_MemberMealFormSheet> {
  late String _memberId;
  late DateTime _date;
  late double _breakfast;
  late double _lunch;
  late double _dinner;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final now = DateTime.now();
    _memberId = existing?.memberId ?? widget.presetMemberId ?? widget.members.first.id;
    final date = existing?.date ?? widget.presetDate ?? now;
    _date = DateTime(date.year, date.month, date.day);
    _breakfast = existing?.breakfast ?? 0;
    _lunch = existing?.lunch ?? 0;
    _dinner = existing?.dinner ?? 0;
  }

  double get _total => _breakfast + _lunch + _dinner;

  String get _memberName {
    for (final member in widget.members) {
      if (member.id == _memberId) return member.name;
    }
    return 'Member';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(now.year - 1), lastDate: DateTime(now.year + 1, now.month, now.day));
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _submit() {
    Navigator.of(context).pop(MemberMealFormResult(memberId: _memberId, date: _date, breakfast: _breakfast, lunch: _lunch, dinner: _dinner));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.mealOnlyEdit && _isEdit ? 'Edit $_memberName meal' : _isEdit ? 'Edit meal' : 'Add meal',
          style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        if (!widget.mealOnlyEdit) ...[
          _FieldLabel(label: 'Member'),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _MemberField(members: widget.members, memberId: _memberId, enabled: !_isEdit, onChanged: (id) => setState(() => _memberId = id)),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          _FieldLabel(label: 'Date'),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _DateField(date: _date, enabled: !_isEdit, onTap: _pickDate),
          const SizedBox(height: Dimensions.paddingSizeLarge),
        ],
        _StepperRow(icon: Icons.free_breakfast_rounded, label: 'Breakfast', accent: colors.warningColor, value: _breakfast, onChanged: (v) => setState(() => _breakfast = v)),
        const Divider(height: Dimensions.paddingSizeLarge),
        _StepperRow(icon: Icons.lunch_dining_rounded, label: 'Lunch', accent: colors.primaryColor, value: _lunch, onChanged: (v) => setState(() => _lunch = v)),
        const Divider(height: Dimensions.paddingSizeLarge),
        _StepperRow(icon: Icons.dinner_dining_rounded, label: 'Dinner', accent: colors.infoColor, value: _dinner, onChanged: (v) => setState(() => _dinner = v)),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        Row(
          children: [
            Text(
              'Total',
              style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textSecondaryColor),
            ),
            const Spacer(),
            Text(
              '${MealFormatters.count(_total)} meals',
              style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.primaryColor),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(onPressed: _total > 0 ? _submit : null, icon: const Icon(Icons.check_rounded), label: Text(_isEdit ? 'Save changes' : 'Add meal')),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Text(
      label,
      style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textSecondaryColor),
    );
  }
}

class _MemberField extends StatelessWidget {
  const _MemberField({required this.members, required this.memberId, required this.enabled, required this.onChanged});

  final List<MealMemberEntity> members;
  final String memberId;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: memberId,
          isExpanded: true,
          icon: Icon(Icons.expand_more_rounded, color: colors.textHintColor),
          items: [
            for (final m in members)
              DropdownMenuItem(
                value: m.id,
                child: Text(
                  m.name,
                  style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
                ),
              ),
          ],
          onChanged: enabled ? (v) => v != null ? onChanged(v) : null : null,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.enabled, required this.onTap});

  final DateTime date;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeLarge),
        decoration: BoxDecoration(
          color: colors.backgroundColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, size: Dimensions.iconSizeDefault, color: colors.primaryColor),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Text(
              MealFormatters.dayLabel(date),
              style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
            ),
            const Spacer(),
            if (enabled) Icon(Icons.edit_calendar_rounded, size: Dimensions.iconSizeSmall, color: colors.textHintColor),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({required this.icon, required this.label, required this.accent, required this.value, required this.onChanged});

  final IconData icon;
  final String label;
  final Color accent;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
          child: Icon(icon, color: accent, size: Dimensions.iconSizeDefault),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
          ),
        ),
        MealStepper(value: value, onChanged: onChanged, accent: accent),
      ],
    );
  }
}
