import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';
import 'package:clean_boilerplate/features/cost/presentation/widgets/cost_formatters.dart';

/// Reusable bazar entry form — used both in the "Bazar Entry" tab (add) and in
/// a bottom sheet (edit). Collects a person, a date + time, and a dynamic list
/// of product / price rows, showing a live running total.
class CostEntryForm extends StatefulWidget {
  const CostEntryForm({required this.members, required this.onSubmit, this.existing, super.key});

  final List<CostMemberEntity> members;
  final CostEntity? existing;
  final void Function({required String personId, required DateTime date, required List<CostItemEntity> items}) onSubmit;

  @override
  State<CostEntryForm> createState() => _CostEntryFormState();
}

class _ItemRow {
  final TextEditingController product;
  final TextEditingController price;
  _ItemRow({String product = '', String price = ''}) : product = TextEditingController(text: product), price = TextEditingController(text: price);

  void dispose() {
    product.dispose();
    price.dispose();
  }
}

class _CostEntryFormState extends State<CostEntryForm> {
  final _formKey = GlobalKey<FormState>();
  late String? _personId;
  late DateTime _date;
  late List<_ItemRow> _rows;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _personId = existing?.personId ?? (widget.members.isNotEmpty ? widget.members.first.id : null);
    _date = existing?.date ?? DateTime.now();
    _rows = existing != null && existing.items.isNotEmpty ? existing.items.map((i) => _ItemRow(product: i.product, price: CostFormatters.number(i.price))).toList() : [_ItemRow()];
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  double get _total {
    var sum = 0.0;
    for (final r in _rows) {
      sum += double.tryParse(r.price.text.trim()) ?? 0;
    }
    return sum;
  }

  void _addRow() => setState(() => _rows.add(_ItemRow()));

  void _removeRow(int i) {
    setState(() {
      _rows.removeAt(i).dispose();
      if (_rows.isEmpty) _rows.add(_ItemRow());
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(_date.year - 2), lastDate: DateTime(_date.year + 2));
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (picked != null) {
      setState(() => _date = DateTime(_date.year, _date.month, _date.day, picked.hour, picked.minute));
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_personId == null) {
      context.showErrorSnackBar('Please select a member');
      return;
    }
    final items = <CostItemEntity>[];
    for (final r in _rows) {
      final product = r.product.text.trim();
      final price = double.tryParse(r.price.text.trim()) ?? 0;
      if (product.isEmpty || price <= 0) continue;
      items.add(CostItemEntity(product: product, price: price));
    }
    if (items.isEmpty) {
      context.showErrorSnackBar('Add at least one product with a price');
      return;
    }
    widget.onSubmit(personId: _personId!, date: _date, items: items);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Label('Member'),
          DropdownButtonFormField<String>(
            initialValue: _personId,
            decoration: _decoration(context),
            items: [for (final m in widget.members) DropdownMenuItem(value: m.id, child: Text(m.name))],
            onChanged: (v) => setState(() => _personId = v),
            validator: (v) => v == null ? 'Select a member' : null,
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          // Date + time.
          Row(
            children: [
              Expanded(
                child: _PickerField(label: 'Bazar Date', icon: Icons.calendar_today_rounded, value: CostFormatters.date(_date), onTap: _pickDate),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: _PickerField(label: 'Bazar Time', icon: Icons.access_time_rounded, value: CostFormatters.time(_date), onTap: _pickTime),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // Products.
          Row(
            children: [
              Expanded(child: _Label('Products')),
              TextButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add_rounded, size: Dimensions.iconSizeSmall),
                label: const Text('Add product'),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          for (var i = 0; i < _rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _rows[i].product,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration(context, hint: 'Product'),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _rows[i].price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                      decoration: _decoration(context, hint: 'Price'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.remove_circle_outline_rounded, color: colors.errorColor),
                    onPressed: () => _removeRow(i),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Live total.
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
                ),
                Text(
                  CostFormatters.taka(_total),
                  style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          SizedBox(
            height: Dimensions.buttonHeightLarge,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: Icon(_isEdit ? Icons.save_rounded : Icons.check_rounded),
              label: Text(_isEdit ? 'Save changes' : 'Save bazar entry'),
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge))),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, {String? hint}) {
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

/// A tappable field that shows a label and a picked value.
class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.icon, required this.value, required this.onTap});

  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: colors.cardBackgroundColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              border: Border.all(color: colors.borderColor),
            ),
            child: Row(
              children: [
                Icon(icon, size: Dimensions.iconSizeSmall, color: colors.textSecondaryColor),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
