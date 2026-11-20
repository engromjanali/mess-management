import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/errors/failures.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/core/widgets/app_page_scroll_view.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';
import 'package:mess_pilot/features/poll/presentation/widgets/poll_formatters.dart';

/// Saves the form; completes with null on success or the [Failure].
typedef PollSubmit = Future<Failure?> Function(PollDraft draft);

/// Opens the create / edit poll sheet; completes with `true` once saved.
///
/// When [existing] is null this creates a poll for [initialDate]. Existing
/// polls keep their date; options are locked once members have voted.
Future<bool?> showPollFormSheet({
  required BuildContext context,
  required PollSubmit onSubmit,
  DateTime? initialDate,
  PollEntity? existing,
}) {
  return context.showAdaptiveSheet<bool>(
    child: PollForm(existing: existing, initialDate: initialDate ?? DateTime.now(), onSubmit: onSubmit),
  );
}

class PollForm extends StatefulWidget {
  const PollForm({required this.initialDate, required this.onSubmit, this.existing, this.embedded = false, this.onSaved, super.key});

  final DateTime initialDate;
  final PollSubmit onSubmit;
  final PollEntity? existing;

  /// Shown inline on a page instead of inside the adaptive sheet.
  final bool embedded;
  final VoidCallback? onSaved;

  @override
  State<PollForm> createState() => _PollFormState();
}

class _PollFormState extends State<PollForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final List<TextEditingController> _optionControllers;
  late DateTime _pollDate;
  late bool _allowMultiple;
  late int _maxChoices;
  late bool _anonymous;
  late PollResultsVisibility _resultsVisibility;

  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};
  String? _error;

  PollEntity? get _existing => widget.existing;
  bool get _isEdit => _existing != null;
  bool get _lockOptions => _existing != null && !_existing!.canEditOptions;
  bool get _lockDate => _existing != null;

  @override
  void initState() {
    super.initState();
    final existing = _existing;
    final today = DateTime.now();
    final initial = existing?.pollDate ?? widget.initialDate;
    final earliest = DateTime(today.year, today.month, today.day);
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _pollDate = existing != null || !initial.isBefore(earliest) ? DateTime(initial.year, initial.month, initial.day) : earliest;
    _allowMultiple = existing?.allowMultiple ?? false;
    _maxChoices = existing?.maxChoices ?? 1;
    _anonymous = existing?.isAnonymous ?? true;
    _resultsVisibility = existing?.resultsVisibility ?? PollResultsVisibility.afterVote;
    final options = existing?.options.map((option) => option.text).toList() ?? const <String>[];
    _optionControllers = [
      for (var index = 0; index < (options.isEmpty ? 2 : options.length); index++)
        TextEditingController(text: index < options.length ? options[index] : ''),
    ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (_lockDate) return;
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _pollDate.isBefore(firstDate) ? firstDate : _pollDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _pollDate = DateTime(picked.year, picked.month, picked.day));
  }

  void _addOption() {
    if (_optionControllers.length >= 10) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers.removeAt(index).dispose();
      if (_maxChoices > _optionControllers.length) _maxChoices = _optionControllers.length;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _fieldErrors = const {};
      _error = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final options = _optionControllers.map((controller) => controller.text.trim()).where((text) => text.isNotEmpty).toList();
    if (options.length < 2) {
      setState(() => _fieldErrors = {'options': context.local.pollAtLeastTwo});
      return;
    }
    if (options.map((text) => text.toLowerCase()).toSet().length != options.length) {
      setState(() => _fieldErrors = {'options': context.local.pollUniqueOptions});
      return;
    }

    final draft = PollDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      pollDate: _pollDate,
      options: options,
      allowMultiple: _allowMultiple,
      maxChoices: _allowMultiple ? _maxChoices.clamp(1, options.length) : 1,
      isAnonymous: _anonymous,
      resultsVisibility: _resultsVisibility,
    );

    setState(() => _submitting = true);
    final failure = await widget.onSubmit(draft);
    if (!mounted) return;
    if (failure == null) {
      if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        Navigator.of(context).pop(true);
      }
      return;
    }
    final fieldErrors = failure is ServerFailure ? failure.fieldErrors : const <String, String>{};
    const inlineFields = {'title', 'description', 'options'};
    final unmatched = fieldErrors.entries.where((entry) => !inlineFields.contains(entry.key)).map((entry) => entry.value);
    setState(() {
      _submitting = false;
      _fieldErrors = fieldErrors;
      _error = unmatched.isNotEmpty ? unmatched.join('\n') : (fieldErrors.isEmpty ? failure.message : null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final fields = _buildFields(context);

    if (widget.embedded) {
      final showFooter = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);
      final submitButton = ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeight)),
        child: _submitting
            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(context.local.pollCreate, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
      return PopScope(
        canPop: !_submitting,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AppPageScrollView(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  maxWidth: 680,
                  children: [
                    ...fields,
                    if (showFooter) ...[
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      submitButton,
                    ],
                  ],
                ),
              ),
              if (!showFooter)
                Container(
                  decoration: BoxDecoration(
                    color: colors.cardBackgroundColor,
                    border: Border(top: BorderSide(color: colors.borderColor)),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadowColor.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeLarge,
                    Dimensions.paddingSizeDefault,
                    Dimensions.paddingSizeLarge,
                    Dimensions.paddingSizeDefault + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: submitButton,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_submitting,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? context.local.editPoll : context.local.pollNew,
              style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            ...fields,
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeight)),
                    child: Text(context.local.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeight)),
                    child: _submitting
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isEdit ? context.local.save : context.local.pollCreate, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFields(BuildContext context) {
    final colors = context.customThemeColors;
    return [
      _Label(context.local.pollQuestion),
      TextFormField(
        controller: _titleController,
        enabled: !_submitting,
        maxLength: 120,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        decoration: _decoration(context, hint: context.local.pollQuestionHint),
        forceErrorText: _fieldErrors['title'],
        validator: (value) => (value ?? '').trim().isEmpty ? context.local.pollQuestionRequired : null,
      ),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      _Label(context.local.pollDescription),
      TextFormField(
        controller: _descriptionController,
        enabled: !_submitting,
        maxLength: 1000,
        textCapitalization: TextCapitalization.sentences,
        minLines: 2,
        maxLines: 4,
        decoration: _decoration(context, hint: context.local.pollDetailsHint),
        forceErrorText: _fieldErrors['description'],
      ),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      _Label(context.local.pollDate),
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: InkWell(
          onTap: _submitting || _lockDate ? null : _pickDate,
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
                Icon(Icons.event_outlined, size: Dimensions.iconSizeSmall, color: colors.primaryColor),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Text(
                    _lockDate ? PollFormatters.day(_pollDate) : PollFormatters.relativeDay(context.local, _pollDate),
                    style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: colors.textPrimaryColor),
                  ),
                ),
                if (!_lockDate) Icon(Icons.edit_calendar_rounded, size: Dimensions.iconSizeSmall, color: colors.textHintColor),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: Dimensions.paddingSizeLarge),

      _Label(context.local.pollOptions),
      for (var index = 0; index < _optionControllers.length; index++) ...[
        if (index > 0) const SizedBox(height: Dimensions.paddingSizeSmall),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _optionControllers[index],
                enabled: !_submitting && !_lockOptions,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(context, hint: context.local.pollOptionHint(index + 1), counter: true),
              ),
            ),
            if (!_lockOptions && _optionControllers.length > 2) ...[
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              IconButton(
                tooltip: context.local.remove,
                onPressed: _submitting ? null : () => _removeOption(index),
                icon: Icon(Icons.remove_circle_outline_rounded, color: colors.errorColor),
              ),
            ],
          ],
        ),
      ],
      if (_fieldErrors['options'] != null) ...[
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(_fieldErrors['options']!, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.errorColor)),
      ],
      if (!_lockOptions) ...[
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _submitting || _optionControllers.length >= 10 ? null : _addOption,
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: Text(context.local.pollAddOption),
          ),
        ),
      ],
      if (_lockOptions) ...[
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(
          context.local.pollOptionsLocked,
          style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor),
        ),
      ],
      const SizedBox(height: Dimensions.paddingSizeDefault),

      SwitchListTile.adaptive(
        value: _allowMultiple,
        onChanged: _submitting || _lockOptions ? null : (value) => setState(() {
          _allowMultiple = value;
          if (value && _maxChoices < 2) _maxChoices = 2;
        }),
        contentPadding: EdgeInsets.zero,
        title: Text(context.local.pollAllowMultiple, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: colors.textPrimaryColor)),
      ),
      if (_allowMultiple && !_lockOptions) ...[
        _Label(context.local.pollMaxChoices),
        DropdownButtonFormField<int>(
          initialValue: _maxChoices.clamp(1, _optionControllers.length < 2 ? 2 : _optionControllers.length),
          decoration: _decoration(context),
          items: [
            for (var value = 1; value <= (_optionControllers.length < 2 ? 2 : _optionControllers.length); value++)
              DropdownMenuItem(value: value, child: Text('$value')),
          ],
          onChanged: _submitting ? null : (value) => setState(() => _maxChoices = value ?? 1),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
      ],

      SwitchListTile.adaptive(
        value: _anonymous,
        onChanged: _submitting ? null : (value) => setState(() => _anonymous = value),
        contentPadding: EdgeInsets.zero,
        title: Text(context.local.pollAnonymous, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: colors.textPrimaryColor)),
      ),

      _Label(context.local.pollResultsVisibility),
      DropdownButtonFormField<PollResultsVisibility>(
        initialValue: _resultsVisibility,
        decoration: _decoration(context),
        items: [
          DropdownMenuItem(value: PollResultsVisibility.always, child: Text(context.local.pollResultsAlways)),
          DropdownMenuItem(value: PollResultsVisibility.afterVote, child: Text(context.local.pollResultsAfterVote)),
          DropdownMenuItem(value: PollResultsVisibility.afterClose, child: Text(context.local.pollResultsAfterClose)),
        ],
        onChanged: _submitting ? null : (value) => setState(() => _resultsVisibility = value ?? PollResultsVisibility.afterVote),
      ),

      if (_error != null) ...[
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: Dimensions.iconSizeSmall, color: colors.errorColor),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Expanded(child: Text(_error!, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.errorColor))),
          ],
        ),
      ],
    ];
  }

  InputDecoration _decoration(BuildContext context, {String? hint, bool counter = false}) {
    final colors = context.customThemeColors;
    return InputDecoration(
      isDense: true,
      hintText: hint,
      counterText: counter ? '' : null,
      contentPadding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      filled: true,
      fillColor: colors.cardBackgroundColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault), borderSide: BorderSide(color: colors.borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault), borderSide: BorderSide(color: colors.borderColor)),
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
      child: Text(text, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor)),
    );
  }
}
