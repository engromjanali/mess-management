import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';

/// One entry of the profile menu.
class ProfileMenuItem {
  const ProfileMenuItem({required this.icon, required this.title, required this.subtitle, required this.route, this.danger = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  /// Shown in the error color (e.g. Delete account).
  final bool danger;
}

/// The profile menu, shared by the phone profile screen and the desktop
/// profile drawer so both offer the same features. The main sections (Home,
/// Meals, Deposits, Cost) live in the bottom / top bar instead. Sign out
/// follows the list; see [confirmSignOut].
///
/// [deletionScheduledFor] (the user asked to delete their account) shows the
/// date on the Delete account entry.
List<ProfileMenuItem> profileMenuItems(BuildContext context, {required bool isAdmin, DateTime? deletionScheduledFor}) => [
  ProfileMenuItem(icon: Icons.edit_outlined, title: context.local.editProfile, subtitle: context.local.editProfileSubtitle, route: AppRoutes.editProfile),
  ProfileMenuItem(icon: Icons.savings_outlined, title: context.local.fund, subtitle: context.local.fundSubtitle, route: AppRoutes.funds),
  ProfileMenuItem(icon: Icons.notifications_outlined, title: context.local.notices, subtitle: context.local.noticesSubtitle, route: AppRoutes.notices),
  ProfileMenuItem(icon: Icons.home_work_outlined, title: context.local.mess, subtitle: context.local.messSubtitle, route: AppRoutes.messDetails),
  // Everyone has memberships; managers also see the mess side there.
  ProfileMenuItem(icon: Icons.manage_accounts_rounded, title: context.local.membership, subtitle: context.local.membershipSubtitle, route: AppRoutes.manageMembership),
  if (isAdmin) ProfileMenuItem(icon: Icons.event_repeat_rounded, title: context.local.seasonManagement, subtitle: context.local.seasonManagementSubtitle, route: AppRoutes.seasons),
  ProfileMenuItem(icon: Icons.settings_outlined, title: context.local.settings, subtitle: context.local.settingsSubtitle, route: AppRoutes.settings),
  ProfileMenuItem(icon: Icons.help_outline_rounded, title: context.local.faq, subtitle: context.local.faqSubtitle, route: AppRoutes.faq),
  ProfileMenuItem(icon: Icons.privacy_tip_outlined, title: context.local.privacyPolicy, subtitle: context.local.privacyPolicySubtitle, route: AppRoutes.privacyPolicy),
  ProfileMenuItem(icon: Icons.gavel_rounded, title: context.local.termsAndConditions, subtitle: context.local.termsSubtitle, route: AppRoutes.termsAndConditions),
  ProfileMenuItem(
    icon: Icons.delete_forever_outlined,
    title: context.local.deleteAccount,
    subtitle: deletionScheduledFor == null
        ? context.local.deleteAccountSubtitle
        : context.local.deletionScheduledBanner(DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(deletionScheduledFor)),
    route: AppRoutes.deleteAccount,
    danger: true,
  ),
];

/// Asks to confirm, then signs out and opens the login screen. [beforeSignOut]
/// runs once confirmed (e.g. to close the drawer).
Future<void> confirmSignOut(BuildContext context, {VoidCallback? beforeSignOut}) async {
  final authBloc = context.read<AuthBloc>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.local.logout),
      content: Text(context.local.logoutConfirm),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(context.local.cancel)),
        FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(context.local.logout)),
      ],
    ),
  );
  if (!(confirmed ?? false) || !context.mounted) return;
  beforeSignOut?.call();
  authBloc.add(const AuthEvent.logoutRequested());
  context.go(AppRoutes.getLoginRoute());
}
