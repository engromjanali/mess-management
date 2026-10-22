import 'package:clean_boilerplate/core/widgets/app_state_view.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/widgets/app_loader.dart';
import 'package:clean_boilerplate/features/splash/domain/entities/config_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:clean_boilerplate/features/splash/presentation/widgets/app_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.destination, super.key});

  final String destination;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isOpening = false;

  Future<void> _openApp(ConfigEntity config) async {
    if (_isOpening) return;
    _isOpening = true;
    if (!mounted) return;
    await openApp(context, config, destination: widget.destination);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return BlocConsumer<SplashBloc, SplashState>(
      listener: (context, state) {
        state.when(
          loading: () {},
          // Maintenance, forced / optional update, then home or login.
          loaded: _openApp,
          error: (error) {
            context.showErrorSnackBar(error);
          },
        );
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.backgroundColor,
          body: Center(
            child: state.maybeWhen(
              error: (message) => AppErrorState(error: message, onRetry: () => context.read<SplashBloc>().add(const SplashEvent.getConfig())),
              orElse: () => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLoader(size: 132),
                  const SizedBox(height: 24),
                  Text('Mess Pilot', style: AppTextStyles.sfProRoundedBold.copyWith(color: colors.textPrimaryColor, fontSize: 28)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
