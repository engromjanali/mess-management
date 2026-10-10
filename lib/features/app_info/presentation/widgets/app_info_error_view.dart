import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';

/// The backend's error message with a Try again button.
class AppInfoErrorView extends StatelessWidget {
  const AppInfoErrorView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: Dimensions.iconSizeExtraLarge, color: colors.errorColor),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor)),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(context.local.tryAgain)),
          ],
        ),
      ),
    );
  }
}
