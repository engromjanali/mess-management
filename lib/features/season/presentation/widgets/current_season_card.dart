import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/features/season/domain/entities/season_entity.dart';
import 'package:mess_pilot/features/season/presentation/widgets/season_formatters.dart';
import 'package:mess_pilot/features/season/presentation/widgets/season_status_chip.dart';

/// The season the mess is working in now, or an empty state when none is.
class CurrentSeasonCard extends StatelessWidget {
  const CurrentSeasonCard({required this.season, super.key});

  final SeasonEntity? season;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final season = this.season;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge24),
      decoration: BoxDecoration(color: colors.surfaceColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault), border: Border.all(color: colors.borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                child: Icon(Icons.event_available_rounded, color: colors.primaryColor),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(child: Text(context.local.seasonInUse, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor))),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          if (season == null)
            Text(context.local.noSeasonInUse, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor))
          else ...[
            Text(season.name, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Wrap(
              spacing: Dimensions.paddingSizeSmall,
              runSpacing: Dimensions.paddingSizeSmall,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SeasonStatusChip(status: season.status),
                if (season.endDate == null) SeasonStatusChip(inUse: true),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Divider(height: 1, color: colors.borderColor),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _detail(context, Icons.calendar_today_outlined, season.endDate == null ? context.local.messSince(SeasonFormatters.date(season.startDate)) : context.local.seasonDates(SeasonFormatters.date(season.startDate), SeasonFormatters.date(season.endDate!))),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Wrap(
              spacing: Dimensions.paddingSizeExtraLarge24,
              runSpacing: Dimensions.paddingSizeSmall,
              children: [
                if (season.endDate == null) _detail(context, Icons.timelapse_rounded, context.local.seasonDay(season.day)),
                _detail(context, Icons.group_outlined, context.local.seasonMemberCount(season.memberCount)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detail(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: Dimensions.iconSizeSmall, color: context.customThemeColors.textSecondaryColor),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Flexible(child: Text(text, style: AppTextStyles.sfProRoundedMedium.copyWith(color: context.customThemeColors.textSecondaryColor))),
      ],
    );
  }
}
