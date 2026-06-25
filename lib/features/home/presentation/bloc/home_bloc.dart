import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/home/domain/usecases/get_dashboard_usecase.dart';
import 'package:clean_boilerplate/features/home/presentation/bloc/home_event.dart';
import 'package:clean_boilerplate/features/home/presentation/bloc/home_state.dart';

/// Home BLoC — loads and refreshes the dashboard.
@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetDashboardUseCase _getDashboardUseCase;

  HomeBloc(this._getDashboardUseCase) : super(const HomeState.initial()) {
    on<HomeEvent>(_onHomeEvent);
  }

  Future<void> _onHomeEvent(HomeEvent event, Emitter<HomeState> emit) async {
    await event.when(
      loadDashboard: () => _load(emit, showLoading: true),
      refreshDashboard: () => _load(emit, showLoading: false),
    );
  }

  Future<void> _load(Emitter<HomeState> emit, {required bool showLoading}) async {
    // On refresh we keep the current data on screen (no full-page spinner).
    if (showLoading) emit(const HomeState.loading());

    final result = await _getDashboardUseCase(const NoParams());

    result.when(
      success: (success) => emit(HomeState.loaded(success.data)),
      failure: (failure) => emit(HomeState.error(failure.error.toString())),
    );
  }
}
