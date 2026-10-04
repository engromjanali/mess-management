import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_entity.dart';
import 'package:clean_boilerplate/features/season/presentation/widgets/season_formatters.dart';
import 'package:clean_boilerplate/features/season/presentation/widgets/season_status_chip.dart';

/// The season the mess is working in now, or an empty state when none is.
class CurrentSeasonCard extends StatelessWidget {
  const CurrentSeasonCard({required this.season, super.key});

  final SeasonEntity? season;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final season = this.season;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(color: colors.surfaceColor, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge), border: Border.all(color: colors.primaryColor.withValues(alpha: 0.4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_rounded, color: colors.primaryColor),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(child: Text(context.local.seasonInUse, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
              if (season != null) SeasonStatusChip(status: season.status),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          if (season == null)
            Text(context.local.noSeasonInUse, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor))
          else ...[
            Text(season.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(
              [
                if (season.endDate == null) ...[context.local.messSince(SeasonFormatters.date(season.startDate)), context.local.seasonDay(season.day)]
                else context.local.seasonDates(SeasonFormatters.date(season.startDate), SeasonFormatters.date(season.endDate!)),
                context.local.seasonMemberCount(season.memberCount),
              ].join(' · '),
              style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor),
            ),
          ],
        ],
      ),
    );
  }
}
