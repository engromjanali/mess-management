import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_entity.dart';
import 'package:clean_boilerplate/features/season/presentation/widgets/season_formatters.dart';
import 'package:clean_boilerplate/features/season/presentation/widgets/season_status_chip.dart';

/// One season row: name, dates, status, a Switch button (when it can be
/// used) and a menu with Edit / End / Disable or Enable / Delete.
///
/// All actions are hidden or disabled while [enabled] is false (busy).
class SeasonTile extends StatelessWidget {
  const SeasonTile({
    required this.season,
    required this.inUse,
    required this.enabled,
    required this.onSwitch,
    required this.onEdit,
    required this.onEnd,
    required this.onToggleDisabled,
    required this.onDelete,
    super.key,
  });

  final SeasonEntity season;
  final bool inUse;
  final bool enabled;
  final VoidCallback onSwitch;
  final VoidCallback onEdit;
  final VoidCallback onEnd;
  final VoidCallback onToggleDisabled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final end = season.endDate;
    final canSwitch = !inUse && !season.disabled;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault, Dimensions.paddingSizeExtraSmall, Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: inUse ? colors.primaryColor : colors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  season.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: season.disabled ? colors.textHintColor : colors.textPrimaryColor),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text(
                  '${end == null ? context.local.messSince(SeasonFormatters.date(season.startDate)) : context.local.seasonDates(SeasonFormatters.date(season.startDate), SeasonFormatters.date(end))}'
                  ' · ${context.local.seasonMemberCount(season.memberCount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, fontSize: Dimensions.fontSizeSmall),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Wrap(
                  spacing: Dimensions.paddingSizeExtraSmall,
                  runSpacing: Dimensions.paddingSizeExtraSmall,
                  children: [
                    if (inUse) const SeasonStatusChip(inUse: true),
                    SeasonStatusChip(status: season.status),
                  ],
                ),
              ],
            ),
          ),
          if (canSwitch)
            FilledButton.tonalIcon(
              onPressed: enabled ? onSwitch : null,
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: Text(context.local.switchMembership),
            ),
          PopupMenuButton<_SeasonAction>(
            enabled: enabled,
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            onSelected: (action) => switch (action) {
              _SeasonAction.edit => onEdit(),
              _SeasonAction.end => onEnd(),
              _SeasonAction.toggleDisabled => onToggleDisabled(),
              _SeasonAction.delete => onDelete(),
            },
            itemBuilder: (context) => [
              _menuItem(_SeasonAction.edit, Icons.edit_outlined, context.local.edit),
              if (season.endDate == null) _menuItem(_SeasonAction.end, Icons.flag_outlined, context.local.endSeason),
              // The season in use can't be disabled; switch away first.
              if (!inUse) _menuItem(_SeasonAction.toggleDisabled, season.disabled ? Icons.check_circle_outline_rounded : Icons.block_rounded, season.disabled ? context.local.enable : context.local.disable),
              _menuItem(_SeasonAction.delete, Icons.delete_outline_rounded, context.local.delete, color: colors.errorColor),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<_SeasonAction> _menuItem(_SeasonAction value, IconData icon, String label, {Color? color}) => PopupMenuItem(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: Dimensions.iconSizeSmall, color: color),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Text(label, style: TextStyle(color: color)),
      ],
    ),
  );
}

enum _SeasonAction { edit, end, toggleDisabled, delete }
