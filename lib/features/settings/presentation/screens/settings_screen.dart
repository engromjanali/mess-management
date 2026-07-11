import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/settings/domain/entities/locale_entity.dart';
import 'package:clean_boilerplate/features/settings/domain/entities/theme_mode.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:clean_boilerplate/features/settings/presentation/widgets/language_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Settings screen with theme and language toggles
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const HomeBackButton(), title: Text(context.local.settings)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language Section
                Text(context.local.language, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                const SizedBox(height: Dimensions.spaceDefault),
                BlocBuilder<LocalizationBloc, LocalizationState>(
                  builder: (context, state) {
                    final currentLocale = state.locale;
                    final languageName = AppLocale.getLanguageName(currentLocale);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.local.selectLanguage, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
                      subtitle: Text(languageName, style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                      trailing: const Icon(Icons.language),
                      onTap: () => context.showCustomBottomSheet(child: LanguageBottomSheet(currentLocale: currentLocale)),
                    );
                  },
                ),
                const SizedBox(height: Dimensions.spaceLarge),
                const Divider(),
                const SizedBox(height: Dimensions.spaceLarge),
                // Theme Section
                Text(context.local.theme, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                const SizedBox(height: Dimensions.spaceDefault),
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    final isLight = state.value;

                    return SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.local.darkMode, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
                      subtitle: Text(isLight ? context.local.disabled : context.local.enabled, style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                      value: !isLight, // Invert because value represents light
                      onChanged: (isDark) {
                        // Toggle theme by passing the new mode
                        final newMode = isDark ? AppThemeMode.dark : AppThemeMode.light;
                        context.read<ThemeBloc>().add(ThemeEvent.changeThemeMode(newMode));
                      },
                    );
                  },
                ),
                const SizedBox(height: Dimensions.spaceLarge),
                const Divider(),
                const SizedBox(height: Dimensions.spaceLarge),
                Text('Privacy', style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                const SizedBox(height: Dimensions.spaceDefault),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Privacy Policy', style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
                  subtitle: Text('How your account and mess data are handled', style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                  trailing: const Icon(Icons.privacy_tip_outlined),
                  onTap: () => context.push(AppRoutes.privacyPolicy),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
