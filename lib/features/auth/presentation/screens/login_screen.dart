import 'package:mess_pilot/config/util/app_constants.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/features/auth/domain/entities/user_entity.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_event.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:mess_pilot/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mess_pilot/features/auth/presentation/widgets/login_form_widget.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
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
  String _dialCode = '+880';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final identifier = _emailController.text.trim();
    // Digits-only input is a phone number: drop the trunk zero and prepend the dial code.
    final isPhone = RegExp(r'^\d+$').hasMatch(identifier);
    final loginId = isPhone ? '$_dialCode${identifier.replaceFirst(RegExp(r'^0+'), '')}' : identifier;
    context.read<AuthBloc>().add(AuthEvent.loginRequested(email: loginId, password: _passwordController.text));
  }

  /// Fills the form with the demo credentials (dev convenience).
  void _fillDemoCredentials() {
    _emailController.text = 'test@gmail.com';
    _passwordController.text = '12345678';
    context.showInfoSnackBar(context.local.demoCredentialsFilled);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        state.maybeWhen(
          error: (message) => context.showErrorSnackBar(message),
          authenticated: (user) => _onAuthenticated(user),
          orElse: () {},
        );
      },
      builder: (context, state) {
        final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);

        return AuthScaffold(
          icon: Icons.restaurant_menu_rounded,
          logoShadow: true,
          title: context.local.welcomeBack,
          subtitle: context.local.uiSignInToContinueManagingYourMess,
          action: AppConstants.enableDemoLogin ? IconButton(tooltip: context.local.uiFillDemoCredentials, icon: const Icon(CupertinoIcons.pencil_circle), onPressed: _fillDemoCredentials) : null,
          footer: AuthFooterPrompt(promptText: context.local.uiNoAccountPrompt, actionText: context.local.uiSignUp, onTap: () => context.push(AppRoutes.register)),
          child: LoginFormWidget(
            formKey: _formKey,
            emailController: _emailController,
            passwordController: _passwordController,
            onLogin: _handleLogin,
            isLoading: isLoading,
            countryDialCode: _dialCode,
            onCountryChanged: (code) => _dialCode = code.dialCode ?? _dialCode,
            onForgotPassword: () => context.push(AppRoutes.forgotPassword),
          ),
        );
      },
    );
  }

  /// On success: greet the authenticated user and go home.
  void _onAuthenticated(UserEntity user) {
    context.showSuccessSnackBar(context.local.welcome(user.name));
    final destination = GoRouterState.of(context).uri.queryParameters['redirect'] ?? AppRoutes.home;
    context.go(AppRoutes.startupRoute(destination));
  }
}
