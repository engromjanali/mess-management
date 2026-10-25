import 'package:mess_pilot/core/widgets/app_footer.dart';
import 'package:mess_pilot/features/home/presentation/widgets/main_page_body.dart';
import 'package:mess_pilot/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/widgets/home_back_button.dart';
import 'package:mess_pilot/features/settings/domain/entities/locale_entity.dart';
import 'package:mess_pilot/features/settings/domain/entities/theme_mode.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:mess_pilot/features/settings/presentation/bloc/theme/theme_event.dart';
import 'package:mess_pilot/features/settings/presentation/widgets/language_selection_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Settings screen with theme and language toggles
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = MainPageBody.showWebAppBar(context);
    return Scaffold(
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.settings)),
      body: MainPageBody(
        title: context.local.settings,
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
              _SettingsSection(
                title: context.local.language,
                icon: Icons.translate_rounded,
                child: BlocBuilder<LocalizationBloc, LocalizationState>(
                  builder: (context, state) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                      title: Text(context.local.selectLanguage, style: AppTextStyles.sfProRoundedMedium),
                      subtitle: Text(AppLocale.getLanguageName(state.locale)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        final bloc = context.read<LocalizationBloc>();
                        final locale = await showDialog<Locale>(
                          context: context,
                          builder: (_) => LanguageSelectionOverlay(currentLocale: state.locale),
                        );
                        if (locale != null && !bloc.isClosed) {
                          bloc.add(LocalizationEvent.changeLocale(locale.languageCode));
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: Dimensions.spaceLarge),
              _SettingsSection(
                title: context.local.theme,
                icon: Icons.palette_outlined,
                child: BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    final selected = state.when(light: (_) => AppThemeMode.light, dark: (_) => AppThemeMode.dark, system: (_) => AppThemeMode.system);
                    return Column(
                      children: AppThemeMode.values.map((mode) {
                        final label = switch (mode) {
                          AppThemeMode.light => context.local.uiLightMode,
                          AppThemeMode.dark => context.local.darkMode,
                          AppThemeMode.system => context.local.uiSystemDefault,
                        };
                        final icon = switch (mode) {
                          AppThemeMode.light => Icons.light_mode_outlined,
                          AppThemeMode.dark => Icons.dark_mode_outlined,
                          AppThemeMode.system => Icons.sunny_snowing,
                        };
                        final isSelected = selected == mode;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                          contentPadding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                          leading: Icon(icon),
                          title: Text(label, style: AppTextStyles.sfProRoundedMedium),
                          trailing: Icon(isSelected ? Icons.check_circle_rounded : Icons.circle_outlined),
                          onTap: isSelected ? null : () => context.read<ThemeBloc>().add(ThemeEvent.changeThemeMode(mode)),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (showWebAppBar) const AppFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: Dimensions.spaceDefault),
                Expanded(child: Text(title, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge))),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}
