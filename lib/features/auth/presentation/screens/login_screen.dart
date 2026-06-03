import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/auth/presentation/widgets/login_form_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Login screen with Freezed BLoC integration
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // Per redesign spec: tapping login goes straight to the home dashboard,
    // no authentication required yet. Wire the AuthBloc flow back in here when
    // real login is implemented.
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.local.login),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: context.local.settings,
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // Using Freezed pattern matching with maybeWhen for cleaner code
          state.maybeWhen(
            error: (message) {
              context.showErrorSnackBar(message);
            },
            authenticated: (user) {
              context.showSuccessSnackBar(context.local.welcome(user.name));
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          // Using Freezed pattern matching for state handling
          return state.maybeWhen(
            loading: () => const Center(child: CircularProgressIndicator()),
            orElse: () => LoginFormWidget(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              onLogin: _handleLogin,
            ),
          );
        },
      ),
    );
  }
}

