import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:clean_boilerplate/features/splash/presentation/widgets/app_gate.dart';

/// Shown while the admin has maintenance mode on. "Try again" reloads the
/// config and opens the app once maintenance is over.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return BlocConsumer<SplashBloc, SplashState>(
      listener: (context, state) => state.maybeWhen<void>(
        loaded: (config) {
          if (!config.maintenanceMode) openApp(context, config);
        },
        error: (message) => context.showErrorSnackBar(message),
        orElse: () {},
      ),
      builder: (context, state) {
        final config = state.maybeWhen(loaded: (config) => config, orElse: () => null);
        final loading = state.maybeWhen(loading: () => true, orElse: () => false);
        final until = config?.maintenanceUntil;
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: colors.warningColor.withValues(alpha: 0.12),
                        child: Icon(Icons.construction_rounded, size: 44, color: colors.warningColor),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      Text(context.local.maintenanceTitle, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      if (config != null && config.maintenanceMessage.isNotEmpty)
                        Text(config.maintenanceMessage, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, height: 1.4)),
                      if (until != null) ...[
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        Text(
                          context.local.maintenanceUntil(DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).add_jm().format(until)),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: colors.textPrimaryColor),
                        ),
                      ],
                      const SizedBox(height: Dimensions.paddingSizeExtraLarge24),
                      FilledButton.icon(
                        onPressed: loading ? null : () => context.read<SplashBloc>().add(const SplashEvent.getConfig()),
                        icon: loading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded),
                        label: Text(context.local.tryAgain),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
