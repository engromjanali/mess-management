import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/membership/domain/entities/mess_details_entity.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_avatar.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_formatters.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_section_card.dart';

/// The season's members: manager and acting manager first, the signed-in
/// user tagged "You".
class MessMembersCard extends StatelessWidget {
  const MessMembersCard({required this.members, required this.myUserId, super.key});

  final List<MessMemberEntity> members;

  /// The signed-in user's id, to tag their row; null when unknown.
  final int? myUserId;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return MessSectionCard(
      title: context.local.members,
      icon: Icons.groups_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
        decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large)),
        child: Text(
          '${members.length}',
          style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.primaryColor),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < members.length; i++) ...[
            if (i > 0) Divider(height: Dimensions.paddingSizeDefault, color: colors.dividerColor.withValues(alpha: 0.3)),
            _MemberRow(member: members[i], isMe: members[i].userId == myUserId),
          ],
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.isMe});

  final MessMemberEntity member;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final accent = switch (member.role) {
      'manager' => colors.primaryColor,
      'acting_manager' => colors.secondaryColor,
      _ => colors.infoColor,
    };

    return Row(
      children: [
        MessAvatar(name: member.name, color: accent),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor),
                    ),
                  ),
                  if (isMe) ...[const SizedBox(width: Dimensions.paddingSizeExtraSmall), _Tag(label: context.local.you, color: colors.successColor)],
                ],
              ),
              Text(
                context.local.joinedOn(MessFormatters.date(context, member.joinedAt)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor),
              ),
            ],
          ),
        ),
        if (member.role != 'member') ...[const SizedBox(width: Dimensions.paddingSizeSmall), _Tag(label: MessFormatters.role(context, member.role), color: accent)],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      child: Text(
        label,
        maxLines: 1,
        style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: color),
      ),
    );
  }
}
