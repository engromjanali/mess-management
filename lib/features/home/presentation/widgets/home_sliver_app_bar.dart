import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/route/app_router.dart';
import '../../../../config/util/dimensions.dart';
import '../../../../config/util/styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../settings/domain/entities/theme_mode.dart';
import '../../../settings/presentation/bloc/theme/theme_bloc.dart';
import '../../../settings/presentation/bloc/theme/theme_event.dart';
import 'dashboard_formatters.dart';

/// Collapsing hero header for the dashboard.
///
/// Pinned + stretchable [SliverAppBar] showing a green gradient, the welcome
/// greeting, the headline total balance and quick "meal / fund" chips. Hosts
/// the theme toggle and settings actions.
class HomeSliverAppBar extends StatelessWidget {
  const HomeSliverAppBar({
    required this.userName,
    required this.totalBalance,
    required this.mealBalance,
    required this.fundBalance,
    required this.expandedHeight,
    super.key,
  });

  final String userName;
  final double totalBalance;
  final double mealBalance;
  final double fundBalance;
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: expandedHeight,
      backgroundColor: colors.primaryDarkColor,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Dashboard',
        style: AppTextStyles.sfProRoundedBold.copyWith(color: Colors.white),
      ),
      actions: [
        IconButton(
          tooltip: 'Toggle theme',
          icon: Icon(
            context.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
          ),
          onPressed: () {
            context.read<ThemeBloc>().add(
                  ThemeEvent.changeThemeMode(
                    context.isDarkMode
                        ? AppThemeMode.light
                        : AppThemeMode.dark,
                  ),
                );
          },
        ),
        IconButton(
          tooltip: context.local.settings,
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => context.push(AppRoutes.settings),
        ),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: _HeaderBackground(
          userName: userName,
          totalBalance: totalBalance,
          mealBalance: mealBalance,
          fundBalance: fundBalance,
        ),
      ),
    );
  }
}

class _HeaderBackground extends StatelessWidget {
  const _HeaderBackground({
    required this.userName,
    required this.totalBalance,
    required this.mealBalance,
    required this.fundBalance,
  });

  final String userName;
  final double totalBalance;
  final double mealBalance;
  final double fundBalance;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryDarkColor,
            colors.primaryColor,
            colors.primaryLightColor,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeLarge,
            Dimensions.paddingSizeExtraLarge24,
            Dimensions.paddingSizeLarge,
            Dimensions.paddingSizeLarge,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: AppTextStyles.sfProRoundedMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
              Text(
                userName,
                style: AppTextStyles.sfProRoundedBold.copyWith(
                  color: Colors.white,
                  fontSize: Dimensions.fontSizeExtraOverLarge,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Text(
                'Total balance',
                style: AppTextStyles.sfProRoundedMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  DashboardFormatters.taka(totalBalance),
                  style: AppTextStyles.sfProRoundedBold.copyWith(
                    color: Colors.white,
                    fontSize: 34,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Wrap(
                spacing: Dimensions.paddingSizeSmall,
                runSpacing: Dimensions.paddingSizeSmall,
                children: [
                  _HeaderChip(
                    icon: Icons.restaurant_rounded,
                    label: 'Meal',
                    value: DashboardFormatters.taka(mealBalance),
                  ),
                  _HeaderChip(
                    icon: Icons.savings_rounded,
                    label: 'Fund',
                    value: DashboardFormatters.taka(fundBalance),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
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
            style: AppTextStyles.sfProRoundedSemiBold.copyWith(
              color: Colors.white,
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }
}
