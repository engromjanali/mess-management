import 'package:mess_pilot/core/role/role_cubit.dart';
import 'package:mess_pilot/core/widgets/notification_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/features/home/presentation/widgets/dashboard_formatters.dart';
import 'package:mess_pilot/features/home/presentation/widgets/membership_summary_card.dart';
import 'package:mess_pilot/features/membership/domain/entities/membership_status_entity.dart';

class HomeSliverAppBar extends StatelessWidget {
  const HomeSliverAppBar({required this.userName, required this.role, required this.currentSeasonName, required this.totalBalance, required this.expandedHeight, this.photoUrl, this.membership, this.hasSwitch = false, super.key});

  final String userName;
  final UserRole role;
  final String? photoUrl;
  final String currentSeasonName;
  final double totalBalance;
  final double expandedHeight;
  final MembershipSummaryEntity? membership;
  final bool hasSwitch;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final topInset = MediaQuery.paddingOf(context).top;
    final maximumHeight = expandedHeight + topInset;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: expandedHeight,
      backgroundColor: colors.primaryDarkColor,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const Border(),
      actions: [
        const NotificationIconButton(),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: Dimensions.paddingSizeSmall),
          child: _RoleBadge(role: role),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapsedHeight = topInset + kToolbarHeight;
          final collapseProgress = ((maximumHeight - constraints.maxHeight) / (maximumHeight - collapsedHeight)).clamp(0.0, 1.0);
          final expandedOpacity = (1 - ((collapseProgress - 0.12) / 0.70)).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              _HeaderBackground(userName: userName, currentSeasonName: currentSeasonName, totalBalance: totalBalance, expandedHeight: maximumHeight, contentOpacity: expandedOpacity, membership: membership, hasSwitch: hasSwitch),
              Positioned(
                top: topInset,
                left: Dimensions.paddingSizeLarge,
                right: Dimensions.paddingSizeLarge + kToolbarHeight,
                height: kToolbarHeight,
                child: IgnorePointer(
                  ignoring: collapseProgress < 0.55,
                  child: Opacity(opacity: ((collapseProgress - 0.55) / 0.55).clamp(0.0, 1.0), child: _CollapsedIdentity(userName: userName, photoUrl: photoUrl)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground({required this.userName, required this.currentSeasonName, required this.totalBalance, required this.expandedHeight, required this.contentOpacity, this.membership, this.hasSwitch = false});

  final String userName;
  final String currentSeasonName;
  final double totalBalance;
  final double expandedHeight;
  final double contentOpacity;
  final MembershipSummaryEntity? membership;
  final bool hasSwitch;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colors.primaryDarkColor, colors.primaryColor, colors.primaryLightColor]),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(top: -70, right: -45, child: _DecorativeCircle(size: 190, color: Colors.white.withValues(alpha: 0.08))),
            Positioned(bottom: -85, left: -70, child: _DecorativeCircle(size: 180, color: colors.secondaryColor.withValues(alpha: 0.20))),
            OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: MediaQuery.sizeOf(context).width,
              maxWidth: MediaQuery.sizeOf(context).width,
              minHeight: expandedHeight,
              maxHeight: expandedHeight,
              child: Opacity(
                opacity: contentOpacity,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, MediaQuery.paddingOf(context).top + Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge + kToolbarHeight, 0),
                  child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.local.uiWelcomeBack,
                  style: AppTextStyles.sfProRoundedMedium.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: Dimensions.fontSizeDefault),
                ),
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraOverLarge),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            const Spacer(),
            Text(
              context.local.uiTotalBalance,
              style: AppTextStyles.sfProRoundedMedium.copyWith(color: Colors.white.withValues(alpha: 0.78), fontSize: Dimensions.fontSizeSmall),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(DashboardFormatters.taka(totalBalance), style: AppTextStyles.sfProRoundedBold.copyWith(color: Colors.white, fontSize: 32)),
            ),
            if (membership != null || currentSeasonName.isNotEmpty)
              MembershipSummaryCard(
                messName: membership?.messName ?? '',
                seasonName: membership?.seasonName ?? currentSeasonName,
                imageUrl: membership?.messImageUrl,
                hasSwitch: hasSwitch,
                maxMessChars: 100,
                maxSeasonChars: 100,
                maxWidth: MediaQuery.sizeOf(context).width,
                onDark: true,
              ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapsedIdentity extends StatelessWidget {
  const _CollapsedIdentity({required this.userName, this.photoUrl});

  final String userName;
  final String? photoUrl;

  String get _initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl?.trim() ?? '';
    final fallback = Text(_initials, style: AppTextStyles.sfProRoundedBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault));
    final imageSize = (38 * MediaQuery.devicePixelRatioOf(context)).round();
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.35))),
          alignment: Alignment.center,
          child: imageUrl.isEmpty ? fallback : ClipOval(child: Image.network(imageUrl, width: 38, height: 38, fit: BoxFit.cover, cacheWidth: imageSize, cacheHeight: imageSize, errorBuilder: (_, _, _) => Center(child: fallback))),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.local.uiWelcomeBackText, style: AppTextStyles.sfProRoundedMedium.copyWith(color: Colors.white.withValues(alpha: 0.75), fontSize: Dimensions.fontSizeExtraSmall)),
              Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(child: Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle)));
}

/// Glass pill that shows the signed-in user's role in the phone app bar.
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final (label, icon, accent) = switch (role) {
      UserRole.manager => (context.local.roleManager, Icons.admin_panel_settings_rounded, const Color(0xFFFFD166)),
      UserRole.actingManager => (context.local.roleActingManager, Icons.verified_user_rounded, const Color(0xFF7FE7D1)),
      UserRole.member => (context.local.roleMember, Icons.person_rounded, Colors.white),
    };

    return Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Dimensions.iconSizeSmall, color: accent),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
            ),
          ),
        ],
      ),
    );
  }
}
