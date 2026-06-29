import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:clean_boilerplate/features/auth/presentation/widgets/register_form_widget.dart';
import 'package:flutter/material.dart';
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
    // Per redesign spec the auth backend isn't wired yet — validate the form
    // and return to sign-in. Hook the AuthBloc registration flow in here when
    // real sign-up is implemented.
    if (!_formKey.currentState!.validate()) return;
    context.showSuccessSnackBar('Account created. Please sign in.');
    _goToLogin();
  }

  void _goToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.getLoginRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
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
      ),
    );
  }
}
