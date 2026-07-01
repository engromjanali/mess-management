import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/features/auth/domain/entities/user_entity.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:clean_boilerplate/features/auth/presentation/widgets/register_form_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Modern sign-up screen — gradient hero + floating form sheet.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _dialCode = '+880';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final phone = _phoneController.text.trim();
    context.read<AuthBloc>().add(
      AuthEvent.registerRequested(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: phone.isEmpty ? null : '$_dialCode$phone',
      ),
    );
  }

  void _goToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.getLoginRoute());
    }
  }

  /// On success the backend returns tokens, so we sign the user straight in.
  void _onAuthenticated(UserEntity user) {
    context.read<RoleCubit>().setRole(user.isManager ? UserRole.admin : UserRole.user);
    context.showSuccessSnackBar(context.local.welcome(user.name));
    context.go(AppRoutes.home);
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
          icon: Icons.person_add_alt_1_rounded,
          title: 'Create account',
          subtitle: 'Join and start managing your mess',
          footer: AuthFooterPrompt(promptText: 'Already have an account? ', actionText: context.local.login, onTap: _goToLogin),
          child: RegisterFormWidget(
            formKey: _formKey,
            nameController: _nameController,
            emailController: _emailController,
            phoneController: _phoneController,
            passwordController: _passwordController,
            countryDialCode: _dialCode,
            onCountryChanged: (code) => _dialCode = code.dialCode ?? _dialCode,
            onRegister: _handleRegister,
            isLoading: isLoading,
          ),
        );
      },
    );
  }
}
