import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/core/widgets/app_footer.dart';
import 'package:flutter/material.dart';

/// Scrollable page content with a full-width footer at the viewport bottom.
class AppPageScrollView extends StatelessWidget {
  const AppPageScrollView({this.child, this.children, this.padding = EdgeInsets.zero, this.physics, this.controller, this.maxWidth = double.infinity, super.key}) : assert(child == null || children == null);

  final Widget? child;
  final List<Widget>? children;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final showFooter = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);
    return LayoutBuilder(
      builder: (context, viewport) => SingleChildScrollView(
        controller: controller,
        physics: physics,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewport.maxHeight),
          child: Column(
            mainAxisAlignment: showFooter ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: padding,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: child ?? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children ?? const []),
                  ),
                ),
              ),
              if (showFooter) const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
