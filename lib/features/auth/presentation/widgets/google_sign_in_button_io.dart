import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/features/auth/data/services/google_sign_in_service.dart';
import 'package:mess_pilot/features/auth/presentation/widgets/google_sign_in_button_view.dart';

typedef GoogleIdTokenCallback = void Function(String idToken);
typedef GoogleSignInErrorCallback = void Function(String message);

/// "Continue with Google" button for Android, iOS and macOS.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({required this.onIdToken, required this.onError, this.enabled = true, super.key});

  final GoogleIdTokenCallback onIdToken;
  final GoogleSignInErrorCallback onError;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!GoogleSignInService.instance.isSupported) return const SizedBox.shrink();
    return GoogleSignInButtonView(enabled: enabled, onPressed: () => _signIn(context));
  }

  Future<void> _signIn(BuildContext context) async {
    final service = GoogleSignInService.instance;
    if (!service.isConfigured) {
      onError(context.local.googleSignInNotConfigured);
      return;
    }
    if (!service.supportsAuthenticate) {
      onError(context.local.googleSignInFailed);
      return;
    }
    try {
      final idToken = await service.authenticate();
      if (idToken == null || idToken.isEmpty) {
        if (context.mounted) onError(context.local.googleSignInFailed);
        return;
      }
      onIdToken(idToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled || error.code == GoogleSignInExceptionCode.interrupted) return;
      if (context.mounted) onError(context.local.googleSignInFailed);
    } catch (_) {
      if (context.mounted) onError(context.local.googleSignInFailed);
    }
  }
}
