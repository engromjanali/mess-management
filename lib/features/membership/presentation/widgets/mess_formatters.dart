import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';

/// Formatting helpers for the mess details screen.
class MessFormatters {
  const MessFormatters._();

  /// Translated label for a `manager` / `acting_manager` / `member` role.
  static String role(BuildContext context, String role) => switch (role) {
    'manager' => context.local.roleManager,
    'acting_manager' => context.local.roleActingManager,
    _ => context.local.roleMember,
  };

  /// A date in the app's language, e.g. `3 Oct 2026`.
  static String date(BuildContext context, DateTime value) => DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(value);

  /// Up to two initials, e.g. `Green House` → `GH`.
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
  }
}
