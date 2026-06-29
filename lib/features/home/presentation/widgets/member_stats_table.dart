import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/home/domain/entities/dashboard_entity.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';

/// Manager-only breakdown of every member's deposit / meal / remaining.
///
/// Collapsed by default to the first few rows with a "Show more" toggle,
/// mirroring the legacy first screen's see-more behaviour.
class MemberStatsTable extends StatefulWidget {
  const MemberStatsTable({required this.members, required this.mealRate, super.key});

  final List<MemberStatEntity> members;
  final double mealRate;

  @override
  State<MemberStatsTable> createState() => _MemberStatsTableState();
}

class _MemberStatsTableState extends State<MemberStatsTable> {
  static const _collapsedCount = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final visible = _expanded ? widget.members : widget.members.take(_collapsedCount).toList();
    final canToggle = widget.members.length > _collapsedCount;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeaderRow(context),
          Divider(height: 1, color: colors.dividerColor.withValues(alpha: 0.4)),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Column(children: [for (var i = 0; i < visible.length; i++) _buildMemberRow(context, i, visible[i])]),
          ),
          if (canToggle)
            TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              label: Text(_expanded ? 'Show less' : 'Show all members'),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final colors = context.customThemeColors;
    final style = AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: style)),
          Expanded(flex: 3, child: Text('Member', style: style)),
          Expanded(
            child: Text('Deposit', style: style, textAlign: TextAlign.end),
          ),
          Expanded(
            child: Text('Meal', style: style, textAlign: TextAlign.end),
          ),
          Expanded(
            child: Text('Remaining', style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(BuildContext context, int index, MemberStatEntity m) {
    final colors = context.customThemeColors;
    final remaining = m.remaining(widget.mealRate);
    final remainingColor = remaining < 0 ? colors.errorColor : colors.successColor;

    final valueStyle = AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textPrimaryColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colors.primaryColor.withValues(alpha: 0.15),
            child: Text(
              '${index + 1}',
              style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: colors.primaryColor),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            flex: 3,
            child: Text(
              m.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor),
            ),
          ),
          Expanded(
            child: Text(DashboardFormatters.taka(m.deposit), style: valueStyle, textAlign: TextAlign.end),
          ),
          Expanded(
            child: Text(DashboardFormatters.number(m.meal), style: valueStyle, textAlign: TextAlign.end),
          ),
          Expanded(
            child: Text(
              DashboardFormatters.taka(remaining),
              textAlign: TextAlign.end,
              style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: remainingColor),
            ),
          ),
        ],
      ),
    );
  }
}
