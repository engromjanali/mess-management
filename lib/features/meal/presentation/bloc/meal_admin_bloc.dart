import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
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
/// a save or delete; the loaded state always carries the latest of both.
@injectable
class MealAdminBloc extends Bloc<MealAdminEvent, MealAdminState> {
  final GetMealAdminDataUseCase _getAdminData;
  final AddMealsForDayUseCase _addMealsForDay;
  final UpdateMemberMealUseCase _updateMemberMeal;
  final DeleteMemberMealUseCase _deleteMemberMeal;

  MealAdminEntity? _data;
  String? _selectedMemberId;
  DateTime? _selectedDate;

  MealAdminBloc(this._getAdminData, this._addMealsForDay, this._updateMemberMeal, this._deleteMemberMeal) : super(const MealAdminState.initial()) {
    on<MealAdminEvent>(_onEvent);
  }

  Future<void> _onEvent(MealAdminEvent event, Emitter<MealAdminState> emit) async {
    await event.when(
      load: () => _load(emit, showLoading: true),
      refresh: () => _load(emit, showLoading: false),
      selectMember: (memberId) async {
        _selectedMemberId = memberId;
        _emitLoaded(emit);
      },
      selectDate: (date) async {
        _selectedDate = date;
        _emitLoaded(emit);
      },
      addForDay: (date, meals) => _addForDay(emit, date: date, meals: meals),
      update: (memberId, date, breakfast, lunch, dinner) => _update(emit, memberId: memberId, date: date, breakfast: breakfast, lunch: lunch, dinner: dinner),
      delete: (memberId, date) => _delete(emit, memberId: memberId, date: date),
    );
  }

  Future<void> _load(Emitter<MealAdminState> emit, {required bool showLoading}) async {
    if (showLoading) emit(const MealAdminState.loading());

    final result = await _getAdminData(const NoParams());

    result.when(
      success: (success) {
        _data = success.data;
        _emitLoaded(emit);
      },
      failure: (failure) => emit(MealAdminState.error(failure.error.toString())),
    );
  }

  Future<void> _addForDay(Emitter<MealAdminState> emit, {required DateTime date, required List<MemberMealEntity> meals}) async {
    final result = await _addMealsForDay(AddMealsForDayParams(date: date, meals: meals));

    result.when(
      success: (success) {
        _data = success.data;
        // Focus the list on the day we just added so the result is visible.
        _selectedDate = DateTime(date.year, date.month, date.day);
        _emitLoaded(emit);
      },
      failure: (failure) => _emitMutationError(emit, failure.error.toString()),
    );
  }

  Future<void> _update(Emitter<MealAdminState> emit, {required String memberId, required DateTime date, required double breakfast, required double lunch, required double dinner}) async {
    final result = await _updateMemberMeal(UpdateMemberMealParams(memberId: memberId, date: date, breakfast: breakfast, lunch: lunch, dinner: dinner));

    result.when(
      success: (success) {
        _data = success.data;
        _emitLoaded(emit);
      },
      failure: (failure) => _emitMutationError(emit, failure.error.toString()),
    );
  }

  Future<void> _delete(Emitter<MealAdminState> emit, {required String memberId, required DateTime date}) async {
    final result = await _deleteMemberMeal(DeleteMemberMealParams(memberId: memberId, date: date));

    result.when(
      success: (success) {
        _data = success.data;
        _emitLoaded(emit);
      },
      failure: (failure) => _emitMutationError(emit, failure.error.toString()),
    );
  }

  /// Reports a failed add/edit/delete, then restores the loaded data so the
  /// screen keeps its list; listeners show [message] as a snack bar.
  void _emitMutationError(Emitter<MealAdminState> emit, String message) {
    emit(MealAdminState.error(message));
    _emitLoaded(emit);
  }

  /// Re-emits the loaded state from the cached data and current filters.
  void _emitLoaded(Emitter<MealAdminState> emit) {
    final data = _data;
    if (data == null) return;
    emit(MealAdminState.loaded(data: data, selectedMemberId: _selectedMemberId, selectedDate: _selectedDate));
  }
}
