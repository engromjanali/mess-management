import 'package:mess_pilot/core/widgets/app_page_scroll_view.dart';
import 'package:mess_pilot/core/widgets/app_user_avatar.dart';
import 'package:mess_pilot/core/widgets/app_state_view.dart';
import 'package:mess_pilot/core/widgets/app_loader.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/role/role_cubit.dart';
import 'package:mess_pilot/core/widgets/home_back_button.dart';
import 'package:mess_pilot/features/auth/domain/entities/user_entity.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:mess_pilot/features/home/presentation/widgets/main_page_body.dart';
import 'package:mess_pilot/features/home/presentation/widgets/profile_menu.dart';
import 'package:mess_pilot/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Profile screen — the signed-in user's details and current role, then the
/// profile menu ([profileMenuItems], the same features as the desktop profile
/// drawer) and sign out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = MainPageBody.showWebAppBar(context);
    return Scaffold(
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.profile)),
      body: MainPageBody(
        title: context.local.profile,
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state.maybeWhen(authenticated: (user) => user, orElse: () => null);
            if (user != null) return _ProfileBody(user: user);
            final isSignedOut = state.maybeWhen(unauthenticated: () => true, error: (_) => true, orElse: () => false);
            if (isSignedOut) return const _SignedOutView();
            return const Center(child: AppLoader());
          },
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return AppPageScrollView(
          maxWidth: Dimensions.webMaxWidth,
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          children: [
            _ProfileHeader(user: user),
            const SizedBox(height: Dimensions.spaceLarge),
            for (final item in profileMenuItems(context, canManage: context.watch<RoleCubit>().state.canManage, deletionScheduledFor: user.deletionScheduledFor)) ...[
              _ProfileTile(icon: item.icon, title: item.title, subtitle: item.subtitle, danger: item.danger, onTap: () => context.push(item.route)),
              const SizedBox(height: Dimensions.paddingSizeSmall),
            ],
            const SizedBox(height: Dimensions.spaceLarge),
            const Divider(),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _ProfileTile(icon: Icons.logout_rounded, title: context.local.logout, subtitle: context.local.logoutSubtitle, danger: true, onTap: () => confirmSignOut(context)),
          ],
    );
  }
}

/// Avatar, name, email and role badge for the signed-in user.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final UserEntity user;

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
          AppUserAvatar(name: user.name, photoUrl: user.photoUrl, radius: 40),
          const SizedBox(height: Dimensions.spaceDefault),
          Text(
            user.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            user.email,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            switch (role) {
              UserRole.manager => context.local.roleManager,
              UserRole.actingManager => context.local.roleActingManager,
              UserRole.member => context.local.roleMember,
            },
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: danger ? tint : colors.textPrimaryColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
    return AppStateView(title: context.local.notSignedIn, message: context.local.signInAgain, icon: Icons.person_outline_rounded, onAction: () => context.go(AppRoutes.getLoginRoute()), actionLabel: context.local.login, actionIcon: Icons.login_rounded);
  }
}
