import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/features/home/presentation/widgets/dashboard_formatters.dart';

/// Gradient summary banner for the tablet & desktop dashboards.
///
/// Mirrors the phone hero as a self-contained rounded card.
class DashboardHeroBanner extends StatelessWidget {
  const DashboardHeroBanner({required this.userName, required this.totalBalance, super.key});

  final String userName;
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
            _balanceBlock(context),
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

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(child: Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle)));
}
