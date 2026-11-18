import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/home/presentation/widgets/membership_summary_card.dart';
import 'package:mess_pilot/features/membership/domain/entities/membership_status_entity.dart';
import 'package:mess_pilot/features/membership/presentation/bloc/membership_cubit.dart';
import 'package:mess_pilot/features/membership/presentation/widgets/mess_avatar.dart';

/// Tappable membership summary that opens the mess/season switcher.
///
/// Shared by the tablet & desktop top bar and the phone header so both behave
/// the same way.
class MembershipMenuButton extends StatefulWidget {
  const MembershipMenuButton({
    this.fallbackMessName = '',
    this.fallbackSeasonName = '',
    this.fallbackImageUrl,
    this.fallbackHasSwitch = false,
    this.onDark = false,
    this.maxMessChars = 15,
    this.maxSeasonChars = 20,
    this.maxWidth = 220,
    this.padding = const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
    super.key,
  });

  final String fallbackMessName;
  final String fallbackSeasonName;
  final String? fallbackImageUrl;
  final bool fallbackHasSwitch;
  final bool onDark;
  final int maxMessChars;
  final int maxSeasonChars;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  State<MembershipMenuButton> createState() => _MembershipMenuButtonState();
}

class _MembershipMenuButtonState extends State<MembershipMenuButton> {
  bool _switching = false;

  @override
  Widget build(BuildContext context) {
    if (context.findAncestorWidgetOfExactType<BlocProvider<MembershipCubit>>() == null) return _fallbackCard(context);
    final state = context.watch<MembershipCubit>().state;
    if (state is! MembershipLoaded) return _fallbackCard(context);
    final current = state.status.current;
    if (current == null) return _fallbackCard(context);

    final memberships = state.status.memberships.where((membership) => membership.messId == current.messId).toList();
    if (!memberships.any((membership) => membership.seasonId == current.seasonId)) memberships.insert(0, current);
    memberships.sort((a, b) {
      if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
      return (b.seasonStartDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.seasonStartDate ?? DateTime.fromMillisecondsSinceEpoch(0));
    });
    final hasSwitch = memberships.any((membership) => membership.canSwitch && !membership.isCurrent);

    return Padding(
      padding: widget.padding,
      child: PopupMenuButton<MembershipSummaryEntity>(
        tooltip: context.local.myMemberships,
        enabled: !_switching,
        position: PopupMenuPosition.under,
        offset: const Offset(0, 8),
        color: context.customThemeColors.surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge), side: BorderSide(color: context.customThemeColors.borderColor)),
        onSelected: _switchTo,
        itemBuilder: (context) => [
          PopupMenuItem<MembershipSummaryEntity>(
            enabled: false,
            height: 58,
            child: SizedBox(
              width: 300,
              child: Row(
                children: [
                  MessAvatar(name: current.messName, color: context.customThemeColors.primaryColor, size: 36, imageUrl: current.messImageUrl),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(current.messName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: context.customThemeColors.textPrimaryColor)),
                        Text(context.local.myMemberships, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: context.customThemeColors.textSecondaryColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          for (final membership in memberships)
            PopupMenuItem<MembershipSummaryEntity>(
              value: membership,
              enabled: membership.canSwitch && !membership.isCurrent,
              height: 58,
              child: SizedBox(
                width: 300,
                child: Row(
                  children: [
                    Icon(
                      membership.isCurrent ? Icons.check_circle_rounded : membership.canSwitch ? Icons.calendar_month_rounded : Icons.lock_outline_rounded,
                      size: Dimensions.iconSizeDefault,
                      color: membership.isCurrent ? context.customThemeColors.primaryColor : membership.canSwitch ? context.customThemeColors.textSecondaryColor : context.customThemeColors.textHintColor,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeDefault),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(membership.seasonName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: membership.canSwitch || membership.isCurrent ? context.customThemeColors.textPrimaryColor : context.customThemeColors.textHintColor)),
                          const SizedBox(height: 2),
                          Text(_subtitle(context, membership), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: context.customThemeColors.textSecondaryColor)),
                        ],
                      ),
                    ),
                    if (membership.isCurrent)
                      Text(context.local.currentMembership, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: context.customThemeColors.primaryColor))
                    else if (membership.canSwitch)
                      Icon(Icons.swap_horiz_rounded, size: Dimensions.iconSizeSmall + 2, color: context.customThemeColors.primaryColor)
                    else
                      Icon(Icons.lock_outline_rounded, size: Dimensions.iconSizeSmall, color: context.customThemeColors.textHintColor),
                  ],
                ),
              ),
            ),
        ],
        child: _card(context, current.messName, current.seasonName, current.messImageUrl, hasSwitch, _switching),
      ),
    );
  }

  Widget _fallbackCard(BuildContext context) {
    if (widget.fallbackMessName.isEmpty && widget.fallbackSeasonName.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: widget.padding,
      child: _card(context, widget.fallbackMessName, widget.fallbackSeasonName, widget.fallbackImageUrl, widget.fallbackHasSwitch, false),
    );
  }

  Widget _card(BuildContext context, String messName, String seasonName, String? imageUrl, bool hasSwitch, bool switching) => MembershipSummaryCard(
    messName: messName,
    seasonName: seasonName,
    imageUrl: imageUrl,
    switching: switching,
    hasSwitch: hasSwitch,
    maxMessChars: widget.maxMessChars,
    maxSeasonChars: widget.maxSeasonChars,
    maxWidth: widget.maxWidth,
    onDark: widget.onDark,
  );

  String _subtitle(BuildContext context, MembershipSummaryEntity membership) {
    final role = switch (membership.role) {
      'manager' => context.local.roleManager,
      'acting_manager' => context.local.roleActingManager,
      _ => context.local.roleMember,
    };
    return membership.status == 'left' ? '$role · ${context.local.membershipLeft}' : role;
  }

  Future<void> _switchTo(MembershipSummaryEntity membership) async {
    if (_switching) return;
    setState(() => _switching = true);
    try {
      await context.read<MembershipCubit>().switchMembership(membership);
      if (!mounted) return;
      await context.read<AuthBloc>().refreshProfile();
      if (!mounted) return;
      context.showSuccessSnackBar(context.local.switchedMembership(membership.messName, membership.seasonName));
      context.go(AppRoutes.home);
    } catch (error) {
      if (mounted) context.showErrorSnackBar(error);
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }
}
