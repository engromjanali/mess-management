import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:flutter/material.dart';

class AppSnackbarContent extends StatelessWidget {
  const AppSnackbarContent({required this.message, required this.icon, required this.color, this.onDismiss, super.key});

  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewInsets.bottom - media.viewPadding.bottom;
    final compact = ResponsiveHelper.isSmallMobile(context);
    final tablet = ResponsiveHelper.isTab(context);
    final iconExtent = compact ? 32.0 : tablet ? 40.0 : 36.0;
    final iconSize = compact ? 20.0 : tablet ? 24.0 : 22.0;
    final iconRadius = compact ? 8.0 : tablet ? 10.0 : 8.0;
    final dismissExtent = compact ? 34.0 : 40.0;
    final textSize = compact ? 13.0 : tablet ? 15.0 : Dimensions.fontSizeDefault;
    final maxTextHeight = (availableHeight * (compact ? 0.3 : tablet ? 0.32 : 0.25)).clamp(48.0, tablet ? 320.0 : 240.0);
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Container(
            width: iconExtent,
            height: iconExtent,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(iconRadius)),
            child: Icon(icon, color: color, size: iconSize),
          ),
          SizedBox(width: compact ? Dimensions.paddingSizeSmall : Dimensions.paddingSizeDefault),
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxTextHeight),
              child: SingleChildScrollView(
                child: Text(
                  message,
                  style: AppTextStyles.sfProRoundedMedium.copyWith(color: context.customThemeColors.textPrimaryColor, fontSize: textSize, height: 1.35),
                ),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onDismiss ?? () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            constraints: BoxConstraints.tightFor(width: dismissExtent, height: dismissExtent),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close_rounded, color: context.customThemeColors.textSecondaryColor, size: compact ? 18 : 20),
          ),
        ],
      ),
    );
  }
}
