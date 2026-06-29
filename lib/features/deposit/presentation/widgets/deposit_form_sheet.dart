import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/features/deposit/domain/entities/deposit_entity.dart';
import 'package:clean_boilerplate/features/deposit/presentation/widgets/deposit_formatters.dart';

/// Opens the add / edit deposit bottom sheet.
///
/// When [existing] is null this records a new deposit for **one** member
/// chosen from [members]; otherwise it edits that deposit in place (the member
/// is fixed). [onSave] receives the signed amount — positive for a credit,
/// negative for a debit.
Future<void> showDepositFormSheet({
  required BuildContext context,
  required List<DepositMemberEntity> members,
  required void Function({required String memberId, required double amount, required DateTime date, String? note}) onSave,
  DepositEntity? existing,
}) {
  return context.showAdaptiveSheet<void>(
    child: _DepositFormSheet(members: members, existing: existing, onSave: onSave),
  );
}

class _DepositFormSheet extends StatefulWidget {
  const _DepositFormSheet({required this.members, required this.existing, required this.onSave});

  final List<DepositMemberEntity> members;
  final DepositEntity? existing;
  final void Function({required String memberId, required double amount, required DateTime date, String? note}) onSave;

  @override
  State<_DepositFormSheet> createState() => _DepositFormSheetState();
}

class _DepositFormSheetState extends State<_DepositFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  String? _memberId;
  late DepositType _type;
  late DateTime _date;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _memberId = existing?.memberId ?? (widget.members.isNotEmpty ? widget.members.first.id : null);
    _type = existing?.type ?? DepositType.credit;
    _date = existing?.date ?? DateTime.now();
    _amountController = TextEditingController(text: existing != null ? DepositFormatters.taka(existing.absoluteAmount).replaceAll('৳', '') : '');
    _noteController = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(_date.year - 2), lastDate: DateTime(_date.year + 2));
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_memberId == null) {
      context.showErrorSnackBar('Please select a member');
      return;
    }
    final magnitude = double.parse(_amountController.text.trim());
    final signed = _type == DepositType.debit ? -magnitude : magnitude;
    final note = _noteController.text.trim();

    widget.onSave(memberId: _memberId!, amount: signed, date: _date, note: note.isEmpty ? null : note);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEdit ? 'Edit deposit' : 'Add deposit',
            style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
          ),
          Text(
            'Recorded for one member at a time',
            style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // Member — dropdown when adding, read-only when editing.
          _Label('Member'),
          if (_isEdit)
            _ReadOnlyField(value: widget.existing!.memberName)
          else
            DropdownButtonFormField<String>(
              initialValue: _memberId,
              decoration: _fieldDecoration(context),
              items: [for (final m in widget.members) DropdownMenuItem(value: m.id, child: Text(m.name))],
              onChanged: (v) => setState(() => _memberId = v),
              validator: (v) => v == null ? 'Select a member' : null,
            ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          // Credit / debit toggle.
          _Label('Type'),
          _TypeToggle(type: _type, onChanged: (t) => setState(() => _type = t)),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          // Amount (magnitude — the sign comes from the type toggle).
          _Label('Amount (৳)'),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
            decoration: _fieldDecoration(context, hint: '0.00'),
            validator: (v) {
              final value = double.tryParse((v ?? '').trim());
              if (value == null || value <= 0) {
                return 'Enter an amount greater than 0';
              }
              return null;
            },
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          // Date.
          _Label('Date'),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: InputDecorator(
              decoration: _fieldDecoration(context),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: Dimensions.iconSizeSmall, color: colors.textSecondaryColor),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Text(
                    DepositFormatters.date(_date),
                    style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          // Note (optional).
          _Label('Note (optional)'),
          TextFormField(
            controller: _noteController,
            textInputAction: TextInputAction.done,
            decoration: _fieldDecoration(context, hint: 'e.g. Monthly deposit'),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeightDefault)),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeightDefault)),
                  child: Text(_isEdit ? 'Save' : 'Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, {String? hint}) {
    final colors = context.customThemeColors;
    return InputDecoration(
      isDense: true,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
      filled: true,
      fillColor: colors.cardBackgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        borderSide: BorderSide(color: colors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        borderSide: BorderSide(color: colors.borderColor),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
      child: Text(
        text,
        style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: colors.borderColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(color: colors.borderColor),
      ),
      child: Text(
        value,
        style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor),
      ),
    );
  }
}

/// Segmented Credit / Debit selector.
class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.type, required this.onChanged});
  final DepositType type;
  final ValueChanged<DepositType> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Row(
      children: [
        Expanded(
          child: _Segment(label: 'Credit', icon: Icons.south_west_rounded, selected: type == DepositType.credit, accent: colors.successColor, onTap: () => onChanged(DepositType.credit)),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: _Segment(label: 'Debit', icon: Icons.north_east_rounded, selected: type == DepositType.debit, accent: colors.errorColor, onTap: () => onChanged(DepositType.debit)),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.icon, required this.selected, required this.accent, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Material(
      color: selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(color: selected ? accent : colors.borderColor, width: selected ? 1.4 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: Dimensions.iconSizeSmall, color: selected ? accent : colors.textSecondaryColor),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Text(
                label,
                style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: selected ? accent : colors.textSecondaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
