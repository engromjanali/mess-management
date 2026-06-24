import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/deposit_entity.dart';
import '../../domain/usecases/deposit_usecases.dart';
import 'deposit_event.dart';
import 'deposit_state.dart';
import 'deposit_view_mode.dart';

/// Deposit BLoC — loads deposits under the active filter (per-member,
/// per-date, or "mine") and applies add / update / delete mutations.
@injectable
class DepositBloc extends Bloc<DepositEvent, DepositState> {
  final GetDepositMembersUseCase _getMembers;
  final GetAllDepositsUseCase _getAllDeposits;
  final GetMemberDepositsUseCase _getMemberDeposits;
  final GetDepositsByDateUseCase _getDepositsByDate;
  final GetDepositsInRangeUseCase _getDepositsInRange;
  final GetMyDepositsUseCase _getMyDeposits;
  final AddDepositUseCase _addDeposit;
  final UpdateDepositUseCase _updateDeposit;
  final DeleteDepositUseCase _deleteDeposit;

  // ── Current filter state ──────────────────────────────────────────────
  bool _isAdmin = false;
  DepositViewMode _mode = DepositViewMode.mine;
  List<DepositMemberEntity> _members = const [];
  DepositMemberEntity? _selectedMember; // null → all members
  DepositDateFilter _dateFilter = DepositDateFilter.allTime;
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _selectedRange;

  DepositBloc(
    this._getMembers,
    this._getAllDeposits,
    this._getMemberDeposits,
    this._getDepositsByDate,
    this._getDepositsInRange,
    this._getMyDeposits,
    this._addDeposit,
    this._updateDeposit,
    this._deleteDeposit,
  ) : super(const DepositState.initial()) {
    on<DepositStarted>(_onStarted);
    on<DepositChangeMode>(_onChangeMode);
    on<DepositSelectMember>(_onSelectMember);
    on<DepositChangeDateFilter>(_onChangeDateFilter);
    on<DepositSelectDate>(_onSelectDate);
    on<DepositSelectRange>(_onSelectRange);
    on<DepositAdd>(_onAdd);
    on<DepositUpdate>(_onUpdate);
    on<DepositDelete>(_onDelete);
  }

  Future<void> _onStarted(
    DepositStarted event,
    Emitter<DepositState> emit,
  ) async {
    _isAdmin = event.isAdmin;
    emit(const DepositState.loading());

    if (_isAdmin) {
      final membersResult = await _getMembers(const NoParams());
      membersResult.when(
        success: (s) => _members = s.data,
        failure: (_) => _members = const [],
      );
      // Admins start on the by-member view, focused on all members.
      _mode = DepositViewMode.byMember;
      _selectedMember = null;
    } else {
      _members = const [];
      _mode = DepositViewMode.mine;
      _selectedMember = null;
    }

    await _reload(emit);
  }

  Future<void> _onChangeMode(
    DepositChangeMode event,
    Emitter<DepositState> emit,
  ) async {
    if (!_isAdmin || event.mode == DepositViewMode.mine) return;
    _mode = event.mode;
    emit(const DepositState.loading());
    await _reload(emit);
  }

  Future<void> _onSelectMember(
    DepositSelectMember event,
    Emitter<DepositState> emit,
  ) async {
    if (!_isAdmin) return;
    _mode = DepositViewMode.byMember;
    final id = event.memberId;
    _selectedMember = id == null
        ? null
        : _members.firstWhere(
            (m) => m.id == id,
            orElse: () => _selectedMember ?? _members.first,
          );
    emit(const DepositState.loading());
    await _reload(emit);
  }

  Future<void> _onChangeDateFilter(
    DepositChangeDateFilter event,
    Emitter<DepositState> emit,
  ) async {
    if (!_isAdmin) return;
    _mode = DepositViewMode.byDate;
    _dateFilter = event.filter;
    emit(const DepositState.loading());
    await _reload(emit);
  }

  Future<void> _onSelectDate(
    DepositSelectDate event,
    Emitter<DepositState> emit,
  ) async {
    if (!_isAdmin) return;
    _mode = DepositViewMode.byDate;
    _dateFilter = DepositDateFilter.day;
    _selectedDate =
        DateTime(event.date.year, event.date.month, event.date.day);
    emit(const DepositState.loading());
    await _reload(emit);
  }

  Future<void> _onSelectRange(
    DepositSelectRange event,
    Emitter<DepositState> emit,
  ) async {
    if (!_isAdmin) return;
    _mode = DepositViewMode.byDate;
    _dateFilter = DepositDateFilter.range;
    _selectedRange = DateTimeRange(start: event.start, end: event.end);
    emit(const DepositState.loading());
    await _reload(emit);
  }

  Future<void> _onAdd(DepositAdd event, Emitter<DepositState> emit) async {
    _emitSaving(emit);
    final result = await _addDeposit(
      AddDepositParams(
        memberId: event.memberId,
        amount: event.amount,
        date: event.date,
        note: event.note,
      ),
    );
    await _afterMutation(emit, result);
  }

  Future<void> _onUpdate(
    DepositUpdate event,
    Emitter<DepositState> emit,
  ) async {
    _emitSaving(emit);
    final result = await _updateDeposit(
      UpdateDepositParams(
        id: event.id,
        amount: event.amount,
        date: event.date,
        note: event.note,
      ),
    );
    await _afterMutation(emit, result);
  }

  Future<void> _onDelete(
    DepositDelete event,
    Emitter<DepositState> emit,
  ) async {
    _emitSaving(emit);
    final result = await _deleteDeposit(event.id);
    await _afterMutation(emit, result);
  }

  /// Loads deposits for the current filter and emits a loaded state.
  Future<void> _reload(Emitter<DepositState> emit) async {
    final Result<List<DepositEntity>> result;
    switch (_mode) {
      case DepositViewMode.byMember:
        result = _selectedMember == null
            ? await _getAllDeposits(const NoParams())
            : await _getMemberDeposits(_selectedMember!.id);
      case DepositViewMode.byDate:
        switch (_dateFilter) {
          case DepositDateFilter.allTime:
            result = await _getAllDeposits(const NoParams());
          case DepositDateFilter.day:
            result = await _getDepositsByDate(_selectedDate);
          case DepositDateFilter.range:
            final range = _selectedRange;
            result = range == null
                ? await _getAllDeposits(const NoParams())
                : await _getDepositsInRange(
                    DepositRangeParams(start: range.start, end: range.end),
                  );
        }
      case DepositViewMode.mine:
        result = await _getMyDeposits(const NoParams());
    }

    result.when(
      success: (s) => emit(_loaded(s.data)),
      failure: (f) => emit(DepositState.error(f.error.toString())),
    );
  }

  /// Keeps current data visible while a mutation is in flight.
  void _emitSaving(Emitter<DepositState> emit) {
    final current = state;
    if (current is DepositLoaded) {
      emit(current.copyWith(saving: true));
    }
  }

  /// On a failed mutation surface the error; otherwise reload the active list.
  Future<void> _afterMutation(
    Emitter<DepositState> emit,
    Result<dynamic> result,
  ) async {
    if (result.isFailure) {
      emit(DepositState.error(result.error.toString()));
      return;
    }
    await _reload(emit);
  }

  DepositState _loaded(List<DepositEntity> deposits) => DepositState.loaded(
        mode: _mode,
        deposits: deposits,
        members: _members,
        dateFilter: _dateFilter,
        selectedDate: _selectedDate,
        isAdmin: _isAdmin,
        selectedMember: _selectedMember,
        selectedRange: _selectedRange,
      );
}
