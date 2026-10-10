import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:clean_boilerplate/features/splash/presentation/widgets/app_gate.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SplashBloc, SplashState>(
      listener: (context, state) {
        state.when(
          loading: () {},
          // Maintenance, forced / optional update, then home or login.
          loaded: (config) => openApp(context, config),
          error: (error) {
            context.showErrorSnackBar(error);
          },
        );
      },
      builder: (context, state) {
        return Scaffold(
          body: Center(
            child: state.maybeWhen(
              error: (message) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 48),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(message, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SplashBloc>().add(const SplashEvent.getConfig()),
                    child: Text(context.local.tryAgain),
                  ),
                ],
              ),
              orElse: () => const CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}
