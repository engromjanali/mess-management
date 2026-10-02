import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';

/// Common desktop / big-tablet title bar: a primary-colored strip with the
/// page title centered. Shown under the `DashboardTopBar` on screens that have
/// no menu entry in it (e.g. Funds), so the page keeps its title like the
/// mobile `AppBar`.
class WebPageTitleBar extends StatelessWidget {
  const WebPageTitleBar({required this.title, super.key});

  final String title;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Material(
      color: colors.primaryColor.withAlpha(100),
      child: SizedBox(
        height: height,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
