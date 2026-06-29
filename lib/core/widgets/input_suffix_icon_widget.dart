import 'package:flutter/material.dart';

class InputSuffixIconWidget extends StatelessWidget {
  final bool isPasswordField;
  final bool obscurePassword;
  final bool enabled;
  final Widget? customSuffixIcon;
  final VoidCallback onTogglePasswordVisibility;

  const InputSuffixIconWidget({
    required this.isPasswordField,
    required this.obscurePassword,
    required this.enabled,
    required this.customSuffixIcon,
    required this.onTogglePasswordVisibility,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isPasswordField) {
      return IconButton(
        icon: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(3.1416),
          child: Icon(
            obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: enabled ? Theme.of(context).textTheme.titleLarge!.color!.withValues(alpha: 0.5) : Theme.of(context).disabledColor,
          ),
        ),
        onPressed: enabled ? onTogglePasswordVisibility : null,
      );
    }

    if (customSuffixIcon != null) {
      return customSuffixIcon!;
    }

    return const SizedBox.shrink();
  }
}
