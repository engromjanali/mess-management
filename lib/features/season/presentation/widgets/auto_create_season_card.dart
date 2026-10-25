import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/features/season/domain/entities/auto_create_season_entity.dart';

/// "Auto Create new season" setting: title and the day it runs on the left,
/// a change-date button and the on / off switch on the right (under the
/// text on narrow screens). Callbacks are null while busy.
class AutoCreateSeasonCard extends StatelessWidget {
  const AutoCreateSeasonCard({required this.setting, required this.onToggle, required this.onChangeDay, this.onDayChanged, this.inlineDay = false, super.key});

  final AutoCreateSeasonEntity setting;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onChangeDay;
  final ValueChanged<int>? onDayChanged;
  final bool inlineDay;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final info = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.autorenew_rounded, color: colors.primaryColor),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.local.autoCreateSeason, style: AppTextStyles.sfProRoundedBold.copyWith(color: colors.textPrimaryColor)),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(
                setting.isMonthEnd ? context.local.autoCreateSeasonMonthEndHint : context.local.autoCreateSeasonHint(setting.day),
                style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, fontSize: Dimensions.fontSizeSmall),
              ),
            ],
          ),
        ),
      ],
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (inlineDay)
          Flexible(child: DropdownButton<int>(
            value: setting.day,
            isExpanded: true,
            items: [
              DropdownMenuItem(value: AutoCreateSeasonEntity.monthEnd, child: Text(context.local.monthEnd, maxLines: 1, overflow: TextOverflow.ellipsis)),
              for (var day = 1; day <= AutoCreateSeasonEntity.lastFixedDay; day++)
                DropdownMenuItem(value: day, child: Text(context.local.dayOfMonth(day), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: onDayChanged == null ? null : (day) { if (day != null) onDayChanged!(day); },
          ))
        else Flexible(child: Tooltip(
          message: context.local.changeDate,
          child: OutlinedButton.icon(
            onPressed: onChangeDay,
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: Text(setting.isMonthEnd ? context.local.monthEnd : context.local.dayOfMonth(setting.day), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        )),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Switch.adaptive(value: setting.enabled, onChanged: onToggle),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(color: colors.surfaceColor, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge), border: Border.all(color: colors.borderColor)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 600) return Row(children: [Expanded(child: info), const SizedBox(width: Dimensions.paddingSizeDefault), inlineDay ? SizedBox(width: 280, child: controls) : controls]);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [info, const SizedBox(height: Dimensions.paddingSizeSmall), Align(alignment: AlignmentDirectional.centerEnd, child: controls)],
          );
        },
      ),
    );
  }
}
