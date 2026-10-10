import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:clean_boilerplate/features/splash/presentation/widgets/app_gate.dart';

/// Shown when this app version is older than the admin's minimum version:
/// the app can't be used until it's updated.
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final config = context.watch<SplashBloc>().state.maybeWhen(loaded: (config) => config, orElse: () => null);
    final url = config == null ? null : storeUrl(config);
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
                    backgroundColor: colors.primaryColor.withValues(alpha: 0.12),
                    child: Icon(Icons.system_update_rounded, size: 44, color: colors.primaryColor),
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  Text(context.local.updateRequiredTitle, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  FutureBuilder<String>(
                    future: currentAppVersion(),
                    builder: (context, snapshot) {
                      final message = config != null && config.updateMessage.isNotEmpty
                          ? config.updateMessage
                          : context.local.updateRequiredMessage(snapshot.data ?? '', config?.latestVersion ?? '');
                      return Text(message, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, height: 1.4));
                    },
                  ),
                  if (url != null) ...[
                    const SizedBox(height: Dimensions.paddingSizeExtraLarge24),
                    FilledButton.icon(onPressed: () => openStore(url), icon: const Icon(Icons.download_rounded), label: Text(context.local.updateNow)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
