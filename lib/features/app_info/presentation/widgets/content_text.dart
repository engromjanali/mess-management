import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';

/// Renders an admin-written page body: a blank line starts a paragraph,
/// `# ` a heading and `- ` a bullet. Selectable so users can copy text.
class ContentText extends StatelessWidget {
  const ContentText({required this.body, super.key});

  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final bodyStyle = AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textPrimaryColor, height: 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in body.split('\n').map((line) => line.trimRight()))
          if (line.trim().isEmpty)
            const SizedBox(height: Dimensions.paddingSizeSmall)
          else if (line.startsWith('# '))
            Padding(
              padding: const EdgeInsets.only(top: Dimensions.paddingSizeDefault, bottom: Dimensions.paddingSizeExtraSmall),
              child: SelectableText(line.substring(2), style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor)),
            )
          else if (line.startsWith('- '))
            Padding(
              padding: const EdgeInsetsDirectional.only(start: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeExtraSmall),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: bodyStyle.copyWith(color: colors.primaryColor)),
                  Expanded(child: SelectableText(line.substring(2), style: bodyStyle)),
                ],
              ),
            )
          else
            SelectableText(line, style: bodyStyle),
      ],
    );
  }
}
