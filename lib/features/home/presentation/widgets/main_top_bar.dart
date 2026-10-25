import 'package:flutter/material.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_top_bar.dart';

/// Desktop / big-tablet app bar with the main sections, for screens that use
/// the shared layout. [active] marks the current section; screens outside the
/// main sections (e.g. Mess, Membership) leave it null and add a
/// `WebPageTitleBar` below. Must sit below the `Scaffold` (it opens the end
/// drawer) — use it inside the body.
///
/// This is a thin wrapper around [DashboardTopBar] that uses the built-in
/// default navItems. Pass [hiddenSections] or [extraNavItems] to customise.
class MainTopBar extends StatelessWidget {
  const MainTopBar({this.active, this.hiddenSections = const {}, this.extraNavItems = const [], super.key});

  final DashboardSection? active;
  final Set<DashboardSection> hiddenSections;
  final List<DashboardNavItem> extraNavItems;

  @override
  Widget build(BuildContext context) {
    return DashboardTopBar(
      active: active,
      hiddenSections: hiddenSections,
      extraNavItems: extraNavItems,
    );
  }
}
