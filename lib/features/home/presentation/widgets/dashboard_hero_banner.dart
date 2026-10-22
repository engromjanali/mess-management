import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';

/// Gradient summary banner for the tablet & desktop dashboards.
///
/// Mirrors the phone hero as a self-contained rounded card.
class DashboardHeroBanner extends StatelessWidget {
  const DashboardHeroBanner({required this.userName, required this.currentSeasonName, required this.totalBalance, super.key});

  final String userName;
  final String currentSeasonName;
  final double totalBalance;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge32),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusExtra2Large), bottomLeft: Radius.circular(Dimensions.radiusExtra2Large), bottomRight: Radius.circular(Dimensions.radiusExtra2Large)),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colors.primaryDarkColor, colors.primaryColor, colors.primaryLightColor]),
        boxShadow: [BoxShadow(color: colors.primaryColor.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only( bottomLeft: Radius.circular(Dimensions.radiusExtra2Large), bottomRight: Radius.circular(Dimensions.radiusExtra2Large)),
        child: Stack(
          children: [
            Positioned(top: -110, right: -55, child: _DecorativeCircle(size: 270, color: Colors.white.withValues(alpha: 0.08))),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 640;
                if (wide) {
                  return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _balanceBlock(context)),
                if (currentSeasonName.isNotEmpty) _SeasonChip(seasonName: currentSeasonName),
              ],
            );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _balanceBlock(context),
                    if (currentSeasonName.isNotEmpty) ...[
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      _SeasonChip(seasonName: currentSeasonName),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceBlock(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.local.uiWelcomeBack,
            style: AppTextStyles.sfProRoundedMedium.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: Dimensions.fontSizeDefault),
          ),
          Text(
            userName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sfProRoundedBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraOverLarge),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),
          Text(
            context.local.uiTotalBalance,
            style: AppTextStyles.sfProRoundedMedium.copyWith(color: Colors.white.withValues(alpha: 0.78), fontSize: Dimensions.fontSizeSmall),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text.rich(TextSpan(style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700, height: 1.15), children: [TextSpan(text: '৳'), TextSpan(text: DashboardFormatters.number(totalBalance), style: AppTextStyles.sfProRoundedBold)])),
          ),
        ],
      ),
    );
  }
}

class _SeasonChip extends StatelessWidget {
  const _SeasonChip({required this.seasonName});

  final String seasonName;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)), child: const Icon(Icons.event_note_rounded, size: Dimensions.iconSizeSmall, color: Colors.white)),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.local.currentSeasonLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedMedium.copyWith(color: Colors.white.withValues(alpha: 0.70), fontSize: Dimensions.fontSizeExtraSmall)),
            Text(seasonName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault)),
          ])),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(child: Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle)));
}
