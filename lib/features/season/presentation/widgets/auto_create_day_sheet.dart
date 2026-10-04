import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/features/season/domain/entities/auto_create_season_entity.dart';

/// Picks the auto-create day: a calendar-like grid of days 1–28 plus
/// "Month end". Resolves to the chosen day (`AutoCreateSeasonEntity.monthEnd`
/// for month end), or null if dismissed.
Future<int?> showAutoCreateDaySheet(BuildContext context, {required int selected}) {
  return context.showAdaptiveSheet<int>(child: _AutoCreateDayPicker(selected: selected));
}

class _AutoCreateDayPicker extends StatelessWidget {
  const _AutoCreateDayPicker({required this.selected});

  final int selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.local.autoCreateDayTitle, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        Text(context.local.autoCreateDayNote, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor)),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Dimensions.paddingSizeExtraSmall,
          crossAxisSpacing: Dimensions.paddingSizeExtraSmall,
          children: [
            for (var day = 1; day <= AutoCreateSeasonEntity.lastFixedDay; day++)
              _DayOption(label: '$day', selected: day == selected, onTap: () => Navigator.of(context).pop(day)),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        SizedBox(
          height: 48,
          child: _DayOption(
            label: context.local.monthEnd,
            icon: Icons.event_rounded,
            selected: selected == AutoCreateSeasonEntity.monthEnd,
            onTap: () => Navigator.of(context).pop(AutoCreateSeasonEntity.monthEnd),
          ),
        ),
      ],
    );
  }
}

class _DayOption extends StatelessWidget {
  const _DayOption({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final foreground = selected ? Theme.of(context).colorScheme.onPrimary : colors.textPrimaryColor;
    return Material(
      color: selected ? colors.primaryColor : colors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        side: BorderSide(color: selected ? colors.primaryColor : colors.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: Dimensions.iconSizeSmall, color: foreground), const SizedBox(width: Dimensions.paddingSizeExtraSmall)],
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: foreground))),
            ],
          ),
        ),
      ),
    );
  }
}
