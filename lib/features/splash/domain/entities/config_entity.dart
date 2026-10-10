import 'package:equatable/equatable.dart';

/// App-wide settings the admin sets in Django admin (`/api/v1/app/config`).
class ConfigEntity extends Equatable {
  /// Newest app version; an older app is offered an optional update.
  final String latestVersion;

  /// Oldest supported version; an older app must update before use.
  final String minimumVersion;

  /// Shown with the update prompt (empty = the app's default text).
  final String updateMessage;
  final String androidStoreUrl;
  final String iosStoreUrl;

  /// While on, the app shows [maintenanceMessage] instead of its screens.
  final bool maintenanceMode;
  final String maintenanceMessage;

  /// Expected end of maintenance, if the admin set one.
  final DateTime? maintenanceUntil;

  final String supportEmail;

  const ConfigEntity({
    required this.latestVersion,
    required this.minimumVersion,
    this.updateMessage = '',
    this.androidStoreUrl = '',
    this.iosStoreUrl = '',
    this.maintenanceMode = false,
    this.maintenanceMessage = '',
    this.maintenanceUntil,
    this.supportEmail = '',
  });

  /// Whether [appVersion] is too old to use.
  bool requiresUpdate(String appVersion) => compareVersions(appVersion, minimumVersion) < 0;

  /// Whether a newer (optional) version exists.
  bool updateAvailable(String appVersion) => compareVersions(appVersion, latestVersion) < 0;

  @override
  List<Object?> get props => [latestVersion, minimumVersion, updateMessage, androidStoreUrl, iosStoreUrl, maintenanceMode, maintenanceMessage, maintenanceUntil, supportEmail];
}

/// Compares dotted versions part by part (`1.2.10` > `1.2.9`); `+build` suffixes are ignored.
int compareVersions(String a, String b) {
  List<int> parts(String version) => version.split('+').first.split('.').map((part) => int.tryParse(part.trim()) ?? 0).toList();
  final left = parts(a);
  final right = parts(b);
  for (var i = 0; i < 3; i++) {
    final difference = (i < left.length ? left[i] : 0) - (i < right.length ? right[i] : 0);
    if (difference != 0) return difference.sign;
  }
  return 0;
}
