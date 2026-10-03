import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_avatar.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_formatters.dart';

/// What a manager can do to a member from the members list.
enum MemberAction { makeActingManager, removeActingManager, makePrimaryManager, disable, enable }

/// One member in the manager's list: identity, role / disabled badges and a
/// menu with the [actions] the caller may take. While [busy] the menu becomes
/// a spinner; a null [onAction] disables the menu (another action runs).
class ManagedMemberTile extends StatelessWidget {
  const ManagedMemberTile({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.disabled,
    required this.isMe,
    required this.actions,
    required this.busy,
    required this.onAction,
    this.left = false,
    super.key,
  });

  final String name;
  final String email;
  final String phone;

  /// `manager`, `acting_manager` or `member`.
  final String role;
  final bool disabled;

  /// Left this season; shown dimmed with a "Left" badge.
  final bool left;
  final bool isMe;
  final List<MemberAction> actions;
  final bool busy;
  final ValueChanged<MemberAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final inactive = disabled || left;
    final accent = inactive
        ? colors.textHintColor
        : switch (role) {
            'manager' => colors.primaryColor,
            'acting_manager' => colors.secondaryColor,
            _ => colors.infoColor,
          };
    final contact = [email, phone].where((v) => v.isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Row(
        children: [
          Opacity(opacity: inactive ? 0.6 : 1, child: MessAvatar(name: name, color: accent, size: 44)),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: inactive ? colors.textSecondaryColor : colors.textPrimaryColor),
                ),
                if (contact.isNotEmpty)
                  Text(contact, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor)),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Wrap(
                  spacing: Dimensions.paddingSizeExtraSmall,
                  runSpacing: Dimensions.paddingSizeExtraSmall,
                  children: [
                    if (isMe) _Badge(label: context.local.you, color: colors.successColor),
                    if (role != 'member') _Badge(label: MessFormatters.role(context, role), color: accent),
                    if (disabled) _Badge(label: context.local.disabled, color: colors.errorColor),
                    if (left) _Badge(label: context.local.membershipLeft, color: colors.textHintColor),
                  ],
                ),
              ],
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (actions.isNotEmpty)
            PopupMenuButton<MemberAction>(
              tooltip: context.local.memberActions,
              enabled: onAction != null,
              icon: Icon(Icons.more_vert_rounded, color: onAction == null ? colors.textHintColor : colors.textSecondaryColor),
              onSelected: onAction,
              itemBuilder: (context) => [for (final action in actions) _menuItem(context, action)],
            ),
        ],
      ),
    );
  }

  PopupMenuItem<MemberAction> _menuItem(BuildContext context, MemberAction action) {
    final colors = context.customThemeColors;
    final (icon, label, color) = switch (action) {
      MemberAction.makeActingManager => (Icons.supervisor_account_rounded, context.local.makeActingManager, colors.secondaryColor),
      MemberAction.removeActingManager => (Icons.person_remove_alt_1_rounded, context.local.removeActingManager, colors.warningColor),
      MemberAction.makePrimaryManager => (Icons.workspace_premium_rounded, context.local.makePrimaryManager, colors.primaryColor),
      MemberAction.disable => (Icons.block_rounded, context.local.disableMember, colors.errorColor),
      MemberAction.enable => (Icons.check_circle_rounded, context.local.enableMember, colors.successColor),
    };
    return PopupMenuItem<MemberAction>(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: Dimensions.iconSizeDefault, color: color),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      child: Text(label, maxLines: 1, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: color)),
    );
  }
}
