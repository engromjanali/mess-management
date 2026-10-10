import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/helpers/auth_helper.dart';
import 'package:clean_boilerplate/features/splash/domain/entities/config_entity.dart';

/// The installed app's version, e.g. `1.0.0` (from pubspec `version`).
Future<String> currentAppVersion() async => (await PackageInfo.fromPlatform()).version;

/// Opens the app for [config]: the maintenance screen while maintenance mode
/// is on, the update screen when this version is too old, an optional update
/// prompt when a newer one exists, then home (or login when signed out).
Future<void> openApp(BuildContext context, ConfigEntity config) async {
  final version = await currentAppVersion();
  if (!context.mounted) return;
  if (config.maintenanceMode) return context.go(AppRoutes.maintenance);
  if (config.requiresUpdate(version)) return context.go(AppRoutes.updateRequired);
  if (config.updateAvailable(version)) {
    await showDialog<void>(context: context, builder: (_) => _UpdateAvailableDialog(config: config, currentVersion: version));
    if (!context.mounted) return;
  }
  context.go(AuthHelper.isLogin() ? AppRoutes.getHomeRoute() : AppRoutes.getLoginRoute());
}

Future<void> openBlockedAppRoute(BuildContext context, ConfigEntity config) async {
  final path = router.routerDelegate.currentConfiguration.uri.path;
  if (config.maintenanceMode) {
    if (path != AppRoutes.maintenance) router.go(AppRoutes.maintenance);
    return;
  }

  if (path == AppRoutes.getSplashRoute() || path == AppRoutes.maintenance || path == AppRoutes.updateRequired) return;

  final version = await currentAppVersion();
  if (!context.mounted) return;
  if (config.requiresUpdate(version)) {
    router.go(AppRoutes.updateRequired);
    return;
  }
}

/// The store page for this platform, or null when the admin set none.
Uri? storeUrl(ConfigEntity config) {
  final isApple = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
  final url = isApple ? config.iosStoreUrl : config.androidStoreUrl;
  return url.isEmpty ? null : Uri.tryParse(url);
}

Future<void> openStore(Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);

class _UpdateAvailableDialog extends StatelessWidget {
  const _UpdateAvailableDialog({required this.config, required this.currentVersion});

  final ConfigEntity config;
  final String currentVersion;

  @override
  Widget build(BuildContext context) {
    final url = storeUrl(config);
    return AlertDialog(
      icon: const Icon(Icons.system_update_rounded),
      title: Text(context.local.updateAvailableTitle),
      content: Text(config.updateMessage.isNotEmpty ? config.updateMessage : context.local.updateAvailableMessage(currentVersion, config.latestVersion)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.local.later)),
        if (url != null)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              openStore(url);
            },
            child: Text(context.local.updateNow),
          ),
      ],
    );
  }
}
