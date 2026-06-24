import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/animated_entrance.dart';
import 'package:flutter/material.dart';

/// Shared, modern auth shell used by the sign-in and sign-up screens.
///
/// Uses the app's standard scaffold background (matching the rest of the
/// project) with a floating brand badge, title and subtitle, and a rounded
/// surface card that hosts the form [child]. Responsive (card capped for
/// web/tablet).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  /// Optional top-right action (e.g. an info button).
  final Widget? action;

  /// Auth forms read better narrow — cap well below [Dimensions.webMaxWidth].
  static const double _maxCardWidth = 460;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeLarge,
              vertical: Dimensions.paddingSizeExtraLarge32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxCardWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hero: brand badge + greeting.
                  AnimatedEntrance(
                    child: Column(
                      children: [
                        Container(
                          height: 76,
                          width: 76,
                          decoration: BoxDecoration(
                            color: colors.primaryColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.primaryColor.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            icon,
                            size: Dimensions.iconSizeLarge,
                            color: colors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.sfProRoundedBold.copyWith(
                            color: colors.textPrimaryColor,
                            fontSize: Dimensions.fontSizeExtraOverLarge,
                          ),
                        ),
                        const SizedBox(
                          height: Dimensions.paddingSizeExtraSmall,
                        ),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.sfProRoundedRegular.copyWith(
                            color: colors.textSecondaryColor,
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeExtraLarge24),

                  // Form sheet.
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 120),
                    child: Container(
                      padding: const EdgeInsets.all(
                        Dimensions.paddingSizeExtraLarge24,
                      ),
                      decoration: BoxDecoration(
                        color: colors.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusExtra2Large,
                        ),
                        border: Border.all(color: colors.borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadowColor,
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),

                  if (footer != null) ...[
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 220),
                      child: footer!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
            if (action != null)
              Positioned(
                top: Dimensions.paddingSizeSmall,
                right: Dimensions.paddingSizeSmall,
                child: action!,
              ),
          ],
        ),
      ),
    );
  }
}

/// "Don't have an account? Sign up" style footer row.
class AuthFooterPrompt extends StatelessWidget {
  const AuthFooterPrompt({
    required this.promptText,
    required this.actionText,
    required this.onTap,
    super.key,
  });

  final String promptText;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          promptText,
          style: AppTextStyles.sfProRoundedRegular.copyWith(
            color: colors.textSecondaryColor,
            fontSize: Dimensions.fontSizeDefault,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: Text(
              actionText,
              style: AppTextStyles.sfProRoundedBold.copyWith(
                color: colors.primaryColor,
                fontSize: Dimensions.fontSizeDefault,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
