import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/widgets/common_labeled_input_item_widget.dart';
import 'package:flutter/material.dart';

/// Sign-in form: email + password, with a "forgot password" affordance and a
/// full-width primary action. Carried over from the legacy sign-in screen.
class LoginFormWidget extends StatefulWidget {
  const LoginFormWidget({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
    this.onForgotPassword,
    this.isLoading = false,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final VoidCallback? onForgotPassword;
  final bool isLoading;

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  /// Brand green kept identical in light and dark mode so the field prefix
  /// icons stay visible against both backgrounds.
  static const Color _prefixIconColor = Color(0xFF1FA463);

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!widget.isLoading) widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email
          CommonLabeledInputItemWidget(
            label: context.local.email,
            hintText: context.local.email,
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            focusNode: _emailFocus,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            prefixIcon: const Icon(Icons.alternate_email_rounded),
            prefixIconColor: _prefixIconColor,
            borderRadius: Dimensions.radiusLarge,
            isRequired: true,
          ),
          const SizedBox(height: Dimensions.spaceDefault),

          // Password
          CommonLabeledInputItemWidget(
            label: context.local.password,
            hintText: context.local.password,
            controller: widget.passwordController,
            keyboardType: TextInputType.visiblePassword,
            focusNode: _passwordFocus,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            prefixIconColor: _prefixIconColor,
            borderRadius: Dimensions.radiusLarge,
            isRequired: true,
            passwordLength: 6,
          ),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              child: Text(
                'Forgot password?',
                style: AppTextStyles.sfProRoundedMedium.copyWith(
                  color: context.primaryColor,
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Primary action
          SizedBox(
            height: Dimensions.buttonHeightLarge,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onLogin,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: Dimensions.iconSizeDefault,
                      width: Dimensions.iconSizeDefault,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      context.local.login,
                      style: AppTextStyles.sfProRoundedSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
