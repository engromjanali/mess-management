import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mess_pilot/config/util/app_constants.dart';

/// Thin wrapper around `google_sign_in` that initializes the SDK once with the
/// OAuth client IDs from [AppConstants] and exposes the two flows the app uses:
/// interactive `authenticate()` on native platforms and the SDK-rendered
/// button + [authenticationEvents] on web.
class GoogleSignInService {
  GoogleSignInService._();

  static final GoogleSignInService instance = GoogleSignInService._();

  Future<void>? _initializing;
  bool _initialized = false;

  /// Whether Google Sign-In exists on this platform at all.
  bool get isSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// Whether the login screen should render the Google entry point. It shows
  /// even before IDs are configured so the layout is always the same; tapping
  /// then explains that Google sign-in is not configured for this build.
  bool get shouldShowButton => isSupported;

  /// True when this platform has the OAuth client ID it needs at build time.
  bool get isConfigured {
    if (kIsWeb) return _isRealId(AppConstants.googleWebClientId);
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      return _isRealId(AppConstants.googleIosClientId);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _isRealId(AppConstants.googleWebClientId);
    }
    return false;
  }

  /// Whether this platform supports the app-triggered [authenticate] flow.
  /// Web returns false and must use the Google-rendered button instead.
  bool get supportsAuthenticate => !kIsWeb && GoogleSignIn.instance.supportsAuthenticate();

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents => GoogleSignIn.instance.authenticationEvents;

  Future<void> ensureInitialized() {
    if (_initialized) return Future<void>.value();
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await GoogleSignIn.instance.initialize(
        clientId: _clientId,
        // google_sign_in_web asserts that serverClientId is null on web.
        serverClientId: kIsWeb ? null : _serverClientId,
      );
      _initialized = true;
    } catch (_) {
      // Allow a later retry instead of caching a failed initialization.
      _initializing = null;
      rethrow;
    }
  }

  String? get _clientId {
    if (kIsWeb) return _realIdOrNull(AppConstants.googleWebClientId);
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      return _realIdOrNull(AppConstants.googleIosClientId);
    }
    // Android resolves the client from google-services.json; the web client ID
    // is passed as serverClientId so the SDK returns an ID token.
    return null;
  }

  String? get _serverClientId {
    return _realIdOrNull(AppConstants.googleWebClientId);
  }

  /// Opens the Google account chooser and returns the ID token, or null when
  /// the user cancels.
  Future<String?> authenticate() async {
    await ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    return _emptyToNull(account.authentication.idToken);
  }

  Future<void> signOut() => GoogleSignIn.instance.signOut();

  static bool _isRealId(String value) => value.isNotEmpty && !value.startsWith('YOUR_');

  static String? _realIdOrNull(String value) => _isRealId(value) ? value : null;

  static String? _emptyToNull(String? value) => value == null || value.isEmpty ? null : value;
}
