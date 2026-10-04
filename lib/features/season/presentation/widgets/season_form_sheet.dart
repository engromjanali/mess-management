import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_entity.dart';
import 'package:clean_boilerplate/features/season/presentation/widgets/season_formatters.dart';

/// The form's values. [sourceSeasonId] is set when creating, [endDate] only
/// when editing (null = running).
typedef SeasonFormResult = ({String name, DateTime startDate, DateTime? endDate, String? sourceSeasonId});

/// Saves the form; completes with null on success or the [Failure].
typedef SeasonSubmit = Future<Failure?> Function(SeasonFormResult result);

/// Opens the season form (dialog on wide screens, bottom sheet on phones):
/// "New season" when [existing] is null — with a "Copy members from" picker
/// over [sources], preset to [defaultSourceId] — otherwise "Edit season" with
/// an optional end date. Stays open while saving and shows the backend's
/// errors under their fields. Resolves to the saved name, or null if cancelled.
Future<String?> showSeasonFormSheet(
  BuildContext context, {
  required SeasonSubmit onSubmit,
  SeasonEntity? existing,
  List<SeasonEntity> sources = const [],
  String? defaultSourceId,
}) {
  return context.showAdaptiveSheet<String>(
    child: _SeasonForm(existing: existing, sources: sources, defaultSourceId: defaultSourceId, onSubmit: onSubmit),
  );
}

class _SeasonForm extends StatefulWidget {
  const _SeasonForm({required this.existing, required this.sources, required this.defaultSourceId, required this.onSubmit});

  final SeasonEntity? existing;
  final List<SeasonEntity> sources;
  final String? defaultSourceId;
  final SeasonSubmit onSubmit;

  @override
  State<_SeasonForm> createState() => _SeasonFormState();
}

class _SeasonFormState extends State<_SeasonForm> {
  /// Backend fields this form shows errors under.
  static const _fields = {'name', 'start_date', 'end_date', 'source_season_id'};

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.name ?? SeasonFormatters.autoName());
  late DateTime _startDate = widget.existing?.startDate ?? DateUtils.dateOnly(DateTime.now());
  late DateTime? _endDate = widget.existing?.endDate;
  late String? _sourceId = widget.sources.any((s) => s.id == widget.defaultSourceId) ? widget.defaultSourceId : widget.sources.firstOrNull?.id;
  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final endDate = _endDate;
    return PopScope(
      canPop: !_submitting,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_isEdit ? context.local.editSeason : context.local.newSeason, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
            if (!_isEdit) ...[
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(context.local.newSeasonNote, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor)),
            ],
            const SizedBox(height: Dimensions.paddingSizeLarge),
            TextFormField(
              controller: _nameController,
              enabled: !_submitting,
              autofocus: !_isEdit,
              maxLength: 100,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: context.local.seasonNameLabel, prefixIcon: const Icon(Icons.label_outline_rounded)),
              forceErrorText: _fieldErrors['name'],
              validator: (value) => (value?.trim().isEmpty ?? true) ? context.local.seasonNameRequired : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _DateField(
              label: context.local.seasonStartDate,
              value: SeasonFormatters.date(_startDate),
              error: _fieldErrors['start_date'],
              onTap: _submitting ? null : () => _pickDate(start: true),
            ),
            if (_isEdit) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              _DateField(
                label: context.local.seasonEndDate,
                value: endDate == null ? null : SeasonFormatters.date(endDate),
                hint: context.local.seasonEndDateHint,
                error: _fieldErrors['end_date'],
                onTap: _submitting ? null : () => _pickDate(start: false),
                onClear: endDate == null || _submitting ? null : () => setState(() => _endDate = null),
              ),
            ] else if (widget.sources.isNotEmpty) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              DropdownButtonFormField<String>(
                initialValue: _sourceId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.local.copyMembersFrom,
                  helperText: context.local.copyMembersFromHint,
                  helperMaxLines: 2,
                  prefixIcon: const Icon(Icons.group_outlined),
                  errorText: _fieldErrors['source_season_id'],
                ),
                items: [
                  for (final season in widget.sources)
                    DropdownMenuItem(
                      value: season.id,
                      child: Text('${season.name} · ${context.local.seasonMemberCount(season.memberCount)}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: _submitting ? null : (value) => setState(() => _sourceId = value),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded, size: Dimensions.iconSizeSmall, color: colors.errorColor),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Expanded(child: Text(_error!, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.errorColor))),
                ],
              ),
            ],
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(), child: Text(context.local.cancel)),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? context.local.save : context.local.create, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate ?? DateUtils.dateOnly(now),
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    final endDate = _endDate;
    setState(() {
      _error = null;
      _fieldErrors = endDate != null && endDate.isBefore(_startDate) ? {'end_date': context.local.seasonEndBeforeStart} : const {};
    });
    if (!(_formKey.currentState?.validate() ?? false) || _fieldErrors.isNotEmpty) return;

    final name = _nameController.text.trim();
    setState(() => _submitting = true);
    final failure = await widget.onSubmit((name: name, startDate: _startDate, endDate: endDate, sourceSeasonId: _isEdit ? null : _sourceId));
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(name);
      return;
    }
    final fieldErrors = failure is ServerFailure ? failure.fieldErrors : const <String, String>{};
    setState(() {
      _submitting = false;
      _fieldErrors = fieldErrors;
      // Field errors show under their field; anything else shows here.
      _error = fieldErrors.keys.any(_fields.contains) ? null : failure.message;
    });
  }
}

/// Tappable date input; shows [hint] when [value] is null and a clear
/// button when [onClear] is set. Disabled when [onTap] is null.
class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap, this.hint, this.error, this.onClear});

  final String label;
  final String? value;
  final String? hint;
  final String? error;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: error,
          errorMaxLines: 2,
          enabled: onTap != null,
          prefixIcon: const Icon(Icons.calendar_today_rounded),
          suffixIcon: onClear == null ? null : IconButton(tooltip: MaterialLocalizations.of(context).deleteButtonTooltip, onPressed: onClear, icon: const Icon(Icons.close_rounded)),
        ),
        child: Text(value ?? ''),
      ),
    );
  }
}
