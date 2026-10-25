import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Back button for top-level destinations.
///
/// Top-level screens are reached with `context.go(...)`, so there is usually
/// nothing on the navigation stack to pop. This pops when possible (e.g. when
/// the screen was pushed as a drill-down) and otherwise navigates home, so the
/// user is never stranded — on web, mobile or deep links.
class HomeBackButton extends StatelessWidget {
  const HomeBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: const BackButtonIcon(), tooltip: MaterialLocalizations.of(context).backButtonTooltip, onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home));
  }
}
