import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/core/widgets/animated_bottom_nav_bar.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';


class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  /// Accumulated pixel delta before the scroll direction flips the navbar.
  /// Accumulating (instead of checking a single frame) keeps slow drags working.
  static const double _directionThreshold = 4;

  bool _navbarVisible = true;
  double? _lastScrollPixels;
  double _scrollAccumulator = 0;
  int? _lastBranchIndex;

  @override
  void initState() {
    super.initState();
    _lastBranchIndex = widget.navigationShell.currentIndex;
  }

  @override
  void didUpdateWidget(covariant MainNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.navigationShell.currentIndex;
    if (index != _lastBranchIndex) {
      _lastBranchIndex = index;
      _resetScrollTracking();
      _navbarVisible = true;
    }
  }

  void _resetScrollTracking() {
    _lastScrollPixels = null;
    _scrollAccumulator = 0;
  }

  void _setNavbarVisible(bool visible) {
    if (visible == _navbarVisible) return;
    setState(() => _navbarVisible = visible);
  }

  /// Hides the navbar while scrolling down and shows it again when scrolling up.
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final metrics = notification.metrics;
    final pixels = metrics.pixels;

    if (notification is ScrollStartNotification) {
      _lastScrollPixels = pixels;
      _scrollAccumulator = 0;
      return false;
    }

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        _setNavbarVisible(false);
      } else if (notification.direction == ScrollDirection.forward) {
        _setNavbarVisible(true);
      }
      return false;
    }

    if (notification is ScrollEndNotification) {
      _resetScrollTracking();
      return false;
    }

    if (notification is! ScrollUpdateNotification) return false;

    final previous = _lastScrollPixels;
    _lastScrollPixels = pixels;
    final delta = notification.scrollDelta ?? (previous == null ? 0 : pixels - previous);
    _scrollAccumulator += delta;

    // Always reveal the navbar at the very top of the list.
    if (pixels <= metrics.minScrollExtent) {
      _scrollAccumulator = 0;
      _setNavbarVisible(true);
      return false;
    }

    if (_scrollAccumulator > _directionThreshold) {
      _scrollAccumulator = 0;
      _setNavbarVisible(false);
    } else if (_scrollAccumulator < -_directionThreshold) {
      _scrollAccumulator = 0;
      _setNavbarVisible(true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    if (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context)) return navigationShell;

    final currentIndex = navigationShell.currentIndex;
    final photoUrl = context.select<AuthBloc, String?>((bloc) => bloc.state.maybeWhen(authenticated: (user) => user.photoUrl, orElse: () => null));

    void navigate(int index) {
      if (index != currentIndex) navigationShell.goBranch(index);
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: navigationShell,
            ),
          ),
          if (MediaQuery.viewInsetsOf(context).bottom == 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Align(
                heightFactor: 1,
                child: AnimatedBottomNavBar(
                  currentIndex: currentIndex,
                  visible: _navbarVisible,
                  items: [
                    BottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: context.local.home, onTap: () => navigate(0)),
                    BottomNavItem(icon: Icons.restaurant_outlined, activeIcon: Icons.restaurant_rounded, label: context.local.meals, onTap: () => navigate(1)),
                    BottomNavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: context.local.deposits, onTap: () => navigate(2)),
                    BottomNavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart_rounded, label: context.local.cost, onTap: () => navigate(3)),
                    BottomNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: context.local.profile, profileImageUrl: photoUrl ?? '', onTap: () => navigate(4)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
