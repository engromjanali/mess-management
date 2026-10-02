import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/helpers/responsive_helper.dart';
import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';
import 'package:clean_boilerplate/features/cost/presentation/widgets/cost_formatters.dart';

/// One Cost entry card — an index badge, the timestamp + person, the total
/// (maskable), a 3-dot menu (admin), and an expandable product breakdown.
class CostTile extends StatefulWidget {
  const CostTile({required this.cost, required this.index, required this.maskCost, required this.showActions, this.onEdit, this.onDelete, super.key});

  final CostEntity cost;
  final int index;

  /// When true the total / prices are hidden behind a mask.
  final bool maskCost;

  /// Whether the 3-dot edit / delete menu is shown (admin only).
  final bool showActions;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<CostTile> createState() => _CostTileState();
}

class _CostTileState extends State<CostTile> {
  bool _expanded = false;

  String _amount(double v) => widget.maskCost ? '৳ ••••' : CostFormatters.taka(v);

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final cost = widget.cost;
    final showActionMenu = ResponsiveHelper.isMobile(context) || ResponsiveHelper.isSmallTab(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row — tap to expand / collapse.
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Row(
                children: [
                  _IndexBadge(index: widget.index),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CostFormatters.stamp(cost.date),
                          style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cost.personName,
                          style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Text(
                    _amount(cost.total),
                    style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
                  ),
                  Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: colors.textHintColor),
                  if (widget.showActions && showActionMenu)
                    PopupMenuButton<_CostAction>(
                      tooltip: context.local.options,
                      icon: Icon(Icons.more_vert_rounded, color: colors.textSecondaryColor),
                      onSelected: (a) {
                        switch (a) {
                          case _CostAction.edit:
                            widget.onEdit?.call();
                          case _CostAction.delete:
                            widget.onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _CostAction.edit,
                          child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.edit_rounded), title: Text(context.local.edit)),
                        ),
                        PopupMenuItem(
                          value: _CostAction.delete,
                          child: ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.delete_outline_rounded), title: Text(context.local.delete)),
                        ),
                      ],
                    ),
                  if (widget.showActions && !showActionMenu) ...[
                    IconButton(tooltip: context.local.edit, onPressed: widget.onEdit, icon: Icon(Icons.edit_rounded, color: colors.primaryColor)),
                    IconButton(tooltip: context.local.delete, onPressed: widget.onDelete, icon: Icon(Icons.delete_outline_rounded, color: colors.errorColor)),
                  ],
                ],
              ),
            ),
          ),
          // Expanded detail.
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: _Details(cost: cost, maskCost: widget.maskCost),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

enum _CostAction { edit, delete }

class _IndexBadge extends StatelessWidget {
  const _IndexBadge({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return CircleAvatar(
      radius: 18,
      backgroundColor: colors.errorColor,
      child: Text(
        '$index',
        style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white),
      ),
    );
  }
}

/// The expandable breakdown — meta lines + a product/price table.
class _Details extends StatelessWidget {
  const _Details({required this.cost, required this.maskCost});
  final CostEntity cost;
  final bool maskCost;

  String _price(double v) => maskCost ? '••••' : CostFormatters.number(v);

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: colors.borderColor, height: Dimensions.paddingSizeLarge),
          // Meta data — compact chips that wrap on narrow screens.
          Wrap(
            spacing: Dimensions.paddingSizeSmall,
            runSpacing: Dimensions.paddingSizeSmall,
            children: [
              _MetaChip(icon: Icons.tag_rounded, text: context.local.costEntryId(cost.id)),
              _MetaChip(icon: Icons.calendar_today_rounded, text: context.local.costDateValue(CostFormatters.date(cost.date))),
              _MetaChip(icon: Icons.access_time_rounded, text: context.local.costTimeValue(CostFormatters.time(cost.date))),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(
            context.local.productsBought,
            style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          // Table header.
          _Row(sl: context.local.serialNo, product: context.local.product, price: context.local.price, bold: true, color: colors.textPrimaryColor),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          for (var i = 0; i < cost.items.length; i++)
            Container(
              color: i.isEven ? colors.warningColor.withValues(alpha: 0.10) : colors.successColor.withValues(alpha: 0.10),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _Row(sl: '${i + 1}.', product: cost.items[i].product, price: _price(cost.items[i].price), color: colors.textPrimaryColor),
            ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          // Total row.
          _Row(sl: '', product: context.local.total, price: maskCost ? '••••' : CostFormatters.number(cost.total), bold: true, color: colors.primaryColor),
        ],
      ),
    );
  }
}

/// One meta-data item (icon + text) in a soft, rounded chip.
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall + 2, vertical: Dimensions.paddingSizeExtraSmall + 2),
      decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Dimensions.iconSizeSmall - 2, color: colors.primaryColor),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall + 2),
          Text(text, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textPrimaryColor)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.sl, required this.product, required this.price, required this.color, this.bold = false});

  final String sl;
  final String product;
  final String price;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = (bold ? AppTextStyles.sfProRoundedBold : AppTextStyles.sfProRoundedMedium).copyWith(fontSize: Dimensions.fontSizeDefault, color: color);

    return Row(
      children: [
        SizedBox(width: 56, child: Text(sl, style: style)),
        Expanded(
          child: Text(product, textAlign: TextAlign.center, style: style),
        ),
        SizedBox(
          width: 72,
          child: Text(price, textAlign: TextAlign.right, style: style),
        ),
      ],
    );
  }
}
