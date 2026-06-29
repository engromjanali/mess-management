import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:clean_boilerplate/features/auth/presentation/widgets/login_form_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Modern sign-in screen — gradient hero + floating form sheet.
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
    if (!_formKey.currentState!.validate()) return;
    context.go(AppRoutes.home);
  }

  /// Fills the form with the demo credentials (dev convenience).
  void _fillDemoCredentials() {
    _emailController.text = 'test@gmail.com';
    _passwordController.text = '12345678';
    context.showInfoSnackBar('Demo credentials filled');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        state.maybeWhen(error: (message) => context.showErrorSnackBar(message), authenticated: (user) => context.showSuccessSnackBar(context.local.welcome(user.name)), orElse: () {});
      },
      builder: (context, state) {
        final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);

        return AuthScaffold(
          icon: Icons.restaurant_menu_rounded,
          title: context.local.welcomeBack,
          subtitle: 'Sign in to continue managing your mess',
          action: IconButton(tooltip: 'Fill demo credentials', icon: const Icon(Icons.info_outline_rounded), onPressed: _fillDemoCredentials),
          footer: AuthFooterPrompt(promptText: "Don't have an account? ", actionText: 'Sign up', onTap: () => context.push(AppRoutes.register)),
          child: LoginFormWidget(
            formKey: _formKey,
            emailController: _emailController,
            passwordController: _passwordController,
            onLogin: _handleLogin,
            isLoading: isLoading,
            onForgotPassword: () => context.showInfoSnackBar('Password reset is coming soon.'),
          ),
        );
      },
    );
  }
}
