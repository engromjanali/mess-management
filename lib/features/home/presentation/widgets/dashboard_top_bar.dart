import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/assets/assets.gen.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/settings/domain/entities/theme_mode.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_event.dart';

/// A single navigation entry rendered in the [DashboardTopBar].
class DashboardNavItem {
  const DashboardNavItem({required this.label, required this.icon, required this.onTap, this.active = false});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
}

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({required this.userName, required this.onProfileTap, this.navItems = const [], super.key});

  final String userName;
  final VoidCallback onProfileTap;
  final List<DashboardNavItem> navItems;

  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

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
                      if (navItems.isNotEmpty) ...[
                        const SizedBox(width: Dimensions.paddingSizeExtraLarge32),
                        for (final item in navItems)
                          Padding(
                            padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                            child: _NavButton(item: item, showLabel: showNavLabels),
                          ),
                      ],
                      const Spacer(),
                      _ActionIcon(icon: Icons.notifications_outlined, tooltip: 'Notifications', onPressed: () => context.go(AppRoutes.notices)),
                      _ActionIcon(
                        icon: context.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        tooltip: 'Toggle theme',
                        onPressed: () => context.read<ThemeBloc>().add(ThemeEvent.changeThemeMode(context.isDarkMode ? AppThemeMode.light : AppThemeMode.dark)),
                      ),
                      const _LocaleMenu(),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      _ProfileChip(userName: userName, showText: showProfileText, onTap: onProfileTap),
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
          child: Icon(Icons.restaurant_menu_rounded, color: colors.primaryColor, size: Dimensions.iconSizeDefault),
        ),
        if (showText) ...[
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mess Manager',
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

class _LocaleMenu extends StatelessWidget {
  const _LocaleMenu();

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocalizationBloc>().state.locale;
    final currentLanguage = AppConstants.languages.firstWhere((language) => language.code == locale.languageCode, orElse: () => AppConstants.languages.first);

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
  const _ProfileChip({required this.userName, required this.showText, required this.onTap});
  final String userName;
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

    final avatar = CircleAvatar(
      radius: 18,
      backgroundColor: colors.primaryColor.withValues(alpha: 0.15),
      child: Text(
        _initials,
        style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.primaryColor),
      ),
    );

    if (!showText) {
      return IconButton(tooltip: 'Profile menu', onPressed: onTap, icon: avatar);
    }

    final radius = BorderRadius.circular(Dimensions.radiusExtra2Large);
    return Material(
      color: colors.backgroundColor,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeExtraSmall, Dimensions.paddingSizeExtraSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeExtraSmall),
          decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: colors.borderColor)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              const SizedBox(width: Dimensions.paddingSizeSmall),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor)),
                    Text('Member', style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: colors.textSecondaryColor)),
                  ],
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Icon(Icons.keyboard_arrow_left_rounded, size: Dimensions.iconSizeSmall, color: colors.textSecondaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
