import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/fund_entity.dart';
import '../../domain/usecases/fund_usecases.dart';
import 'fund_date_filter.dart';
import 'fund_event.dart';
import 'fund_state.dart';

/// Fund BLoC — loads fund entries under the active date scope (all time, a
/// single day, or a custom range) and applies add / update / delete mutations.
@injectable
class FundBloc extends Bloc<FundEvent, FundState> {
  final GetAllFundsUseCase _getAllFunds;
  final GetFundsByDateUseCase _getFundsByDate;
  final GetFundsInRangeUseCase _getFundsInRange;
  final AddFundUseCase _addFund;
  final UpdateFundUseCase _updateFund;
  final DeleteFundUseCase _deleteFund;

  // ── Current filter state ──────────────────────────────────────────────
  bool _isAdmin = false;
  FundDateFilter _dateFilter = FundDateFilter.allTime;
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _selectedRange;

  FundBloc(
    this._getAllFunds,
    this._getFundsByDate,
    this._getFundsInRange,
    this._addFund,
    this._updateFund,
    this._deleteFund,
  ) : super(const FundState.initial()) {
    on<FundStarted>(_onStarted);
    on<FundChangeDateFilter>(_onChangeDateFilter);
    on<FundSelectDate>(_onSelectDate);
    on<FundSelectRange>(_onSelectRange);
    on<FundAdd>(_onAdd);
    on<FundUpdate>(_onUpdate);
    on<FundDelete>(_onDelete);
  }

  Future<void> _onStarted(
    FundStarted event,
    Emitter<FundState> emit,
  ) async {
    _isAdmin = event.isAdmin;
    emit(const FundState.loading());
    await _reload(emit);
  }

  Future<void> _onChangeDateFilter(
    FundChangeDateFilter event,
    Emitter<FundState> emit,
  ) async {
    _dateFilter = event.filter;
    emit(const FundState.loading());
    await _reload(emit);
  }

  Future<void> _onSelectDate(
    FundSelectDate event,
    Emitter<FundState> emit,
  ) async {
    _dateFilter = FundDateFilter.day;
    _selectedDate =
        DateTime(event.date.year, event.date.month, event.date.day);
    emit(const FundState.loading());
    await _reload(emit);
  }

  Future<void> _onSelectRange(
    FundSelectRange event,
    Emitter<FundState> emit,
  ) async {
    _dateFilter = FundDateFilter.range;
    _selectedRange = DateTimeRange(start: event.start, end: event.end);
    emit(const FundState.loading());
    await _reload(emit);
  }

  Future<void> _onAdd(FundAdd event, Emitter<FundState> emit) async {
    _emitSaving(emit);
    final result = await _addFund(
      AddFundParams(amount: event.amount, date: event.date, note: event.note),
    );
    await _afterMutation(emit, result);
  }

  Future<void> _onUpdate(FundUpdate event, Emitter<FundState> emit) async {
    _emitSaving(emit);
    final result = await _updateFund(
      UpdateFundParams(
        id: event.id,
        amount: event.amount,
        date: event.date,
        note: event.note,
      ),
    );
    await _afterMutation(emit, result);
  }

  Future<void> _onDelete(FundDelete event, Emitter<FundState> emit) async {
    _emitSaving(emit);
    final result = await _deleteFund(event.id);
    await _afterMutation(emit, result);
  }

  /// Loads funds for the current date scope and emits a loaded state.
  Future<void> _reload(Emitter<FundState> emit) async {
    final Result<List<FundEntity>> result;
    switch (_dateFilter) {
      case FundDateFilter.allTime:
        result = await _getAllFunds(const NoParams());
      case FundDateFilter.day:
        result = await _getFundsByDate(_selectedDate);
      case FundDateFilter.range:
        final range = _selectedRange;
        result = range == null
            ? await _getAllFunds(const NoParams())
            : await _getFundsInRange(
                FundRangeParams(start: range.start, end: range.end),
              );
    }

    result.when(
      success: (s) => emit(_loaded(s.data)),
      failure: (f) => emit(FundState.error(f.error.toString())),
    );
  }

  /// Keeps current data visible while a mutation is in flight.
  void _emitSaving(Emitter<FundState> emit) {
    final current = state;
    if (current is FundLoaded) {
      emit(current.copyWith(saving: true));
    }
  }

  /// On a failed mutation surface the error; otherwise reload the active list.
  Future<void> _afterMutation(
    Emitter<FundState> emit,
    Result<dynamic> result,
  ) async {
    if (result.isFailure) {
      emit(FundState.error(result.error.toString()));
      return;
    }
    await _reload(emit);
  }

  FundState _loaded(List<FundEntity> funds) => FundState.loaded(
        funds: funds,
        dateFilter: _dateFilter,
        selectedDate: _selectedDate,
        isAdmin: _isAdmin,
        selectedRange: _selectedRange,
      );
}
