import 'package:flutter/material.dart';
import 'package:clean_boilerplate/core/helpers/responsive_helper.dart';
import 'package:clean_boilerplate/core/widgets/web_page_title_bar.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/main_top_bar.dart';

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
    if (!showWebAppBar(context)) return child;
    return Column(
      children: [
        const MainTopBar(),
        WebPageTitleBar(title: title),
        Expanded(child: child),
      ],
    );
  }
}
