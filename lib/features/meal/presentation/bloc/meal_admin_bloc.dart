import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_member_entity.dart';
import 'package:clean_boilerplate/features/meal/domain/usecases/add_meal_for_all_usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/usecases/delete_member_meal_usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/usecases/get_meal_admin_data_usecase.dart';
import 'package:clean_boilerplate/features/meal/domain/usecases/save_member_meal_usecase.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_admin_event.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_admin_state.dart';

/// Admin meal-management BLoC — loads the roster and records and lets a manager
/// add, edit and delete meals for a specific member on a specific date.
///
/// The active member/date filters are held here so they survive reloads after
/// a save or delete; the loaded state always carries the latest of both.
@injectable
class MealAdminBloc extends Bloc<MealAdminEvent, MealAdminState> {
  final GetMealAdminDataUseCase _getAdminData;
  final AddMealForAllUseCase _addMealForAll;
  final SaveMemberMealUseCase _saveMemberMeal;
  final DeleteMemberMealUseCase _deleteMemberMeal;

  MealAdminEntity? _data;
  String? _selectedMemberId;
  DateTime? _selectedDate;

  MealAdminBloc(this._getAdminData, this._addMealForAll, this._saveMemberMeal, this._deleteMemberMeal) : super(const MealAdminState.initial()) {
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
      addForAll: (date, breakfast, lunch, dinner) => _addForAllMembers(emit, date: date, breakfast: breakfast, lunch: lunch, dinner: dinner),
      save: (memberId, date, breakfast, lunch, dinner) => _save(emit, memberId: memberId, date: date, breakfast: breakfast, lunch: lunch, dinner: dinner),
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

  Future<void> _addForAllMembers(Emitter<MealAdminState> emit, {required DateTime date, required double breakfast, required double lunch, required double dinner}) async {
    final result = await _addMealForAll(AddMealForAllParams(date: date, breakfast: breakfast, lunch: lunch, dinner: dinner));

    result.when(
      success: (success) {
        _data = success.data;
        // Focus the list on the day we just stamped so the result is visible.
        _selectedDate = DateTime(date.year, date.month, date.day);
        _emitLoaded(emit);
      },
      failure: (failure) => emit(MealAdminState.error(failure.error.toString())),
    );
  }

  Future<void> _save(Emitter<MealAdminState> emit, {required String memberId, required DateTime date, required double breakfast, required double lunch, required double dinner}) async {
    final result = await _saveMemberMeal(SaveMemberMealParams(memberId: memberId, date: date, breakfast: breakfast, lunch: lunch, dinner: dinner));

    result.when(
      success: (success) {
        _data = success.data;
        _emitLoaded(emit);
      },
      failure: (failure) => emit(MealAdminState.error(failure.error.toString())),
    );
  }

  Future<void> _delete(Emitter<MealAdminState> emit, {required String memberId, required DateTime date}) async {
    final result = await _deleteMemberMeal(DeleteMemberMealParams(memberId: memberId, date: date));

    result.when(
      success: (success) {
        _data = success.data;
        _emitLoaded(emit);
      },
      failure: (failure) => emit(MealAdminState.error(failure.error.toString())),
    );
  }

  /// Re-emits the loaded state from the cached data and current filters.
  void _emitLoaded(Emitter<MealAdminState> emit) {
    final data = _data;
    if (data == null) return;
    emit(MealAdminState.loaded(data: data, selectedMemberId: _selectedMemberId, selectedDate: _selectedDate));
  }
}
