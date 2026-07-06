import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/settings/domain/entities/theme_mode.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
            _DrawerHeader(user: user),
            Divider(height: 1, color: context.customThemeColors.borderColor),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                children: [
                  _DrawerItem(icon: Icons.home_rounded, label: 'Home', onTap: () => _navigate(context, AppRoutes.home)),
                  _DrawerItem(icon: Icons.restaurant_rounded, label: 'Meals', onTap: () => _navigate(context, AppRoutes.meals)),
                  if (isAdmin) _DrawerItem(icon: Icons.add_circle_outline_rounded, label: 'Add Meal', onTap: () => _navigate(context, AppRoutes.addMeal)),
                  _DrawerItem(icon: Icons.account_balance_wallet_rounded, label: 'Deposits', onTap: () => _navigate(context, AppRoutes.deposits)),
                  _DrawerItem(icon: Icons.savings_rounded, label: 'Fund', onTap: () => _navigate(context, AppRoutes.funds)),
                  _DrawerItem(icon: Icons.shopping_cart_rounded, label: 'Cost', onTap: () => _navigate(context, AppRoutes.costs)),
                  _DrawerItem(icon: Icons.push_pin_rounded, label: 'Notices', onTap: () => _navigate(context, AppRoutes.notices)),
                  const Divider(),
                  _DrawerItem(icon: Icons.person_rounded, label: 'Profile', onTap: () => _navigate(context, AppRoutes.profile)),
                  _DrawerItem(
                    icon: context.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    label: context.isDarkMode ? 'Light mode' : 'Dark mode',
                    onTap: () => context.read<ThemeBloc>().add(ThemeEvent.changeThemeMode(context.isDarkMode ? AppThemeMode.light : AppThemeMode.dark)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.customThemeColors.borderColor),
            _DrawerItem(icon: Icons.logout_rounded, label: 'Sign out', danger: true, onTap: () => _confirmSignOut(context)),
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

  Future<void> _confirmSignOut(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Sign out')),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;
    Navigator.of(context).pop();
    authBloc.add(const AuthEvent.logoutRequested());
    context.go(AppRoutes.getLoginRoute());
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.user});

  final UserEntity? user;

  String get _initials {
    final parts = user?.name.trim().split(RegExp(r'\s+')) ?? [];
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final role = context.watch<RoleCubit>().state;

    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge24),
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
                Text(user?.name ?? 'User', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedBold.copyWith(color: colors.textPrimaryColor, fontSize: Dimensions.fontSizeLarge)),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text(user?.email ?? role.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, fontSize: Dimensions.fontSizeSmall)),
              ],
            ),
          ),
          IconButton(tooltip: 'Close', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded)),
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
