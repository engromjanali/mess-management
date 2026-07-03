import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/helpers/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SplashBloc, SplashState>(
      listener: (context, state) {
        state.when(
          loading: () {},
          loaded: (config) {
            final isLoggedIn = AuthHelper.isLogin();
            context.replace(isLoggedIn ? AppRoutes.getHomeRoute() : AppRoutes.getLoginRoute());
          },
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
                    child: const Text('Retry'),
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
