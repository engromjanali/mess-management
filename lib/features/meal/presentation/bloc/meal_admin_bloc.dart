import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_member_entity.dart';
import 'package:clean_boilerplate/features/meal/domain/usecases/add_meals_for_day_usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/usecases/delete_member_meal_usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/usecases/get_meal_admin_data_usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/usecases/update_member_meal_usecase.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_admin_event.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_admin_state.dart';

/// Admin meal-management BLoC — loads the roster and records and lets a manager
/// add a day's meals, and edit or delete a member's meal on a date.
///
/// The active member/date filters are held here so they survive reloads after
/// a save or delete; the loaded state always carries the latest of both, plus
/// `busy` while a refresh or change is in flight.
@injectable
class MealAdminBloc extends Bloc<MealAdminEvent, MealAdminState> {
  final GetMealAdminDataUseCase _getAdminData;
  final AddMealsForDayUseCase _addMealsForDay;
  final UpdateMemberMealUseCase _updateMemberMeal;
  final DeleteMemberMealUseCase _deleteMemberMeal;

  MealAdminEntity? _data;
  String? _selectedMemberId;
  DateTime? _selectedDate;
  bool _busy = false;

  MealAdminBloc(this._getAdminData, this._addMealsForDay, this._updateMemberMeal, this._deleteMemberMeal) : super(const MealAdminState.initial()) {
    on<MealAdminEvent>(_onEvent);
  }

  Future<void> _onEvent(MealAdminEvent event, Emitter<MealAdminState> emit) async {
    await event.when(
      load: () => _load(emit),
      // Without data yet there's nothing to keep on screen, so load in full.
      refresh: () => _data == null ? _load(emit) : _run(emit, () => _getAdminData(const NoParams())),
      selectMember: (memberId) async {
        _selectedMemberId = memberId;
        _emitLoaded(emit);
      },
      selectDate: (date) async {
        _selectedDate = date;
        _emitLoaded(emit);
      },
      // Focus the list on the day just added so the result is visible.
      addForDay: (date, meals) => _run(
        emit,
        () => _addMealsForDay(AddMealsForDayParams(date: date, meals: meals)),
        focusDate: date,
      ),
      update: (memberId, date, breakfast, lunch, dinner) =>
          _run(emit, () => _updateMemberMeal(UpdateMemberMealParams(memberId: memberId, date: date, breakfast: breakfast, lunch: lunch, dinner: dinner))),
      delete: (memberId, date) => _run(emit, () => _deleteMemberMeal(DeleteMemberMealParams(memberId: memberId, date: date))),
    );
  }

  Future<void> _load(Emitter<MealAdminState> emit) async {
    emit(const MealAdminState.loading());

    final result = await _getAdminData(const NoParams());

    result.when(
      success: (success) {
        _data = success.data;
        _emitLoaded(emit);
      },
      failure: (failure) => emit(MealAdminState.error(failure.error.toString())),
    );
  }

  /// Runs a refresh or add/edit/delete while keeping the list on screen as
  /// `busy`, so the UI shows progress and blocks repeat taps. A second action
  /// that arrives while one is running is ignored.
  Future<void> _run(Emitter<MealAdminState> emit, ResultFuture<MealAdminEntity> Function() action, {DateTime? focusDate}) async {
    if (_busy) return;
    _busy = true;
    _emitLoaded(emit);

    final result = await action();
    _busy = false;

    result.when(
      success: (success) {
        _data = success.data;
        if (focusDate != null) _selectedDate = DateTime(focusDate.year, focusDate.month, focusDate.day);
        _emitLoaded(emit);
      },
      failure: (failure) => _emitActionError(emit, failure.error.toString()),
    );
  }

  /// Reports a failed action, then restores the loaded data so the screen
  /// keeps its list; listeners show [message] as a snack bar.
  void _emitActionError(Emitter<MealAdminState> emit, String message) {
    emit(MealAdminState.error(message));
    _emitLoaded(emit);
  }

  /// Re-emits the loaded state from the cached data, filters and busy flag.
  void _emitLoaded(Emitter<MealAdminState> emit) {
    final data = _data;
    if (data == null) return;
    emit(MealAdminState.loaded(data: data, selectedMemberId: _selectedMemberId, selectedDate: _selectedDate, busy: _busy));
  }
}
