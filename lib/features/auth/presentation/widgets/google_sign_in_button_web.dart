import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/features/auth/data/services/google_sign_in_service.dart';
import 'package:mess_pilot/features/auth/presentation/widgets/google_sign_in_button_view.dart';

typedef GoogleIdTokenCallback = void Function(String idToken);
typedef GoogleSignInErrorCallback = void Function(String message);

void _noop() {}

/// Web sign-in: Google requires its own rendered button instead of app UI, and
/// delivers the result through [GoogleSignInService.authenticationEvents].
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({required this.onIdToken, required this.onError, this.enabled = true, super.key});

  final GoogleIdTokenCallback onIdToken;
  final GoogleSignInErrorCallback onError;
  final bool enabled;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final service = GoogleSignInService.instance;
    if (!service.isConfigured) return;
    try {
      await service.ensureInitialized();
    } catch (_) {
      if (mounted) widget.onError(context.local.googleSignInFailed);
      return;
    }
    if (!mounted) return;
    _subscription = service.authenticationEvents.listen(
      (event) {
        if (event case GoogleSignInAuthenticationEventSignIn(:final user)) {
          final idToken = user.authentication.idToken;
          if (idToken != null && idToken.isNotEmpty) widget.onIdToken(idToken);
        }
      },
      onError: (Object _) {
        if (mounted) widget.onError(context.local.googleSignInFailed);
      },
    );
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!GoogleSignInService.instance.isConfigured) {
      return GoogleSignInButtonView(
        enabled: widget.enabled,
        onPressed: () => widget.onError(context.local.googleSignInNotConfigured),
      );
    }
    if (!_ready) {
      return const GoogleSignInButtonView(enabled: false, onPressed: _noop);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final locale = Localizations.localeOf(context).languageCode;
        // Google caps the rendered button at 400px; use the available width up to that.
        final maxWidth = constraints.hasBoundedWidth ? constraints.maxWidth : 400.0;
        final buttonWidth = maxWidth > 400 ? 400.0 : maxWidth;
        return Center(
          child: SizedBox(
            key: ValueKey('gsi_${locale}_$buttonWidth'),
            width: buttonWidth,
            height: Dimensions.buttonHeight,
            child: web.renderButton(
              configuration: web.GSIButtonConfiguration(
                type: web.GSIButtonType.standard,
                theme: web.GSIButtonTheme.outline,
                size: web.GSIButtonSize.large,
                text: web.GSIButtonText.continueWith,
                shape: web.GSIButtonShape.rectangular,
                logoAlignment: web.GSIButtonLogoAlignment.center,
                minimumWidth: buttonWidth,
                locale: locale,
              ),
            ),
          ),
        );
      },
    );
  }
}
