import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mess_pilot/core/widgets/app_loader.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';

/// Builds [builder] only after the auth state has resolved (cached user or the
/// `/me` refresh). On a browser refresh the role arrives slightly after the
/// first frame; without this gate role-dependent screens load with the default
/// role and then reload again when the real role arrives.
class AuthReadyBuilder extends StatelessWidget {
  const AuthReadyBuilder({required this.builder, super.key});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => state.maybeWhen(
        authenticated: (_) => builder(context),
        unauthenticated: () => builder(context),
        orElse: () => const Scaffold(body: Center(child: AppLoader())),
      ),
    );
  }
}
