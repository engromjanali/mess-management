import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/usecases/get_meal_overview_usecase.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_event.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_state.dart';

/// Meal BLoC — loads and refreshes the user's own (read-only) meal overview.
@injectable
class MealBloc extends Bloc<MealEvent, MealState> {
  final GetMealOverviewUseCase _getMealOverviewUseCase;

  MealBloc(this._getMealOverviewUseCase) : super(const MealState.initial()) {
    on<MealEvent>(_onMealEvent);
  }

  Future<void> _onMealEvent(MealEvent event, Emitter<MealState> emit) async {
    await event.when(load: () => _load(emit, showLoading: true), refresh: () => _load(emit, showLoading: false));
  }

  /// Full-screen loading the first time; a refresh keeps the overview shown
  /// with `refreshing` so the screen shows progress instead of going blank.
  Future<void> _load(Emitter<MealState> emit, {required bool showLoading}) async {
    final current = state;
    if (showLoading || current is! MealLoaded) {
      emit(const MealState.loading());
    } else {
      if (current.refreshing) return;
      emit(current.copyWith(refreshing: true));
    }

    final result = await _getMealOverviewUseCase(const NoParams());

    result.when(success: (success) => emit(MealState.loaded(success.data)), failure: (failure) => emit(MealState.error(failure.error.toString())));
  }
}
