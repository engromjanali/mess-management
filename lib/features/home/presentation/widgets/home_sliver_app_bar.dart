import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';

class HomeSliverAppBar extends StatelessWidget {
  const HomeSliverAppBar({required this.userName, required this.currentSeasonName, required this.totalBalance, required this.expandedHeight, this.photoUrl, super.key});

  final String userName;
  final String? photoUrl;
  final String currentSeasonName;
  final double totalBalance;
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
        IconButton(tooltip: 'Notifications', onPressed: () => context.push(AppRoutes.notices), icon: const Icon(Icons.notifications_outlined)),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapsedHeight = topInset + kToolbarHeight;
          final collapseProgress = ((maximumHeight - constraints.maxHeight) / (maximumHeight - collapsedHeight)).clamp(0.0, 1.0);
          final expandedOpacity = (1 - ((collapseProgress - 0.12) / 0.70)).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              _HeaderBackground(userName: userName, currentSeasonName: currentSeasonName, totalBalance: totalBalance, expandedHeight: maximumHeight, contentOpacity: expandedOpacity),
              Positioned(
                top: topInset,
                left: Dimensions.paddingSizeLarge,
                right: Dimensions.paddingSizeLarge + kToolbarHeight,
                height: kToolbarHeight,
                child: IgnorePointer(
                  ignoring: collapseProgress < 0.55,
                  child: Opacity(opacity: ((collapseProgress - 0.55) / 0.55).clamp(0.0, 1.0), child: _CollapsedIdentity(userName: userName, photoUrl: photoUrl)),
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
  const _HeaderBackground({required this.userName, required this.currentSeasonName, required this.totalBalance, required this.expandedHeight, required this.contentOpacity});

  final String userName;
  final String currentSeasonName;
  final double totalBalance;
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
        child: Stack(
          children: [
            Positioned(top: -70, right: -45, child: _DecorativeCircle(size: 190, color: Colors.white.withValues(alpha: 0.08))),
            Positioned(bottom: -85, left: -70, child: _DecorativeCircle(size: 180, color: colors.secondaryColor.withValues(alpha: 0.20))),
            OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: MediaQuery.sizeOf(context).width,
              maxWidth: MediaQuery.sizeOf(context).width,
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
            Text(
              'Total balance',
              style: AppTextStyles.sfProRoundedMedium.copyWith(color: Colors.white.withValues(alpha: 0.78), fontSize: Dimensions.fontSizeSmall),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(DashboardFormatters.taka(totalBalance), style: AppTextStyles.sfProRoundedBold.copyWith(color: Colors.white, fontSize: 32)),
            ),
            if (currentSeasonName.isNotEmpty)
              _SeasonChip(seasonName: currentSeasonName),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapsedIdentity extends StatelessWidget {
  const _CollapsedIdentity({required this.userName, this.photoUrl});

  final String userName;
  final String? photoUrl;

  String get _initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = photoUrl?.trim() ?? '';
    final fallback = Text(_initials, style: AppTextStyles.sfProRoundedBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeDefault));
    final imageSize = (38 * MediaQuery.devicePixelRatioOf(context)).round();
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.35))),
          alignment: Alignment.center,
          child: imageUrl.isEmpty ? fallback : ClipOval(child: Image.network(imageUrl, width: 38, height: 38, fit: BoxFit.cover, cacheWidth: imageSize, cacheHeight: imageSize, errorBuilder: (_, _, _) => Center(child: fallback))),
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
          Container(width: 30, height: 30, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)), child: const Icon(Icons.event_note_rounded, size: Dimensions.iconSizeSmall, color: Colors.white)),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.local.currentSeasonLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedMedium.copyWith(color: Colors.white.withValues(alpha: 0.70), fontSize: Dimensions.fontSizeExtraSmall)),
            Text(seasonName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
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
