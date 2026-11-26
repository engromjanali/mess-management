import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/core/widgets/app_footer.dart';
import 'package:flutter/material.dart';

/// Scrollable page content with a full-width footer at the viewport bottom.
class AppPageScrollView extends StatelessWidget {
  const AppPageScrollView({this.child, this.children, this.padding = EdgeInsets.zero, this.physics, this.controller, this.maxWidth = double.infinity, this.showFooter = true, this.centerContent = false, super.key}) : assert(child == null || children == null);

  final Widget? child;
  final List<Widget>? children;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final double maxWidth;

  /// Web footer + its below-the-fold body height. Set false on pages that
  /// shouldn't show the app footer (e.g. auth screens, embedded sheets).
  final bool showFooter;

  /// Vertically centers short content (auth-style pages). Content pages stay
  /// top-aligned.
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    final showFooter = this.showFooter && (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context));
    return LayoutBuilder(
      builder: (context, viewport) => SingleChildScrollView(
        controller: controller,
        physics: physics,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Body is at least 105% of the viewport when the footer shows, so
            // the footer (placed after it) never peeks into the first screen.
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: showFooter ? viewport.maxHeight : viewport.maxHeight),
              child: Padding(
                padding: padding,
                child: centerContent
                    ? Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: child ?? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children ?? const []),
                        ),
                      )
                    : Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: child ?? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children ?? const []),
                        ),
                      ),
              ),
            ),
            if (showFooter) const AppFooter(),
          ],
        ),
      ),
    );
  }
}
