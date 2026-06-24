import 'package:flutter/material.dart';
import '../../../../config/util/dimensions.dart';
import '../../../../config/util/styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/deposit_entity.dart';
import 'deposit_formatters.dart';

/// One deposit row — signed amount with a Debit/Credit status badge, the
/// member/date context, an optional note, and (for admins) edit / delete.
class DepositTile extends StatelessWidget {
  const DepositTile({
    required this.deposit,
    required this.showMember,
    required this.showActions,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final DepositEntity deposit;

  /// Show the member name (by-date view) vs. just the date (by-member / mine).
  final bool showMember;

  /// Whether to render edit / delete buttons (admin only).
  final bool showActions;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final isCredit = deposit.isCredit;
    final accent = isCredit ? colors.successColor : colors.errorColor;

    final title = showMember
        ? deposit.memberName
        : DepositFormatters.date(deposit.date);
    final subtitle = showMember
        ? DepositFormatters.date(deposit.date)
        : (deposit.note?.isNotEmpty ?? false ? deposit.note! : null);

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: colors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // Credit / debit indicator.
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: accent,
              size: Dimensions.iconSizeDefault,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          // Title + context.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.sfProRoundedSemiBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: colors.textPrimaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    _StatusBadge(label: deposit.type.label, accent: accent),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sfProRoundedMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: colors.textSecondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          // Signed amount.
          Text(
            DepositFormatters.signedTaka(deposit.amount),
            style: AppTextStyles.sfProRoundedBold.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: accent,
            ),
          ),
          if (showActions) ...[
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            IconButton(
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.edit_rounded,
                  size: Dimensions.iconSizeDefault, color: colors.infoColor),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.delete_outline_rounded,
                  size: Dimensions.iconSizeDefault, color: colors.errorColor),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Text(
        label,
        style: AppTextStyles.sfProRoundedBold.copyWith(
          fontSize: Dimensions.fontSizeExtraSmall,
          color: accent,
        ),
      ),
    );
  }
}
