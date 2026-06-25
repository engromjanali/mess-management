import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/fund/domain/entities/fund_entity.dart';
import 'package:clean_boilerplate/features/fund/presentation/widgets/fund_formatters.dart';

/// One fund row — signed amount with a Debit/Credit status badge, the date,
/// and (for admins) edit / delete.
class FundTile extends StatelessWidget {
  const FundTile({
    required this.fund,
    required this.showActions,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final FundEntity fund;

  /// Whether to render edit / delete buttons (admin only).
  final bool showActions;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final isCredit = fund.isCredit;
    final accent = isCredit ? colors.successColor : colors.errorColor;

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
              isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: accent,
              size: Dimensions.iconSizeDefault,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          // Date + status.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FundFormatters.date(fund.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedSemiBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: colors.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _StatusBadge(label: fund.type.label, accent: accent),
                    if (fund.note?.isNotEmpty ?? false) ...[
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Flexible(
                        child: Text(
                          fund.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.sfProRoundedMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: colors.textSecondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          // Signed amount.
          Text(
            FundFormatters.signedTaka(fund.amount),
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
