import 'package:bloc/bloc.dart';
import 'package:clean_boilerplate/features/splash/domain/entities/config_entity.dart';
import 'package:clean_boilerplate/features/splash/domain/usecases/get_config_usecase.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'splash_event.dart';
part 'splash_state.dart';
part 'splash_bloc.freezed.dart';

@injectable
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final GetConfigUseCase _getConfigUseCase;

  SplashBloc(this._getConfigUseCase) : super(const SplashState.loading()) {
    on<SplashEvent>(_onGetConfig);
  }

  Future<void> _onGetConfig(SplashEvent event, Emitter<SplashState> emit) async {
    emit(const SplashState.loading());
    final result = await _getConfigUseCase();

    result.when(success: (config) => emit(SplashState.loaded(config.data)), failure: (failure) => emit(SplashState.error(failure.error.toString())));
  }
}
