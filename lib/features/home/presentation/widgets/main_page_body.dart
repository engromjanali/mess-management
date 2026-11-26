import 'package:flutter/material.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/core/widgets/web_page_title_bar.dart';
import 'package:mess_pilot/features/home/presentation/widgets/main_top_bar.dart';

/// Scaffold body for a screen outside the main sections. On desktop / big
/// tablet it puts [MainTopBar] and a [WebPageTitleBar] ([title]) above
/// [child]; on phones it's just [child] (the screen keeps its `AppBar`).
///
/// Pair it with `endDrawer: const WebProfileDrawer()` and no `AppBar` on
/// desktop — see [MainPageBody.showWebAppBar].
class MainPageBody extends StatelessWidget {
  const MainPageBody({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  /// Whether the screen shows the web bars instead of a Material `AppBar`.
  static bool showWebAppBar(BuildContext context) => ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);

  @override
  Widget build(BuildContext context) {
    // The bars occupy a single slot of fixed type so crossing the responsive
    // breakpoint never changes [child]'s position in the tree — that would
    // remount the whole subtree and reset its blocs/form/scroll state. The
    // bars are simply not built on phones (no eager provider dependencies).
    final webAppBar = showWebAppBar(context);
    return Column(
      children: [
        webAppBar
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MainTopBar(),
                  WebPageTitleBar(title: title),
                ],
              )
            : const SizedBox.shrink(),
        Expanded(child: child),
      ],
    );
  }
}
