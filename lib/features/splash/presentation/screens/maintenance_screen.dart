import 'package:mess_pilot/core/widgets/app_state_view.dart';
import 'package:mess_pilot/core/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:mess_pilot/features/splash/presentation/widgets/app_gate.dart';

/// Shown while the admin has maintenance mode on. "Try again" reloads the
/// config and opens the app once maintenance is over.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: AppStateView(
              title: context.local.maintenanceTitle,
              message: config != null && config.maintenanceMessage.isNotEmpty ? config.maintenanceMessage : context.local.stateServiceTitle,
              icon: Icons.construction_rounded,
              onAction: loading ? null : () => context.read<SplashBloc>().add(const SplashEvent.getConfig()),
              actionLabel: context.local.tryAgain,
              secondaryAction: Column(mainAxisSize: MainAxisSize.min, children: [
                if (loading) const AppLoader(size: 48),
                if (until != null) Text(context.local.maintenanceUntil(DateFormat.yMMMd('en_US').add_jm().format(until)), textAlign: TextAlign.center),
              ]),
            ),
          ),
        );
      },
    );
  }
}
