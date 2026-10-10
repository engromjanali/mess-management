import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
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
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: (availableHeight * 0.25).clamp(48.0, 240.0)),
            child: SingleChildScrollView(child: Text(message, style: AppTextStyles.sfProRoundedRegular.copyWith(color: context.customThemeColors.textPrimaryColor, fontSize: Dimensions.fontSizeDefault))),
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: onDismiss ?? () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          padding: EdgeInsets.zero,
          icon: Icon(Icons.close_rounded, color: context.customThemeColors.textSecondaryColor, size: 20),
        ),
      ],
    );
  }
}
