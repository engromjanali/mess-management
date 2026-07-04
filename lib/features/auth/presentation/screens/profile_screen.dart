import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Profile screen — shows the signed-in user's details, current role and
/// quick links to settings / sign out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const HomeBackButton(), title: const Text('Profile')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.maybeWhen(authenticated: (user) => user, orElse: () => null);
          if (user == null) return const _SignedOutView();
          return _ProfileBody(user: user);
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
        child: ListView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          children: [
            _ProfileHeader(user: user),
            const SizedBox(height: Dimensions.spaceLarge),
            _ProfileTile(icon: Icons.savings_outlined, title: 'Fund', subtitle: 'View and manage funds', onTap: () => context.push(AppRoutes.funds)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _ProfileTile(icon: Icons.notifications_outlined, title: 'Notices', subtitle: 'View the notice board', onTap: () => context.push(AppRoutes.notices)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _ProfileTile(icon: Icons.settings_outlined, title: 'Settings', subtitle: 'Theme, language and preferences', onTap: () => context.push(AppRoutes.settings)),
            const SizedBox(height: Dimensions.spaceLarge),
            const Divider(),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _ProfileTile(icon: Icons.logout_rounded, title: 'Sign out', subtitle: 'Log out of your account', danger: true, onTap: () => _confirmSignOut(context)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sign out')),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;
    bloc.add(const AuthEvent.logoutRequested());
    context.go(AppRoutes.getLoginRoute());
  }
}

/// Avatar, name, email and role badge for the signed-in user.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final UserEntity user;

  String get _initials {
    final parts = user.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryColor.withValues(alpha: context.isDarkMode ? 0.22 : 0.10),
            colors.secondaryColor.withValues(alpha: context.isDarkMode ? 0.14 : 0.06),
          ],
        ),
        border: Border.all(color: colors.primaryColor.withValues(alpha: 0.30)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: colors.primaryColor.withValues(alpha: 0.15),
            backgroundImage: (user.photoUrl?.isNotEmpty ?? false) ? NetworkImage(user.photoUrl!) : null,
            child: (user.photoUrl?.isNotEmpty ?? false)
                ? null
                : Text(
                    _initials,
                    style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.iconSizeLarge, color: colors.primaryColor),
                  ),
          ),
          const SizedBox(height: Dimensions.spaceDefault),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textSecondaryColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          BlocBuilder<RoleCubit, UserRole>(builder: (context, role) => _RoleBadge(role: role)),
        ],
      ),
    );
  }
}

/// Small pill showing the current [UserRole].
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: 6),
      decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, size: Dimensions.iconSizeSmall, color: colors.primaryColor),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text(
            role.label,
            style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.primaryColor),
          ),
        ],
      ),
    );
  }
}

/// A single tappable settings-style row used in the profile body.
class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.danger = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final tint = danger ? Colors.redAccent : colors.primaryColor;
    final radius = BorderRadius.circular(Dimensions.radiusExtraLarge);
    return Material(
      color: colors.backgroundColor,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: colors.borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                child: Icon(icon, size: Dimensions.iconSizeDefault, color: tint),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: danger ? tint : colors.textPrimaryColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textHintColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when no user is authenticated.
class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: Dimensions.iconSizeExtraLarge, color: colors.textHintColor),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text('You are not signed in', style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor)),
            const SizedBox(height: Dimensions.spaceLarge),
            ElevatedButton.icon(onPressed: () => context.go(AppRoutes.getLoginRoute()), icon: const Icon(Icons.login_rounded), label: const Text('Sign in')),
          ],
        ),
      ),
    );
  }
}
