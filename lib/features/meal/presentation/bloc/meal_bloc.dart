import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/usecases/get_meal_overview_usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/usecases/update_meal_usecase.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_event.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_state.dart';

/// Meal BLoC — loads, refreshes and edits the user's meal overview.
@injectable
class MealBloc extends Bloc<MealEvent, MealState> {
  final GetMealOverviewUseCase _getMealOverviewUseCase;
  final UpdateMealUseCase _updateMealUseCase;

  MealBloc(this._getMealOverviewUseCase, this._updateMealUseCase) : super(const MealState.initial()) {
    on<MealEvent>(_onMealEvent);
  }

  Future<void> _onMealEvent(MealEvent event, Emitter<MealState> emit) async {
    await event.when(
      load: () => _load(emit, showLoading: true),
      refresh: () => _load(emit, showLoading: false),
      updateToday: (breakfast, lunch, dinner) => _updateToday(emit, breakfast, lunch, dinner),
    );
  }

  Future<void> _load(Emitter<MealState> emit, {required bool showLoading}) async {
    if (showLoading) emit(const MealState.loading());

    final result = await _getMealOverviewUseCase(const NoParams());

    result.when(success: (success) => emit(MealState.loaded(success.data)), failure: (failure) => emit(MealState.error(failure.error.toString())));
  }

  Future<void> _updateToday(Emitter<MealState> emit, double breakfast, double lunch, double dinner) async {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);

    final result = await _updateMealUseCase(UpdateMealParams(date: date, breakfast: breakfast, lunch: lunch, dinner: dinner));

    result.when(success: (success) => emit(MealState.loaded(success.data)), failure: (failure) => emit(MealState.error(failure.error.toString())));
  }
}
