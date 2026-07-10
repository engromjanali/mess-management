import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({this.onAndroidInstall, this.onAppleInstall, super.key});

  final VoidCallback? onAndroidInstall;
  final VoidCallback? onAppleInstall;

  static const Color _backgroundColor = Color(0xFF343536);
  static const Color _textColor = Color(0xFFFFFFFF);
  static const Color _mutedTextColor = Color(0xFFB8B8B8);
  static const Color _dividerColor = Color(0xFF5A5A5A);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _backgroundColor,
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge32),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1000 ? 5 : 2;
                    final itemWidth = (constraints.maxWidth - (Dimensions.spaceLarge * (columns - 1))) / columns;

                    return Wrap(
                      spacing: Dimensions.spaceLarge,
                      runSpacing: Dimensions.spaceLarge,
                      children: [
                        SizedBox(width: itemWidth, child: const _FooterBrand()),
                        SizedBox(
                          width: itemWidth,
                          child: _FooterSection(
                            title: 'Explore',
                            links: [
                              _FooterLink(label: 'Home', route: AppRoutes.home),
                              _FooterLink(label: 'Meals', route: AppRoutes.meals),
                              _FooterLink(label: 'Deposits', route: AppRoutes.deposits),
                              _FooterLink(label: 'Anonymous opinions', route: AppRoutes.opinions),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _FooterSection(
                            title: 'Management',
                            links: [
                              _FooterLink(label: 'Fund', route: AppRoutes.funds),
                              _FooterLink(label: 'Costs', route: AppRoutes.costs),
                              _FooterLink(label: 'Notices', route: AppRoutes.notices),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: _FooterSection(
                            title: 'Account',
                            links: [
                              _FooterLink(label: 'Profile', route: AppRoutes.profile),
                              _FooterLink(label: 'Settings', route: AppRoutes.settings),
                            ],
                          ),
                        ),
                        SizedBox(width: itemWidth, child: _AppInstallSection(onAndroidInstall: onAndroidInstall, onAppleInstall: onAppleInstall)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _dividerColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
            child: Text(
              '© Copyright ${DateTime.now().year} Mess Manager. All rights reserved.',
              textAlign: TextAlign.center,
              style: AppTextStyles.sfProRoundedRegular.copyWith(color: _mutedTextColor, fontSize: Dimensions.fontSizeSmall),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppFooter._textColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              child: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF35C57F)),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Text('Mess Manager', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedBold.copyWith(color: AppFooter._textColor, fontSize: Dimensions.fontSizeExtraLarge)),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        Text(
          'Simple, transparent mess management for every member.',
          style: AppTextStyles.sfProRoundedRegular.copyWith(color: AppFooter._mutedTextColor, fontSize: Dimensions.fontSizeDefault, height: 1.5),
        ),
      ],
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection({required this.title, required this.links});

  final String title;
  final List<_FooterLink> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedBold.copyWith(color: AppFooter._textColor, fontSize: Dimensions.fontSizeDefault)),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        for (final link in links)
          TextButton(
            onPressed: () => context.go(link.route),
            style: TextButton.styleFrom(foregroundColor: AppFooter._mutedTextColor, padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text(link.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}

class _FooterLink {
  const _FooterLink({required this.label, required this.route});

  final String label;
  final String route;
}

class _AppInstallSection extends StatelessWidget {
  const _AppInstallSection({required this.onAndroidInstall, required this.onAppleInstall});

  final VoidCallback? onAndroidInstall;
  final VoidCallback? onAppleInstall;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Get the app', maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedBold.copyWith(color: AppFooter._textColor, fontSize: Dimensions.fontSizeDefault)),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        _StoreButton(icon: Icons.android_rounded, caption: 'GET IT ON', title: 'Google Play', onTap: onAndroidInstall ?? () => _showComingSoon(context, 'Android')),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        _StoreButton(icon: Icons.apple, caption: 'Download on the', title: 'App Store', onTap: onAppleInstall ?? () => _showComingSoon(context, 'iOS')),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String platform) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$platform app is coming soon')));
  }
}

class _StoreButton extends StatelessWidget {
  const _StoreButton({required this.icon, required this.caption, required this.title, required this.onTap});

  final IconData icon;
  final String caption;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(Dimensions.radiusDefault);
    return Material(
      color: const Color(0xFF17181D),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          constraints: const BoxConstraints(minWidth: 160),
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: AppFooter._dividerColor)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppFooter._textColor, size: Dimensions.iconSizeLarge),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(color: AppFooter._textColor, fontSize: Dimensions.fontSizeExtraSmall)),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: AppFooter._textColor, fontSize: Dimensions.fontSizeDefault)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
