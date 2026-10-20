import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/widgets/app_logo.dart';
import 'package:clean_boilerplate/features/splash/domain/entities/config_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:clean_boilerplate/features/splash/presentation/widgets/app_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _splashDuration = Duration(seconds: 3);
  late final DateTime _startedAt;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
  }

  Future<void> _openApp(ConfigEntity config) async {
    if (_isOpening) return;
    _isOpening = true;
    final remaining = _splashDuration - DateTime.now().difference(_startedAt);
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    if (!mounted) return;
    await openApp(context, config);
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
              orElse: () => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 120, shape: BoxShape.circle),
                  const SizedBox(height: 24),
                  Text('Mess Manager', style: AppTextStyles.sfProRoundedBold.copyWith(color: colors.textPrimaryColor, fontSize: 28)),
                  const SizedBox(height: 24),
                  SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: colors.primaryColor)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
