import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/assets/assets.gen.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';

/// The app-styled "Continue with Google" surface, shared by the native button
/// and the web fallback shown before Google's client ID is configured.
class GoogleSignInButtonView extends StatelessWidget {
  const GoogleSignInButtonView({required this.onPressed, this.enabled = true, super.key});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return SizedBox(
      width: double.infinity,
      height: Dimensions.buttonHeight,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Assets.images.icons8GoogleLogo48.image(width: 20, height: 20, fit: BoxFit.contain),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text(
              context.local.continueWithGoogle,
              style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
