import 'package:bloc/bloc.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/features/splash/data/models/config_model.dart';
import 'package:mess_pilot/features/splash/data/models/support_channel_model.dart';
import 'package:mess_pilot/features/splash/domain/entities/config_entity.dart';
import 'package:mess_pilot/features/splash/domain/usecases/get_config_usecase.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'splash_event.dart';
part 'splash_state.dart';
part 'splash_bloc.freezed.dart';

@injectable
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final GetConfigUseCase _getConfigUseCase;

  static const String _configCacheKey = 'cached_app_config';

  SplashBloc(this._getConfigUseCase) : super(const SplashState.loading()) {
    on<SplashEvent>(_onGetConfig);
  }

  ConfigModel? _getCachedConfig() {
    try {
      final jsonStr = getIt<SharedPreferences>().getString(_configCacheKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      return configModelFromJson(jsonStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCachedConfig(ConfigEntity entity) async {
    try {
      final model = ConfigModel(
        latestVersion: entity.latestVersion,
        minimumVersion: entity.minimumVersion,
        updateMessage: entity.updateMessage,
        androidStoreUrl: entity.androidStoreUrl,
        iosStoreUrl: entity.iosStoreUrl,
        maintenance: MaintenanceModel(
          enabled: entity.maintenanceMode,
          message: entity.maintenanceMessage,
          until: entity.maintenanceUntil,
        ),
        supportEmail: entity.supportEmail,
        supportChannels: entity.supportChannels
            .map((c) => SupportChannelModel(name: c.name, kind: c.kind, destination: c.destination, url: c.url))
            .toList(),
      );
      await getIt<SharedPreferences>().setString(_configCacheKey, configModelToJson(model));
    } catch (_) {}
  }

  Future<void> _clearCachedConfig() async {
    try {
      await getIt<SharedPreferences>().remove(_configCacheKey);
    } catch (_) {}
  }

  Future<void> _onGetConfig(SplashEvent event, Emitter<SplashState> emit) async {
    final cached = _getCachedConfig();
    final cachedEntity = cached?.toEntity();

    if (cachedEntity != null) {
      emit(SplashState.loaded(cachedEntity));
    } else {
      emit(const SplashState.loading());
    }

    final result = await _getConfigUseCase();

    await result.when(
      success: (config) async {
        final newEntity = config.data;
        if (cachedEntity == null) {
          await _saveCachedConfig(newEntity);
          emit(SplashState.loaded(newEntity));
        } else if (cachedEntity != newEntity) {
          await _clearCachedConfig();
          await _saveCachedConfig(newEntity);
          emit(SplashState.loaded(newEntity));
          appStartupComplete = false;
          router.go(AppRoutes.getSplashRoute());
        }
      },
      failure: (failure) async {
        if (cachedEntity == null) {
          emit(SplashState.error(failure.message.toString()));
        }
      },
    );
  }
}
