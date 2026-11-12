import 'package:mess_pilot/core/widgets/notification_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/util/app_constants.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/assets/assets.gen.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/core/widgets/app_logo.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:mess_pilot/features/membership/domain/entities/membership_status_entity.dart';
import 'package:mess_pilot/features/membership/presentation/bloc/membership_cubit.dart';
import 'package:mess_pilot/features/settings/domain/entities/theme_mode.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_event.dart';

/// A single navigation entry rendered in the [DashboardTopBar].
class DashboardNavItem {
  const DashboardNavItem({required this.label, required this.icon, required this.onTap, this.active = false});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
}

enum DashboardSection { home, meals, deposits, cost }

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({this.userName, this.onProfileTap, this.navItems, this.active, this.hiddenSections = const {}, this.extraNavItems = const [], this.showNotifications = true, this.showTheme = true, this.showLocale = true, this.showProfile = true, super.key});

  final String? userName;
  final VoidCallback? onProfileTap;
  final List<DashboardNavItem>? navItems;
  final DashboardSection? active;
  final Set<DashboardSection> hiddenSections;
  final List<DashboardNavItem> extraNavItems;
  final bool showNotifications;
  final bool showTheme;
  final bool showLocale;
  final bool showProfile;

  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final user = context.watch<AuthBloc>().state.maybeWhen(authenticated: (user) => user, orElse: () => null);
    final resolvedUserName = userName ?? user?.name ?? context.local.roleMember;
    final roleLabel = switch (user?.role) {
      'manager' => context.local.roleManager,
      'acting_manager' => context.local.roleActingManager,
      _ => context.local.roleMember,
    };
    final resolvedNavItems = navItems ?? [
      if (!hiddenSections.contains(DashboardSection.home)) DashboardNavItem(label: context.local.home, icon: Icons.home_rounded, active: active == DashboardSection.home, onTap: () => context.go(AppRoutes.home)),
      if (!hiddenSections.contains(DashboardSection.meals)) DashboardNavItem(label: context.local.meals, icon: Icons.restaurant_rounded, active: active == DashboardSection.meals, onTap: () => context.go(AppRoutes.meals)),
      if (!hiddenSections.contains(DashboardSection.deposits)) DashboardNavItem(label: context.local.deposits, icon: Icons.account_balance_wallet_rounded, active: active == DashboardSection.deposits, onTap: () => context.go(AppRoutes.deposits)),
      if (!hiddenSections.contains(DashboardSection.cost)) DashboardNavItem(label: context.local.cost, icon: Icons.shopping_cart_rounded, active: active == DashboardSection.cost, onTap: () => context.go(AppRoutes.costs)),
      ...extraNavItems,
    ];
    final themeMode = context.watch<ThemeBloc>().state.when(dark: (_) => AppThemeMode.dark, light: (_) => AppThemeMode.light, system: (_) => AppThemeMode.system);
    final themeIcon = switch (themeMode) {
      AppThemeMode.light => Icons.light_mode_rounded,
      AppThemeMode.dark => Icons.dark_mode_rounded,
      AppThemeMode.system => Icons.sunny_snowing,
    };

    return Material(
      color: colors.surfaceColor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.borderColor)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  // Progressive disclosure as the bar widens.
                  const showNavLabels = true;
                  final showBrandText = width >= 1050;
                  final showProfileText = width >= 1100;

                  return Row(
                    children: [
                      _Brand(showText: showBrandText),
                      if (resolvedNavItems.isNotEmpty) ...[
                        const SizedBox(width: Dimensions.paddingSizeExtraLarge32),
                        Expanded(child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                        for (final item in resolvedNavItems)
                          Padding(
                            padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                            child: _NavButton(item: item, showLabel: showNavLabels),
                          ),
                          ]),
                        )),
                      ],
                      if (resolvedNavItems.isEmpty) const Spacer(),
                      const _MembershipMenu(),
                      if (showNotifications) NotificationIconButton(color: colors.textSecondaryColor),
                      if (showTheme) _ActionIcon(
                        icon: themeIcon,
                        tooltip: context.local.uiThemeDescription(switch (themeMode) { AppThemeMode.light => context.local.uiLightMode, AppThemeMode.dark => context.local.darkMode, AppThemeMode.system => context.local.uiSystemDefault }),
                        onPressed: () => context.read<ThemeBloc>().add(ThemeEvent.changeThemeMode(themeMode.next)),
                      ),
                      if (showLocale) const _LocaleMenu(),
                      if (showProfile) ...[
                        const SizedBox(width: Dimensions.paddingSizeDefault),
                        _ProfileChip(roleLabel: roleLabel, userName: resolvedUserName, profileImageUrl: user?.photoUrl, showText: showProfileText, onTap: onProfileTap ?? () => Scaffold.of(context).openEndDrawer()),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.showText});
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
          child: AppLogo(size: 40, borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
        ),
        if (showText) ...[
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mess Pilot',
                style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.showLabel});
  final DashboardNavItem item;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final color = item.active ? colors.primaryColor : colors.textSecondaryColor;
    final background = item.active ? colors.primaryColor.withValues(alpha: 0.12) : Colors.transparent;

    // Icon-only when space is tight — keep the label in a tooltip.
    if (!showLabel) {
      return Tooltip(
        message: item.label,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Icon(item.icon, size: Dimensions.iconSizeDefault, color: color),
            ),
          ),
        ),
      );
    }

    return TextButton.icon(
      onPressed: item.onTap,
      icon: Icon(item.icon, size: Dimensions.iconSizeSmall, color: color),
      label: Text(
        item.label,
        style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: color),
      ),
      style: TextButton.styleFrom(
        backgroundColor: background,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      ),
    );
  }
}

class _MembershipMenu extends StatefulWidget {
  const _MembershipMenu();

  @override
  State<_MembershipMenu> createState() => _MembershipMenuState();
}

class _MembershipMenuState extends State<_MembershipMenu> {
  bool _switching = false;

  @override
  Widget build(BuildContext context) {
    if (context.findAncestorWidgetOfExactType<BlocProvider<MembershipCubit>>() == null) return const SizedBox.shrink();
    final state = context.watch<MembershipCubit>().state;
    if (state is! MembershipLoaded) return const SizedBox.shrink();
    final current = state.status.current;
    if (current == null) return const SizedBox.shrink();

    final memberships = state.status.memberships.where((membership) => membership.messId == current.messId).toList();
    if (!memberships.any((membership) => membership.seasonId == current.seasonId)) memberships.insert(0, current);
    memberships.sort((a, b) {
      if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
      return (b.seasonStartDate ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.seasonStartDate ?? DateTime.fromMillisecondsSinceEpoch(0));
    });
    final hasSwitch = memberships.any((membership) => membership.canSwitch && !membership.isCurrent);

    return Padding(
      padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: context.customThemeColors.primaryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                    child: Icon(Icons.apartment_rounded, size: Dimensions.iconSizeDefault, color: context.customThemeColors.primaryColor),
                  ),
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
        child: _MembershipChip(current: current, switching: _switching, hasSwitch: hasSwitch),
      ),
    );
  }

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

class _MembershipChip extends StatelessWidget {
  const _MembershipChip({required this.current, required this.switching, required this.hasSwitch});

  final MembershipSummaryEntity current;
  final bool switching;
  final bool hasSwitch;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final radius = BorderRadius.circular(Dimensions.radiusLarge);
    final initial = current.messName.trim().characters.take(1).toString().toUpperCase();
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: colors.primaryColor.withValues(alpha: 0.09),
        borderRadius: radius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusSmall + 2)),
            child: switching
                ? const Padding(padding: EdgeInsets.all(Dimensions.paddingSizeExtraSmall), child: CircularProgressIndicator(strokeWidth: 2))
                : Center(child: Text(initial.isEmpty ? '?' : initial, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall + 1, color: colors.primaryColor))),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(_limited(current.messName, 15), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textPrimaryColor))),
                    if (hasSwitch) ...[
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Icon(Icons.keyboard_arrow_down_rounded, size: Dimensions.iconSizeSmall, color: colors.primaryColor),
                    ],
                  ],
                ),
                Text(_limited(current.seasonName, 20), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: colors.textSecondaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _limited(String value, int max) {
    if (value.characters.length <= max) return value;
    return '${value.characters.take(max - 1).toString().trimRight()}…';
  }
}

class _LocaleMenu extends StatelessWidget {
  const _LocaleMenu();

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocalizationBloc>().state.locale;
    final currentLanguage = AppConstants.languages.firstWhere((language) => language.code == locale.languageCode, orElse: () => AppConstants.languages.firstWhere((language) => language.code == AppConstants.defaultLanguageCode));

    return PopupMenuButton<String>(
      tooltip: context.local.selectLanguage,
      onSelected: (code) => context.read<LocalizationBloc>().add(LocalizationEvent.changeLocale(code)),
      itemBuilder: (context) => AppConstants.languages
          .map(
            (language) => PopupMenuItem<String>(
              value: language.code,
              child: Row(
                children: [
                  _LocaleFlag(code: language.code),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(child: Text(language.nativeName, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (language.code == locale.languageCode) Icon(Icons.check_rounded, size: Dimensions.iconSizeSmall, color: context.customThemeColors.primaryColor),
                ],
              ),
            ),
          )
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeDefault),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LocaleFlag(code: currentLanguage.code),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text(currentLanguage.nativeName, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: context.customThemeColors.textPrimaryColor)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Icon(Icons.keyboard_arrow_down_rounded, color: context.customThemeColors.textPrimaryColor),
          ],
        ),
      ),
    );
  }
}

class _LocaleFlag extends StatelessWidget {
  const _LocaleFlag({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final flag = switch (code) {
      'ar' => Assets.images.svg.flags.ar,
      'bn' => Assets.images.svg.flags.bn,
      _ => Assets.images.svg.flags.en,
    };
    return ClipRRect(borderRadius: BorderRadius.circular(2), child: flag.svg(width: 28, height: 20, fit: BoxFit.cover));
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: context.customThemeColors.textSecondaryColor),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.roleLabel, required this.userName, required this.profileImageUrl, required this.showText, required this.onTap});
  final String roleLabel;
  final String userName;
  final String? profileImageUrl;
  final bool showText;
  final VoidCallback onTap;

  String get _initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final imageUrl = profileImageUrl?.trim() ?? '';
    final fallback = Center(child: Text(_initials, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.primaryColor)));

    final avatar = CircleAvatar(
      radius: 18,
      backgroundColor: colors.primaryColor.withValues(alpha: 0.15),
      child: imageUrl.isEmpty ? fallback : ClipOval(child: Image.network(imageUrl, width: 36, height: 36, fit: BoxFit.cover, cacheWidth: 108, cacheHeight: 108, errorBuilder: (_, _, _) => fallback)),
    );

    if (!showText) {
      return IconButton(tooltip: context.local.uiProfileMenu, onPressed: onTap, icon: avatar);
    }

    final radius = const BorderRadius.only(
      topLeft: Radius.circular(Dimensions.radiusLarge),
      bottomLeft: Radius.circular(Dimensions.radiusLarge),
      topRight: Radius.circular(Dimensions.radiusLarge),
      bottomRight: Radius.circular(Dimensions.radiusLarge),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Material(
        color: colors.backgroundColor,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeExtraSmall, Dimensions.paddingSizeExtraSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeExtraSmall),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                avatar,
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor)),
                      Text(roleLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: colors.textSecondaryColor)),
                    ],
                  ),
                ),
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Icon(Icons.keyboard_arrow_left_rounded, size: Dimensions.iconSizeSmall, color: colors.textSecondaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
