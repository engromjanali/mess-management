import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
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
            context.replace(AppRoutes.getLoginRoute());
          },
          error: (error) {
            context.showErrorSnackBar(error);
          },
        );
      },
      builder: (context, state) {
        return Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
