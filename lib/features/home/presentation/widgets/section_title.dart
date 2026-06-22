import 'package:flutter/material.dart';
import '../../../../config/util/dimensions.dart';
import '../../../../config/util/styles.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Plain (non-sliver) section heading used by the tablet & desktop dashboards.
///
/// Visually matches [PinnedSectionHeader] — accent bar, optional icon, bold
/// title and an optional trailing widget — but lives inline in a [Column].
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    this.icon,
    this.trailing,
    super.key,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: colors.primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          if (icon != null) ...[
            Icon(icon, size: Dimensions.iconSizeSmall, color: colors.primaryColor),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.sfProRoundedBold.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: colors.textPrimaryColor,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
