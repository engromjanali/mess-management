import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/features/home/domain/entities/dashboard_entity.dart';
import 'package:mess_pilot/features/home/presentation/widgets/dashboard_formatters.dart';

/// Highlighted card for the currently pinned notice.
class PinnedNoticeCard extends StatelessWidget {
  const PinnedNoticeCard({required this.notice, super.key});

  final NoticeEntity? notice;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryColor.withValues(alpha: context.isDarkMode ? 0.25 : 0.12),
            colors.secondaryColor.withValues(alpha: context.isDarkMode ? 0.18 : 0.08),
          ],
        ),
        border: Border.all(color: colors.primaryColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.push_pin_rounded, size: Dimensions.iconSizeSmall, color: colors.primaryColor),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                context.local.uiPinnedNotice,
                style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.primaryColor),
              ),
              const Spacer(),
              if (notice != null)
                Text(
                  notice!.noticeId,
                  style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
                ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          if (notice == null)
            Text(
              context.local.uiNoNoticePinnedRightNow,
              style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textSecondaryColor),
            )
          else ...[
            Text(
              notice!.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              notice!.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textSecondaryColor, height: 1.4),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: Dimensions.fontSizeDefault, color: colors.textHintColor),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Text(
                  DashboardFormatters.noticeTime(notice!.createdAt),
                  style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
