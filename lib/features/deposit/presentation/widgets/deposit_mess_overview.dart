import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/widgets/stat_card.dart';
import 'package:clean_boilerplate/features/deposit/domain/entities/deposit_mess_summary_entity.dart';
import 'package:clean_boilerplate/features/deposit/presentation/widgets/deposit_formatters.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/animated_entrance.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/section_title.dart';

/// Admin-only deposit overview: the manager's own totals (a manager is also a member),
/// mess-wide totals, and a per-member balance breakdown.
class DepositMessOverview extends StatelessWidget {
  const DepositMessOverview({required this.summary, super.key});
  final DepositMessSummaryEntity summary;

  @override
  Widget build(BuildContext context) {
    final c = context.customThemeColors;
    final net = summary.netBalance;
    final stats = <(String, String, IconData, Color)>[
      (context.local.totalCredit, DepositFormatters.taka(summary.totalCredit), Icons.south_west_rounded, c.successColor),
      (context.local.totalDebit, DepositFormatters.taka(summary.totalDebit), Icons.north_east_rounded, c.errorColor),
      (context.local.netBalance, DepositFormatters.signedTaka(net), Icons.account_balance_wallet_rounded, net < 0 ? c.errorColor : c.primaryColor),
      (context.local.entries, '${summary.entries}', Icons.receipt_long_rounded, c.infoColor),
      (context.local.members, '${summary.activeMembers}/${summary.memberCount}', Icons.groups_rounded, c.secondaryColor),
      (context.local.avgPerMember, DepositFormatters.signedTaka(summary.averagePerMember), Icons.person_outline_rounded, c.warningColor),
    ];

    final mine = summary.mine;
    final myStats = mine == null
        ? const <(String, String, IconData, Color)>[]
        : [
            (context.local.credit, DepositFormatters.taka(mine.credit), Icons.south_west_rounded, c.successColor),
            (context.local.debit, DepositFormatters.taka(mine.debit), Icons.north_east_rounded, c.errorColor),
            (context.local.netBalance, DepositFormatters.signedTaka(mine.net), Icons.account_balance_wallet_rounded, mine.net < 0 ? c.errorColor : c.primaryColor),
            (context.local.entries, '${mine.entries}', Icons.receipt_long_rounded, c.infoColor),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (myStats.isNotEmpty) ...[
          SectionTitle(title: context.local.myDeposits, icon: Icons.account_circle_outlined),
          _StatGrid(stats: myStats),
          const SizedBox(height: Dimensions.paddingSizeLarge),
        ],
        SectionTitle(title: context.local.messOverview, icon: Icons.insights_rounded),
        _StatGrid(stats: stats),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        SectionTitle(title: context.local.memberBalances, icon: Icons.people_alt_rounded),
        _MemberBalanceList(balances: summary.memberBalances),
      ],
    );
  }
}

/// Width-adaptive grid of [StatCard]s.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});
  final List<(String, String, IconData, Color)> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisExtent: 168,
            crossAxisSpacing: Dimensions.paddingSizeDefault,
            mainAxisSpacing: Dimensions.paddingSizeDefault,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final (label, value, icon, accent) = stats[index];
            return AnimatedEntrance(delay: Duration(milliseconds: 50 * index), child: StatCard(label: label, value: value, icon: icon, accent: accent));
          },
        );
  }
}

/// Per-member credit / debit / net. Columns on wide screens, stacked on phones.
class _MemberBalanceList extends StatelessWidget {
  const _MemberBalanceList({required this.balances});
  final List<DepositMemberBalanceEntity> balances;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final radius = BorderRadius.circular(Dimensions.radiusExtraLarge);
    return Container(
      decoration: BoxDecoration(color: colors.backgroundColor, borderRadius: radius, border: Border.all(color: colors.borderColor)),
      child: balances.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Text(context.local.noMembers, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor)),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 560;
                return Column(
                  children: [
                    if (wide) _HeaderRow(),
                    for (var i = 0; i < balances.length; i++) ...[
                      if (i > 0 || wide) Divider(height: 1, color: colors.borderColor),
                      _BalanceRow(balance: balances[i], wide: wide),
                    ],
                  ],
                );
              },
            ),
    );
  }
}

const double _amountColumnWidth = 104;

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: context.customThemeColors.textSecondaryColor);
    Widget amount(String text) => SizedBox(width: _amountColumnWidth, child: Text(text, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: style));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      child: Row(
        children: [
          Expanded(child: Text(context.local.members, maxLines: 1, overflow: TextOverflow.ellipsis, style: style)),
          amount(context.local.credit),
          amount(context.local.debit),
          amount(context.local.net),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.balance, required this.wide});
  final DepositMemberBalanceEntity balance;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = context.customThemeColors;
    final netColor = balance.net < 0 ? c.errorColor : c.successColor;
    final nameStyle = AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: c.textPrimaryColor);
    final amountStyle = AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: c.textPrimaryColor);
    final netText = Text(DepositFormatters.signedTaka(balance.net), maxLines: 1, textAlign: TextAlign.end, style: amountStyle.copyWith(color: netColor));

    Widget amount(String text, Color color) => SizedBox(
      width: _amountColumnWidth,
      child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerEnd, child: Text(text, maxLines: 1, style: amountStyle.copyWith(color: color))),
    );

    final name = Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: c.primaryColor.withValues(alpha: 0.12),
          child: Text(balance.memberName.isEmpty ? '?' : balance.memberName.characters.first.toUpperCase(), style: AppTextStyles.sfProRoundedBold.copyWith(color: c.primaryColor)),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: Text(balance.memberName, maxLines: 1, overflow: TextOverflow.ellipsis, style: nameStyle)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: wide
          ? Row(
              children: [
                Expanded(child: name),
                amount(DepositFormatters.taka(balance.credit), c.successColor),
                amount(DepositFormatters.taka(balance.debit), c.errorColor),
                SizedBox(width: _amountColumnWidth, child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerEnd, child: netText)),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      name,
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 40),
                        child: Text(
                          '${context.local.credit} ${DepositFormatters.taka(balance.credit)} · ${context.local.debit} ${DepositFormatters.taka(balance.debit)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: c.textSecondaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: _amountColumnWidth), child: FittedBox(fit: BoxFit.scaleDown, child: netText)),
              ],
            ),
    );
  }
}
