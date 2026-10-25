import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/features/membership/domain/entities/membership_status_entity.dart';
import 'package:mess_pilot/features/membership/presentation/widgets/mess_avatar.dart';
import 'package:mess_pilot/features/membership/presentation/widgets/mess_formatters.dart';

/// One of the user's memberships: mess, season (dates), role and state, with
/// a Switch button when it can become current. [busy] shows a spinner; a null
/// [onSwitch] disables the button (another action runs).
class MyMembershipTile extends StatelessWidget {
  const MyMembershipTile({required this.membership, required this.busy, required this.onSwitch, this.showMessName = true, super.key});

  final MembershipSummaryEntity membership;
  final bool busy;
  final VoidCallback? onSwitch;
  final bool showMessName;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final m = membership;
    final start = m.seasonStartDate;
    final dates = start == null
        ? null
        : m.seasonEndDate == null
            ? context.local.messSince(MessFormatters.date(start))
            : context.local.seasonDates(MessFormatters.date(start), MessFormatters.date(m.seasonEndDate!));
    final subtitle = showMessName ? [context.local.seasonName(m.seasonName), ?dates].join(' · ') : dates;
    final accent = m.isCurrent ? colors.primaryColor : (m.canSwitch ? colors.infoColor : colors.textHintColor);

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: m.isCurrent ? colors.primaryColor.withValues(alpha: 0.06) : null,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: m.isCurrent ? colors.primaryColor.withValues(alpha: 0.5) : colors.borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          MessAvatar(name: m.messName, color: accent, size: 44),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showMessName ? m.messName : m.seasonName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: m.canSwitch ? colors.textPrimaryColor : colors.textSecondaryColor),
                ),
                if (subtitle != null) Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Wrap(
                  spacing: Dimensions.paddingSizeExtraSmall,
                  runSpacing: Dimensions.paddingSizeExtraSmall,
                  children: [
                    if (m.isCurrent) _Badge(label: context.local.currentMembership, color: colors.primaryColor),
                    if (m.isManager) _Badge(label: MessFormatters.role(context, 'manager'), color: colors.secondaryColor),
                    if (m.isActingManager) _Badge(label: MessFormatters.role(context, 'acting_manager'), color: colors.secondaryColor),
                    if (m.isMember) _Badge(label: MessFormatters.role(context, 'member'), color: colors.infoColor),
                    if (!m.isMember && (m.isManager || m.isActingManager)) _Badge(label: context.local.leadershipAccessNotJoined, color: colors.warningColor, icon: Icons.admin_panel_settings_outlined),
                    if (m.status == 'disabled') _Badge(label: context.local.disabled, color: colors.errorColor),
                    if (m.status == 'left') _Badge(label: context.local.membershipLeft, color: colors.textHintColor),
                  ],
                ),
              ],
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (m.canSwitch && !m.isCurrent) ...[
            const SizedBox(width: Dimensions.paddingSizeSmall),
            FilledButton.tonalIcon(onPressed: onSwitch, icon: const Icon(Icons.swap_horiz_rounded, size: 18), label: Text(context.local.switchMembership)),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
          ],
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: color))),
        ],
      ),
    );
  }
}
