import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_entity.dart';

/// Small tinted pill: a season's status, or "In use" when [inUse].
class SeasonStatusChip extends StatelessWidget {
  const SeasonStatusChip({this.status, this.inUse = false, super.key}) : assert(status != null || inUse);

  final SeasonStatus? status;
  final bool inUse;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final (label, color) = inUse
        ? (context.local.inUse, colors.primaryColor)
        : switch (status!) {
            SeasonStatus.running => (context.local.statusRunning, colors.successColor),
            SeasonStatus.ended => (context.local.statusEnded, colors.textHintColor),
            SeasonStatus.disabled => (context.local.disabled, colors.errorColor),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large)),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: color, fontSize: Dimensions.fontSizeSmall)),
    );
  }
}
