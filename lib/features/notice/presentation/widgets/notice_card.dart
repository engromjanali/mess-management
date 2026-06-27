import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/notice/domain/entities/notice_entity.dart';
import 'package:clean_boilerplate/features/notice/presentation/widgets/notice_formatters.dart';

class NoticeCard extends StatelessWidget {
  const NoticeCard({
    required this.notice,
    required this.showActions,
    this.onEdit,
    this.onDelete,
    this.onTogglePin,
    super.key,
  });

  final NoticeEntity notice;

  final bool showActions;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePin;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final pinned = notice.pinned;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeDefault,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryColor.withValues(alpha: context.isDarkMode ? 0.22 : 0.10),
            colors.secondaryColor.withValues(alpha: context.isDarkMode ? 0.14 : 0.06),
          ],
        ),
        // A pinned notice gets a bolder, solid accent border.
        border: Border.all(
          color: colors.primaryColor.withValues(alpha: pinned ? 0.85 : 0.30),
          width: pinned ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pinned) ...[_PinnedBadge(), const SizedBox(height: Dimensions.paddingSizeSmall)],
          Row(
            children: [
              Icon(
                Icons.campaign_rounded,
                size: Dimensions.iconSizeDefault,
                color: colors.primaryColor,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(
                  notice.title,
                  style: AppTextStyles.sfProRoundedBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                    color: colors.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            notice.description,
            style: AppTextStyles.sfProRoundedRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: colors.textSecondaryColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: Dimensions.fontSizeDefault,
                color: colors.textHintColor,
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Text(
                NoticeFormatters.time(notice.createdAt),
                style: AppTextStyles.sfProRoundedMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: colors.textHintColor,
                ),
              ),
              if (showActions) ...[
                const Spacer(),
                _NoticeActionButton(
                  icon: pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
                  tooltip: pinned ? 'Unpin' : 'Pin',
                  color: colors.primaryColor,
                  active: pinned,
                  onTap: onTogglePin,
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                _NoticeActionButton(
                  icon: Icons.edit_rounded,
                  tooltip: 'Edit',
                  color: colors.secondaryColor,
                  onTap: onEdit,
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                _NoticeActionButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete',
                  color: Colors.redAccent,
                  onTap: onDelete,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// A single circular, tinted action icon used in the notice card header row.
class _NoticeActionButton extends StatelessWidget {
  const _NoticeActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;

  /// When true the button is filled with [color] (e.g. a pinned notice).
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimensions.radiusDefault);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withValues(alpha: active ? 1 : 0.12),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            child: Icon(icon, size: Dimensions.iconSizeSmall, color: active ? Colors.white : color),
          ),
        ),
      ),
    );
  }
}

/// Small "Pinned" indicator chip shown at the top of the pinned notice.
class _PinnedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 3),
      decoration: BoxDecoration(
        color: colors.primaryColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.push_pin_rounded, size: Dimensions.fontSizeDefault, color: Colors.white),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text(
            'Pinned',
            style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall,color: Colors.white),
          ),
        ],
      ),
    );
  }
}
