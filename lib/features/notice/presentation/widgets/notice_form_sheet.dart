import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/features/notice/domain/entities/notice_entity.dart';

/// Opens the add / edit notice bottom sheet.
///
/// When [existing] is null this publishes a new notice; otherwise it edits
/// that notice in place.
Future<void> showNoticeFormSheet({required BuildContext context, required void Function({required String title, required String description}) onSave, NoticeEntity? existing}) {
  return context.showAdaptiveSheet<void>(
    child: _NoticeFormSheet(existing: existing, onSave: onSave),
  );
}

class _NoticeFormSheet extends StatefulWidget {
  const _NoticeFormSheet({required this.existing, required this.onSave});

  final NoticeEntity? existing;
  final void Function({required String title, required String description}) onSave;

  @override
  State<_NoticeFormSheet> createState() => _NoticeFormSheetState();
}

class _NoticeFormSheetState extends State<_NoticeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

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

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSave(title: _titleController.text.trim(), description: _descriptionController.text.trim());
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
            _isEdit ? 'Edit notice' : 'Publish notice',
            style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          _Label('Title'),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: _decoration(context, hint: 'e.g. Meal rate updated'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a title' : null,
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          _Label('Description'),
          TextFormField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            minLines: 3,
            maxLines: 6,
            decoration: _decoration(context, hint: 'Write the notice details…'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a description' : null,
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
                  child: Text(_isEdit ? 'Save' : 'Publish'),
                ),
              ),
            ],
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
