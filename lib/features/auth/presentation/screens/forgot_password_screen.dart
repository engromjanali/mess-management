import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/core/widgets/common_labeled_input_item_widget.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/password_reset_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/password_reset_event.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/password_reset_state.dart';
import 'package:mess_pilot/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Two-step forgot-password screen: request an OTP by email, then submit the
/// OTP with a new password.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PasswordResetBloc>(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  static const Color _prefixIconColor = Color(0xFF1FA463);

  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _requestOtp() {
    if (!_emailFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<PasswordResetBloc>().add(PasswordResetEvent.otpRequested(email: _emailController.text.trim()));
  }

  void _submitReset(String email) {
    if (!_resetFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<PasswordResetBloc>().add(
      PasswordResetEvent.passwordSubmitted(email: email, otp: _otpController.text.trim(), password: _passwordController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PasswordResetBloc, PasswordResetState>(
      listener: (context, state) {
        state.maybeWhen(
          otpSent: (email) => context.showInfoSnackBar(context.local.resetCodeSent(email)),
          success: () {
            context.showSuccessSnackBar(context.local.passwordResetComplete);
            _goBack();
          },
          error: (message, _) => context.showErrorSnackBar(message),
          orElse: () {},
        );
      },
      builder: (context, state) {
        final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);
        final email = state.maybeWhen(
          otpSent: (email) => email,
          error: (_, email) => email,
          orElse: () => null,
        );
        final isResetStep = email != null;

        return AuthScaffold(
          icon: Icons.lock_reset_rounded,
          logoShadow: true,
          title: context.local.uiResetPassword,
          subtitle: isResetStep
              ? context.local.uiResetInstructions(email)
              : context.local.uiEnterYourEmailAndWeLlSendYouAResetCode,
          footer: AuthFooterPrompt(promptText: context.local.uiRememberedPrompt, actionText: context.local.login, onTap: _goBack),
          child: isResetStep
              ? _buildResetForm(context, email, isLoading)
              : _buildEmailForm(context, isLoading),
        );
      },
    );
  }

  Widget _buildEmailForm(BuildContext context, bool isLoading) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CommonLabeledInputItemWidget(
            label: context.local.email,
            hintText: context.local.email,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _requestOtp(),
            prefixIcon: const Icon(Icons.alternate_email_rounded),
            prefixIconColor: _prefixIconColor,
            borderRadius: Dimensions.radiusLarge,
            isRequired: true,
          ),
          const SizedBox(height: Dimensions.spaceLarge),
          _primaryButton(context, label: context.local.uiSendResetCode, isLoading: isLoading, onPressed: _requestOtp),
        ],
      ),
    );
  }

  Widget _buildResetForm(BuildContext context, String email, bool isLoading) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CommonLabeledInputItemWidget(
            label: context.local.uiResetCode,
            hintText: context.local.ui6DigitCode,
            controller: _otpController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            prefixIcon: const Icon(Icons.pin_outlined),
            prefixIconColor: _prefixIconColor,
            borderRadius: Dimensions.radiusLarge,
            isRequired: true,
          ),
          const SizedBox(height: Dimensions.spaceDefault),
          CommonLabeledInputItemWidget(
            label: context.local.uiNewPassword,
            hintText: context.local.password,
            controller: _passwordController,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitReset(email),
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            prefixIconColor: _prefixIconColor,
            borderRadius: Dimensions.radiusLarge,
            isRequired: true,
            passwordLength: 6,
          ),
          const SizedBox(height: Dimensions.spaceLarge),
          _primaryButton(context, label: context.local.uiResetPassword, isLoading: isLoading, onPressed: () => _submitReset(email)),
          TextButton(
            onPressed: isLoading ? null : () => context.read<PasswordResetBloc>().add(const PasswordResetEvent.restarted()),
            child: Text(
              context.local.uiUseADifferentEmail,
              style: AppTextStyles.sfProRoundedMedium.copyWith(color: context.primaryColor, fontSize: Dimensions.fontSizeDefault),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(BuildContext context, {required String label, required bool isLoading, required VoidCallback onPressed}) {
    return SizedBox(
      height: Dimensions.buttonHeightLarge,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge))),
        child: isLoading
            ? const SizedBox(
                height: Dimensions.iconSizeDefault,
                width: Dimensions.iconSizeDefault,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : Text(label, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.getLoginRoute());
    }
  }
}
