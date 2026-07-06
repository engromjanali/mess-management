import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';

class HomeSliverAppBar extends StatelessWidget {
  const HomeSliverAppBar({required this.userName, required this.totalBalance, required this.mealBalance, required this.depositBalance, required this.expandedHeight, super.key});

  final String userName;
  final double totalBalance;
  final double mealBalance;
  final double depositBalance;
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final topInset = MediaQuery.paddingOf(context).top;
    final maximumHeight = expandedHeight + topInset;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: expandedHeight,
      backgroundColor: colors.primaryDarkColor,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const Border(),
      actions: [
        IconButton(tooltip: 'Notifications', onPressed: () => context.go(AppRoutes.notices), icon: const Icon(Icons.notifications_outlined)),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapsedHeight = topInset + kToolbarHeight;
          final collapseProgress = ((maximumHeight - constraints.maxHeight) / (maximumHeight - collapsedHeight)).clamp(0.0, 1.0);
          final expandedOpacity = (1 - ((collapseProgress - 0.12) / 0.70)).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              _HeaderBackground(userName: userName, totalBalance: totalBalance, mealBalance: mealBalance, depositBalance: depositBalance, expandedHeight: maximumHeight, contentOpacity: expandedOpacity),
              Positioned(
                top: topInset,
                left: Dimensions.paddingSizeLarge,
                right: Dimensions.paddingSizeLarge + kToolbarHeight,
                height: kToolbarHeight,
                child: IgnorePointer(
                  ignoring: collapseProgress < 0.55,
                  child: Opacity(opacity: ((collapseProgress - 0.55) / 0.55).clamp(0.0, 1.0), child: _CollapsedIdentity(userName: userName)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground({required this.userName, required this.totalBalance, required this.mealBalance, required this.depositBalance, required this.expandedHeight, required this.contentOpacity});

  final String userName;
  final double totalBalance;
  final double mealBalance;
  final double depositBalance;
  final double expandedHeight;
  final double contentOpacity;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colors.primaryDarkColor, colors.primaryColor, colors.primaryLightColor]),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: expandedHeight,
          maxHeight: expandedHeight,
          child: Opacity(
            opacity: contentOpacity,
            child: Padding(
              padding: EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, MediaQuery.paddingOf(context).top + Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge + kToolbarHeight, 0),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Welcome back,',
                style: AppTextStyles.sfProRoundedMedium.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: Dimensions.fontSizeDefault),
              ),
              Text(
                userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sfProRoundedBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraOverLarge),
              ),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total balance',
                  style: AppTextStyles.sfProRoundedMedium.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: Dimensions.fontSizeSmall),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(DashboardFormatters.taka(totalBalance), style: AppTextStyles.sfProRoundedBold.copyWith(color: Colors.white, fontSize: 34)),
                ),
              ],
            ),
            Wrap(
              spacing: Dimensions.paddingSizeSmall,
              runSpacing: Dimensions.paddingSizeSmall,
              children: [
                _HeaderChip(icon: Icons.restaurant_rounded, label: 'Meal', value: DashboardFormatters.taka(mealBalance)),
                _HeaderChip(icon: Icons.payments_rounded, label: 'Deposit', value: DashboardFormatters.taka(depositBalance)),
              ],
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ]),
            )
          ),
        ),
      ),
    );
  }
}

class _CollapsedIdentity extends StatelessWidget {
  const _CollapsedIdentity({required this.userName});

  final String userName;

  String get _initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.35))),
          alignment: Alignment.center,
          child: Text(_initials, style: AppTextStyles.sfProRoundedBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault)),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back', style: AppTextStyles.sfProRoundedMedium.copyWith(color: Colors.white.withValues(alpha: 0.75), fontSize: Dimensions.fontSizeExtraSmall)),
              Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge)),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Dimensions.iconSizeSmall, color: Colors.white),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text(
            '$label · $value',
            style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
          ),
        ],
      ),
    );
  }
}
