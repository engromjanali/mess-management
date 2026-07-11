import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Scaffold(
      appBar: AppBar(leading: const HomeBackButton(), title: const Text('Privacy Policy')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
            child: ListView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              children: [
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  decoration: BoxDecoration(
                    color: colors.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                    border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.privacy_tip_outlined, color: colors.primaryColor, size: Dimensions.iconSizeExtraLarge),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Text(
                        '${AppConstants.appName} Privacy Policy',
                        style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      Text(
                        'Last updated: July 11, 2026',
                        style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Text(
                        'We respect your privacy and only collect the information needed to manage mess membership, meals, deposits, costs, funds, notices and account access.',
                        style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textSecondaryColor, height: 1.45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                const _PolicySection(
                  title: 'Information We Collect',
                  items: [
                    'Account details such as name, email, phone number and profile photo.',
                    'Mess, season and membership details, including role and membership status.',
                    'Meal, deposit, cost, fund, notice and opinion records created inside the app.',
                    'Basic device, language and authentication data required to keep your session secure.',
                  ],
                ),
                const _PolicySection(
                  title: 'How We Use Information',
                  items: [
                    'To show your current mess, season, balance, meal history and member status.',
                    'To allow managers to record meals, deposits, costs, funds, notices and membership actions.',
                    'To secure accounts, prevent unauthorized access and keep app data accurate.',
                    'To improve reliability, performance and the overall user experience.',
                  ],
                ),
                const _PolicySection(
                  title: 'Sharing and Access',
                  items: [
                    'Your mess data is visible only to authorized members or managers based on role.',
                    'We do not sell your personal information.',
                    'Data may be shared when required by law, safety needs or legitimate service operation.',
                  ],
                ),
                const _PolicySection(
                  title: 'Data Security',
                  items: [
                    'Authentication tokens are used to protect private API requests.',
                    'Access is role-based, so members and managers only see permitted actions.',
                    'No system is perfectly secure, but we use reasonable safeguards to protect your data.',
                  ],
                ),
                const _PolicySection(
                  title: 'Your Choices',
                  items: [
                    'You can update account and mess details where the app allows.',
                    'You can sign out any time from your profile.',
                    'Contact your mess manager or app support to request correction or removal of data.',
                  ],
                ),
                const _PolicySection(
                  title: 'Contact',
                  items: [
                    'For privacy questions, contact the app administrator or your mess manager.',
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: colors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          for (final item in items) Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(color: colors.primaryColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Text(
                    item,
                    style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textSecondaryColor, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
