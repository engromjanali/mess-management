import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/widgets/common_labeled_input_item_widget.dart';
import 'package:flutter/material.dart';

/// Login form widget with email and password fields
class LoginFormWidget extends StatelessWidget {
  const LoginFormWidget({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Email field
                CommonLabeledInputItemWidget(
                  label: context.local.email,
                  hintText: context.local.email,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  isRequired: true,
                ),
                const SizedBox(height: Dimensions.spaceDefault),

                // Password field
                CommonLabeledInputItemWidget(
                  label: context.local.password,
                  hintText: context.local.password,
                  controller: passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  isRequired: true,
                  passwordLength: 6,
                ),
                const SizedBox(height: Dimensions.spaceLarge),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: Dimensions.buttonHeightDefault,
                  child: ElevatedButton(
                    onPressed: onLogin,
                    child: Text(
                      context.local.login,
                      style: AppTextStyles.sfProRoundedMedium.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
