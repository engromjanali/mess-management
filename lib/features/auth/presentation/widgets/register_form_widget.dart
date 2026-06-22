import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/widgets/common_labeled_input_item_widget.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';

/// Sign-up form carrying over the legacy fields: full name, email, phone
/// (with country code) and password.
class RegisterFormWidget extends StatelessWidget {
  const RegisterFormWidget({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.onRegister,
    this.countryDialCode = '+880',
    this.onCountryChanged,
    this.isLoading = false,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final VoidCallback onRegister;
  final String countryDialCode;
  final ValueChanged<CountryCode>? onCountryChanged;
  final bool isLoading;

  /// Brand green kept identical in light and dark mode so the field prefix
  /// icons stay visible against both backgrounds.
  static const Color _prefixIconColor = Color(0xFF1FA463);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full name
          CommonLabeledInputItemWidget(
            label: 'Full Name',
            hintText: 'Enter your full name',
            controller: nameController,
            keyboardType: TextInputType.name,
            prefixIcon: const Icon(Icons.person_outline_rounded),
            prefixIconColor: _prefixIconColor,
            borderRadius: Dimensions.radiusLarge,
            isRequired: true,
          ),
          const SizedBox(height: Dimensions.spaceDefault),

          // Email
          CommonLabeledInputItemWidget(
            label: context.local.email,
            hintText: context.local.email,
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.alternate_email_rounded),
            prefixIconColor: _prefixIconColor,
            borderRadius: Dimensions.radiusLarge,
            isRequired: true,
          ),
          const SizedBox(height: Dimensions.spaceDefault),

          // Phone with country code
          CommonLabeledInputItemWidget(
            label: 'Phone',
            hintText: 'Phone number',
            controller: phoneController,
            keyboardType: TextInputType.phone,
            countryDialCode: countryDialCode,
            onCountryChanged: onCountryChanged,
            borderRadius: Dimensions.radiusLarge,
            isRequired: true,
          ),
          const SizedBox(height: Dimensions.spaceDefault),

          // Password
          CommonLabeledInputItemWidget(
            label: context.local.password,
            hintText: context.local.password,
            controller: passwordController,
            keyboardType: TextInputType.visiblePassword,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            prefixIconColor: _prefixIconColor,
            borderRadius: Dimensions.radiusLarge,
            isRequired: true,
            passwordLength: 6,
          ),
          const SizedBox(height: Dimensions.spaceLarge),

          // Primary action
          SizedBox(
            height: Dimensions.buttonHeightLarge,
            child: ElevatedButton(
              onPressed: isLoading ? null : onRegister,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: Dimensions.iconSizeDefault,
                      width: Dimensions.iconSizeDefault,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Create account',
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
