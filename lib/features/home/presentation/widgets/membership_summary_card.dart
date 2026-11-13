import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

class MembershipSummaryCard extends StatelessWidget {
  const MembershipSummaryCard({
    required this.messName,
    required this.seasonName,
    this.switching = false,
    this.hasSwitch = false,
    this.maxMessChars = 15,
    this.maxSeasonChars = 20,
    this.maxWidth = 220,
    this.onDark = false,
    super.key,
  });

  final String messName;
  final String seasonName;
  final bool switching;
  final bool hasSwitch;
  final int maxMessChars;
  final int maxSeasonChars;
  final double maxWidth;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final radius = BorderRadius.circular(Dimensions.radiusLarge);
    final initial = messName.trim().characters.take(1).toString().toUpperCase();
    final accent = onDark ? Colors.white : colors.primaryColor;
    final titleColor = onDark ? Colors.white : colors.textPrimaryColor;
    final subtitleColor = onDark ? Colors.white.withValues(alpha: 0.70) : colors.textSecondaryColor;
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.18) : colors.primaryColor.withValues(alpha: 0.09),
        borderRadius: radius,
        border: onDark ? Border.all(color: Colors.white.withValues(alpha: 0.25)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: onDark ? Colors.white.withValues(alpha: 0.16) : colors.primaryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusSmall + 2)),
            child: switching
                ? Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall), child: CircularProgressIndicator(strokeWidth: 2, color: accent))
                : Center(child: Text(initial.isEmpty ? '?' : initial, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall + 1, color: accent))),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (messName.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(_limited(messName, maxMessChars), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: titleColor))),
                      if (hasSwitch) ...[
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Icon(Icons.keyboard_arrow_down_rounded, size: Dimensions.iconSizeSmall, color: accent),
                      ],
                    ],
                  ),
                if (seasonName.isNotEmpty)
                  Text(_limited(seasonName, maxSeasonChars), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: subtitleColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _limited(String value, int max) {
    if (value.characters.length <= max) return value;
    return '${value.characters.take(max - 1).toString().trimRight()}…';
  }
}
