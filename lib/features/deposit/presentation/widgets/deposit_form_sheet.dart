import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/features/deposit/domain/entities/deposit_entity.dart';
import 'package:mess_pilot/features/deposit/presentation/widgets/deposit_formatters.dart';

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
    child: DepositForm(members: members, existing: existing, onSave: onSave),
  );
}

/// Add / edit deposit form.
///
/// Reused both inside the [showDepositFormSheet] sheet and inline in the
/// "Add deposit" tab. When [popOnSave] is false the caller owns navigation
/// after a save; [onCancel] lets an inline host switch away from the form.
class DepositForm extends StatefulWidget {
  const DepositForm({required this.members, required this.onSave, this.existing, this.popOnSave = true, this.onCancel, this.showHeader = true, this.inline = false, super.key});

  final List<DepositMemberEntity> members;
  final DepositEntity? existing;
  final void Function({required String memberId, required double amount, required DateTime date, String? note}) onSave;
  final bool popOnSave;
  final VoidCallback? onCancel;
  final bool showHeader;

  /// Full-page presentation: a live preview card above a sectioned form.
  final bool inline;

  @override
  State<DepositForm> createState() => _DepositFormState();
}

class _DepositFormState extends State<DepositForm> {
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
    final picked = await showDatePicker(context: context, locale: const Locale('en'), initialDate: _date, firstDate: DateTime(_date.year - 2), lastDate: DateTime(_date.year + 2));
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_memberId == null) {
      context.showErrorSnackBar(context.local.selectMember);
      return;
    }
    final magnitude = double.parse(_amountController.text.trim());
    final signed = _type == DepositType.debit ? -magnitude : magnitude;
    final note = _noteController.text.trim();

    widget.onSave(memberId: _memberId!, amount: signed, date: _date, note: note.isEmpty ? null : note);
    if (widget.popOnSave) Navigator.of(context).pop();
  }

  void _cancel() {
    final onCancel = widget.onCancel;
    if (onCancel != null) {
      onCancel();
    } else {
      Navigator.of(context).pop();
    }
  }

  String _resolvedMemberName() {
    final existing = widget.existing;
    if (existing != null) return existing.memberName;
    for (final m in widget.members) {
      if (m.id == _memberId) return m.name;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    // Member — dropdown when adding, read-only when editing.
    final memberField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(context.local.roleMember),
        if (_isEdit)
          _ReadOnlyField(value: widget.existing!.memberName)
        else
          DropdownButtonFormField<String>(
            initialValue: _memberId,
            decoration: _fieldDecoration(context),
            items: [for (final m in widget.members) DropdownMenuItem(value: m.id, child: Text(m.name))],
            onChanged: (v) => setState(() => _memberId = v),
            validator: (v) => v == null ? context.local.selectMember : null,
          ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
      ],
    );

    final typeField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(context.local.type),
        _TypeToggle(type: _type, onChanged: (t) => setState(() => _type = t)),
        const SizedBox(height: Dimensions.paddingSizeDefault),
      ],
    );

    // Amount (magnitude — the sign comes from the type toggle).
    final amountField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(context.local.amountTaka),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
          style: widget.inline ? AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeOverLarge, color: colors.textPrimaryColor) : null,
          decoration: _fieldDecoration(context, hint: '0.00', prefixText: widget.inline ? '৳ ' : null),
          onChanged: widget.inline ? (_) => setState(() {}) : null,
          validator: (v) {
            final value = double.tryParse((v ?? '').trim());
            if (value == null || value <= 0) {
              return context.local.amountMustBePositive;
            }
            return null;
          },
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
      ],
    );

    final dateField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(context.local.date),
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
      ],
    );

    final noteField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(context.local.noteOptional),
        TextFormField(
          controller: _noteController,
          textInputAction: TextInputAction.done,
          decoration: _fieldDecoration(context, hint: 'e.g. Monthly deposit'),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraLarge),
      ],
    );

    final fields = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.inline && widget.showHeader) ...[
          Text(
            _isEdit ? context.local.uiEditDeposit : context.local.uiAddDeposit,
            style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
          ),
          Text(
            context.local.uiRecordedForOneMemberAtATime,
            style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
        ],
        memberField,
        typeField,
        amountField,
        dateField,
        noteField,
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancel,
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeight)),
                child: Text(context.local.cancel),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeight)),
                child: Text(_isEdit ? context.local.save : context.local.add),
              ),
            ),
          ],
        ),
      ],
    );

    return Form(
      key: _formKey,
      child: widget.inline ? _inlineLayout(context, fields) : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [fields]),
    );
  }

  /// Inline (full-page) layout: preview above the form on phones, side by side
  /// once there is room on tablet / desktop.
  Widget _inlineLayout(BuildContext context, Widget fields) {
    final preview = _DepositPreviewCard(
      type: _type,
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      memberName: _resolvedMemberName(),
      date: _date,
      isEdit: _isEdit,
    );
    final section = _FormSectionCard(
      title: context.local.uiDetails,
      icon: Icons.edit_note_rounded,
      child: fields,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 860) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: preview),
              const SizedBox(width: Dimensions.paddingSizeLarge),
              Expanded(flex: 3, child: section),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [preview, const SizedBox(height: Dimensions.paddingSizeLarge), section],
        );
      },
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, {String? hint, String? prefixText}) {
    final colors = context.customThemeColors;
    return InputDecoration(
      isDense: true,
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeOverLarge, color: colors.textSecondaryColor),
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
          child: _Segment(label: context.local.credit, icon: Icons.south_west_rounded, selected: type == DepositType.credit, accent: colors.successColor, onTap: () => onChanged(DepositType.credit)),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: _Segment(label: context.local.debit, icon: Icons.north_east_rounded, selected: type == DepositType.debit, accent: colors.errorColor, onTap: () => onChanged(DepositType.debit)),
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

/// Live summary of the deposit being entered, shown above the inline form.
class _DepositPreviewCard extends StatelessWidget {
  const _DepositPreviewCard({required this.type, required this.amount, required this.memberName, required this.date, required this.isEdit});

  final DepositType type;
  final double amount;
  final String memberName;
  final DateTime date;
  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final credit = type == DepositType.credit;
    final accent = credit ? colors.successColor : colors.errorColor;
    final secondary = credit ? colors.primaryColor : colors.warningColor;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: context.isDarkMode ? 0.26 : 0.12),
            secondary.withValues(alpha: context.isDarkMode ? 0.16 : 0.06),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: Icon(credit ? Icons.south_west_rounded : Icons.north_east_rounded, color: accent, size: Dimensions.iconSizeDefault),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? context.local.uiEditDeposit : context.local.uiAddDeposit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
                    ),
                    Text(
                      credit ? context.local.credit : context.local.debit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text(
            DepositFormatters.taka(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraOverLarge + 10, color: accent),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: Dimensions.iconSizeSmall, color: colors.textSecondaryColor),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: Text(
                  memberName.isEmpty ? context.local.selectMember : memberName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textSecondaryColor),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
                decoration: BoxDecoration(color: colors.cardBackgroundColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_rounded, size: Dimensions.iconSizeSmall, color: colors.textSecondaryColor),
                    const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                    Text(
                      DepositFormatters.date(date),
                      maxLines: 1,
                      style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rounded, bordered surface holding the inline deposit fields.
class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: colors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                child: Icon(icon, size: Dimensions.iconSizeSmall, color: colors.primaryColor),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          child,
        ],
      ),
    );
  }
}
