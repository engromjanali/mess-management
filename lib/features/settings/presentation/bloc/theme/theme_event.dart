import 'package:clean_boilerplate/features/settings/domain/entities/theme_mode.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme_event.freezed.dart';

/// Theme events using Freezed for type safety
/// Note: No JSON serialization as events are runtime-only
@Freezed(toJson: false, fromJson: false)
class ThemeEvent with _$ThemeEvent {
  /// Load saved theme mode event
  const factory ThemeEvent.loadThemeMode() = LoadThemeMode;

  /// Change theme mode event
  const factory ThemeEvent.changeThemeMode(AppThemeMode mode) = ChangeThemeMode;
}
