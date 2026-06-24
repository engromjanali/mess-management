import 'package:flutter/material.dart';
import '../../../../config/util/dimensions.dart';
import '../../../../config/util/styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/notice_entity.dart';
import 'notice_formatters.dart';

/// A single notice card — title, body, timestamp, and (for admins) a 3-dot
/// edit / delete menu.
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

  /// Whether the 3-dot edit / delete / pin menu is shown (admin only).
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
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryColor
                .withValues(alpha: context.isDarkMode ? 0.22 : 0.10),
            colors.secondaryColor
                .withValues(alpha: context.isDarkMode ? 0.14 : 0.06),
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
          if (pinned) ...[
            _PinnedBadge(),
            const SizedBox(height: Dimensions.paddingSizeSmall),
          ],
          Row(
            children: [
              Icon(Icons.campaign_rounded,
                  size: Dimensions.iconSizeDefault, color: colors.primaryColor),
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
              if (showActions)
                SizedBox(
                  height: 28,
                  child: PopupMenuButton<_NoticeAction>(
                    tooltip: 'Options',
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.more_vert_rounded,
                        color: colors.textSecondaryColor),
                    onSelected: (a) {
                      switch (a) {
                        case _NoticeAction.pin:
                          onTogglePin?.call();
                        case _NoticeAction.edit:
                          onEdit?.call();
                        case _NoticeAction.delete:
                          onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _NoticeAction.pin,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(pinned
                              ? Icons.push_pin_outlined
                              : Icons.push_pin_rounded),
                          title: Text(pinned ? 'Unpin' : 'Pin'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: _NoticeAction.edit,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_rounded),
                          title: Text('Edit'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: _NoticeAction.delete,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline_rounded),
                          title: Text('Delete'),
                        ),
                      ),
                    ],
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
              Icon(Icons.schedule_rounded,
                  size: Dimensions.fontSizeDefault, color: colors.textHintColor),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Text(
                NoticeFormatters.time(notice.createdAt),
                style: AppTextStyles.sfProRoundedMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: colors.textHintColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _NoticeAction { pin, edit, delete }

/// Small "Pinned" indicator chip shown at the top of the pinned notice.
class _PinnedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: colors.primaryColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.push_pin_rounded,
              size: Dimensions.fontSizeDefault, color: Colors.white),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text(
            'Pinned',
            style: AppTextStyles.sfProRoundedBold.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
