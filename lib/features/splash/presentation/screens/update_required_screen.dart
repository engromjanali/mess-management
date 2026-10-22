import 'package:clean_boilerplate/core/widgets/app_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:clean_boilerplate/features/splash/presentation/widgets/app_gate.dart';

/// Shown when this app version is older than the admin's minimum version:
/// the app can't be used until it's updated.
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<SplashBloc>().state.maybeWhen(loaded: (config) => config, orElse: () => null);
    final url = config == null ? null : storeUrl(config);
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<String>(
          future: currentAppVersion(),
          builder: (context, snapshot) => AppStateView(
            title: context.local.updateRequiredTitle,
            message: config != null && config.updateMessage.isNotEmpty ? config.updateMessage : context.local.updateRequiredMessage(snapshot.data ?? '', config?.latestVersion ?? ''),
            icon: Icons.system_update_rounded,
            onAction: url == null ? null : () => openStore(url),
            actionLabel: context.local.updateNow,
            actionIcon: Icons.download_rounded,
          ),
        ),
      ),
    );
  }
}
