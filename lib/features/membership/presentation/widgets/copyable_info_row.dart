import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';

/// An icon + value row that copies the value on tap. An empty [value] shows
/// [emptyLabel] muted and isn't tappable.
class CopyableInfoRow extends StatelessWidget {
  const CopyableInfoRow({required this.icon, required this.value, required this.emptyLabel, this.label, super.key});

  final IconData icon;
  final String value;
  final String emptyLabel;

  /// Optional caption above the value (e.g. "Address").
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final empty = value.trim().isEmpty;

    return InkWell(
      onTap: empty
          ? null
          : () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) context.showSuccessSnackBar(context.local.copiedToClipboard);
            },
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeExtraSmall),
        child: Row(
          children: [
            Icon(icon, size: Dimensions.iconSizeSmall, color: empty ? colors.textHintColor : colors.primaryColor),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null)
                    Text(
                      label!,
                      style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: colors.textHintColor),
                    ),
                  Text(
                    empty ? emptyLabel : value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: empty ? colors.textHintColor : colors.textPrimaryColor),
                  ),
                ],
              ),
            ),
            if (!empty) Icon(Icons.copy_rounded, size: Dimensions.iconSizeSmall, color: colors.textHintColor),
          ],
        ),
      ),
    );
  }
}
