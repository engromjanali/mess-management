import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';

/// An attractive, responsive banner inviting users to share system feedback.
class FeedbackBannerCard extends StatelessWidget {
  const FeedbackBannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final isDark = context.isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.feedback),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      colors.primaryColor.withValues(alpha: 0.22),
                      colors.secondaryColor.withValues(alpha: 0.12),
                    ]
                  : [
                      colors.primaryColor.withValues(alpha: 0.10),
                      colors.secondaryColor.withValues(alpha: 0.05),
                    ],
            ),
            border: Border.all(
              color: colors.primaryColor.withValues(alpha: isDark ? 0.35 : 0.20),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colors.primaryColor,
                      colors.secondaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: Dimensions.spaceDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            context.local.feedbackBannerTitle,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: AppTextStyles.bold,
                              color: colors.textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                          ),
                          child: Text(
                            context.local.feedbackNew,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: AppTextStyles.bold,
                              color: colors.primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.local.feedbackBannerSubtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondaryColor,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Dimensions.spaceSmall),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
