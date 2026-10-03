import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/features/notice/domain/entities/notice_entity.dart';

/// Saves the form; completes with null on success or the [Failure].
typedef NoticeSubmit = Future<Failure?> Function({required String title, required String description});

/// Same limits as the backend, so they're caught while typing.
const int _titleMaxLength = 200;
const int _descriptionMaxLength = 2000;

/// Opens the publish / edit notice sheet; completes with `true` once saved.
///
/// The sheet stays open while saving (locked, with a spinner) and shows the
/// backend's errors — field errors under their field, others above the
/// buttons — so nothing typed is lost on failure. When [existing] is null this
/// publishes a new notice; otherwise it edits that notice.
Future<bool?> showNoticeFormSheet({required BuildContext context, required NoticeSubmit onSubmit, NoticeEntity? existing}) {
  return context.showAdaptiveSheet<bool>(
    child: _NoticeFormSheet(existing: existing, onSubmit: onSubmit),
  );
}

class _NoticeFormSheet extends StatefulWidget {
  const _NoticeFormSheet({required this.existing, required this.onSubmit});

  final NoticeEntity? existing;
  final NoticeSubmit onSubmit;

  @override
  State<_NoticeFormSheet> createState() => _NoticeFormSheetState();
}

class _NoticeFormSheetState extends State<_NoticeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _fieldErrors = const {};
      _error = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final failure = await widget.onSubmit(title: _titleController.text.trim(), description: _descriptionController.text.trim());
    if (!mounted) return;

    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    final fieldErrors = failure is ServerFailure ? failure.fieldErrors : const <String, String>{};
    setState(() {
      _submitting = false;
      _fieldErrors = fieldErrors;
      // Field errors show under their field; anything else shows here.
      _error = fieldErrors.containsKey('title') || fieldErrors.containsKey('description') ? null : failure.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    // Block back / outside-tap dismissal while saving.
    return PopScope(
      canPop: !_submitting,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? context.local.editNotice : context.local.publishNotice,
              style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            _Label(context.local.noticeTitle),
            TextFormField(
              controller: _titleController,
              enabled: !_submitting,
              maxLength: _titleMaxLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: _decoration(context, hint: context.local.noticeTitleHint),
              forceErrorText: _fieldErrors['title'],
              validator: (v) => (v ?? '').trim().isEmpty ? context.local.enterNoticeTitle : null,
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            _Label(context.local.noticeDescription),
            TextFormField(
              controller: _descriptionController,
              enabled: !_submitting,
              maxLength: _descriptionMaxLength,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 6,
              decoration: _decoration(context, hint: context.local.noticeDescriptionHint),
              forceErrorText: _fieldErrors['description'],
              validator: (v) => (v ?? '').trim().isEmpty ? context.local.enterNoticeDescription : null,
            ),

            if (_error != null) ...[
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded, size: Dimensions.iconSizeSmall, color: colors.errorColor),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.errorColor),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeightDefault)),
                    child: Text(context.local.cancel, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(Dimensions.buttonHeightDefault)),
                    child: _submitting
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isEdit ? context.local.save : context.local.publish, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, {String? hint}) {
    final colors = context.customThemeColors;
    return InputDecoration(
      isDense: true,
      hintText: hint,
      contentPadding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
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
