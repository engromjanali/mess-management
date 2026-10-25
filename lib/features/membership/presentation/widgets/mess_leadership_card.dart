import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/membership/domain/entities/mess_details_entity.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/copyable_info_row.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_avatar.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_section_card.dart';

/// Manager and acting manager with their contact details (tap to copy).
class MessLeadershipCard extends StatelessWidget {
  const MessLeadershipCard({required this.manager, required this.actingManager, super.key});

  final MessPersonEntity? manager;
  final MessPersonEntity? actingManager;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return MessSectionCard(
      title: context.local.leadership,
      icon: Icons.admin_panel_settings_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tiles = [
            _LeaderTile(role: context.local.roleManager, person: manager, accent: colors.primaryColor, icon: Icons.workspace_premium_rounded),
            _LeaderTile(role: context.local.roleActingManager, person: actingManager, accent: colors.secondaryColor, icon: Icons.supervisor_account_rounded),
          ];
          if (constraints.maxWidth < 560) {
            return Column(
              children: [
                tiles[0],
                const SizedBox(height: Dimensions.paddingSizeDefault),
                tiles[1],
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[0]),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Expanded(child: tiles[1]),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LeaderTile extends StatelessWidget {
  const _LeaderTile({required this.role, required this.person, required this.accent, required this.icon});

  final String role;
  final MessPersonEntity? person;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final person = this.person;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (person == null)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: colors.textHintColor.withValues(alpha: 0.12)),
                  child: Icon(Icons.person_off_rounded, color: colors.textHintColor),
                )
              else
                MessAvatar(name: person.name, color: accent, size: 44),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: Dimensions.iconSizeSmall, color: accent),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Flexible(
                          child: Text(
                            role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: accent),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      person?.name ?? context.local.notAssigned,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: person == null ? colors.textHintColor : colors.textPrimaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (person != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            CopyableInfoRow(icon: Icons.phone_rounded, value: person.phone, emptyLabel: context.local.notProvided),
            CopyableInfoRow(icon: Icons.email_rounded, value: person.email, emptyLabel: context.local.notProvided),
          ],
        ],
      ),
    );
  }
}
