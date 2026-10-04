import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/profile_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Desktop / big-tablet profile drawer (the `endDrawer` opened from the
/// `DashboardTopBar`). It offers the same features as the phone profile
/// screen — see [profileMenuItems]; the header opens the profile screen.
class WebProfileDrawer extends StatelessWidget {
  const WebProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.maybeWhen(authenticated: (user) => user, orElse: () => null);
    final isAdmin = context.watch<RoleCubit>().state.isAdmin;

    return Drawer(
      width: 380,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(user: user, onTap: () => _navigate(context, AppRoutes.profile)),
            Divider(height: 1, color: context.customThemeColors.borderColor),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                children: [
                  for (final item in profileMenuItems(context, isAdmin: isAdmin))
                    _DrawerItem(icon: item.icon, label: item.title, onTap: () => _navigate(context, item.route)),
                ],
              ),
            ),
            Divider(height: 1, color: context.customThemeColors.borderColor),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: context.local.logout,
              danger: true,
              onTap: () => confirmSignOut(context, beforeSignOut: () => Navigator.of(context).pop()),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }
}

/// Avatar, name and email; tapping it opens the profile screen.
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.user, required this.onTap});

  final UserEntity? user;
  final VoidCallback onTap;

  String get _initials {
    final parts = user?.name.trim().split(RegExp(r'\s+')) ?? [];
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final roleLabel = context.watch<RoleCubit>().state.isAdmin ? context.local.roleAdmin : context.local.roleUser;

    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: context.local.profile,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: colors.primaryColor.withValues(alpha: 0.15),
                        child: Text(_initials, style: AppTextStyles.sfProRoundedBold.copyWith(color: colors.primaryColor, fontSize: Dimensions.fontSizeExtraLarge)),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? context.local.roleUser,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.sfProRoundedBold.copyWith(color: colors.textPrimaryColor, fontSize: Dimensions.fontSizeLarge),
                            ),
                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                            Text(
                              user?.email ?? roleLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, fontSize: Dimensions.fontSizeSmall),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: colors.textHintColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(tooltip: MaterialLocalizations.of(context).closeButtonTooltip, onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.danger = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.customThemeColors.errorColor : context.customThemeColors.textPrimaryColor;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedMedium.copyWith(color: color)),
      trailing: Icon(Icons.chevron_right_rounded, color: context.customThemeColors.textHintColor),
      onTap: onTap,
    );
  }
}
