import 'package:flutter/material.dart';

typedef GoogleIdTokenCallback = void Function(String idToken);
typedef GoogleSignInErrorCallback = void Function(String message);

/// Fallback used on platforms without a Google Sign-In implementation.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({required this.onIdToken, required this.onError, this.enabled = true, super.key});

  final GoogleIdTokenCallback onIdToken;
  final GoogleSignInErrorCallback onError;
  final bool enabled;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
