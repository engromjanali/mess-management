import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';
import 'package:clean_boilerplate/features/cost/domain/usecases/cost_usecases.dart';
import 'package:clean_boilerplate/features/cost/presentation/bloc/cost_event.dart';
import 'package:clean_boilerplate/features/cost/presentation/bloc/cost_state.dart';

/// Cost (bazar) BLoC — loads the entry list and applies add / update / delete
/// mutations, reloading the list afterwards.
@injectable
class CostBloc extends Bloc<CostEvent, CostState> {
  final GetCostMembersUseCase _getMembers;
  final GetCostsUseCase _getCosts;
  final AddCostUseCase _addCost;
  final UpdateCostUseCase _updateCost;
  final DeleteCostUseCase _deleteCost;

  bool _isAdmin = false;
  List<CostMemberEntity> _members = const [];

  CostBloc(
    this._getMembers,
    this._getCosts,
    this._addCost,
    this._updateCost,
    this._deleteCost,
  ) : super(const CostState.initial()) {
    on<CostStarted>(_onStarted);
    on<CostRefresh>(_onRefresh);
    on<CostAdd>(_onAdd);
    on<CostUpdate>(_onUpdate);
    on<CostDelete>(_onDelete);
  }

  Future<void> _onStarted(
    CostStarted event,
    Emitter<CostState> emit,
  ) async {
    _isAdmin = event.isAdmin;
    emit(const CostState.loading());

    if (_isAdmin) {
      final membersResult = await _getMembers(const NoParams());
      membersResult.when(
        success: (s) => _members = s.data,
        failure: (_) => _members = const [],
      );
    } else {
      _members = const [];
    }

    await _reload(emit);
  }

  Future<void> _onRefresh(
    CostRefresh event,
    Emitter<CostState> emit,
  ) async {
    await _reload(emit);
  }

  Future<void> _onAdd(CostAdd event, Emitter<CostState> emit) async {
    _emitSaving(emit);
    final result = await _addCost(
      AddCostParams(
        personId: event.personId,
        date: event.date,
        items: event.items,
      ),
    );
    await _afterMutation(emit, result, flagSaved: true);
  }

  Future<void> _onUpdate(CostUpdate event, Emitter<CostState> emit) async {
    _emitSaving(emit);
    final result = await _updateCost(
      UpdateCostParams(
        id: event.id,
        personId: event.personId,
        date: event.date,
        items: event.items,
      ),
    );
    await _afterMutation(emit, result, flagSaved: true);
  }

  Future<void> _onDelete(CostDelete event, Emitter<CostState> emit) async {
    _emitSaving(emit);
    final result = await _deleteCost(event.id);
    await _afterMutation(emit, result);
  }

  /// Loads the entry list and emits a loaded state.
  Future<void> _reload(Emitter<CostState> emit, {bool justSaved = false}) async {
    final result = await _getCosts(const NoParams());
    result.when(
      success: (s) => emit(_loaded(s.data, justSaved: justSaved)),
      failure: (f) => emit(CostState.error(f.error.toString())),
    );
  }

  /// Keeps current data visible while a mutation is in flight.
  void _emitSaving(Emitter<CostState> emit) {
    final current = state;
    if (current is CostLoaded) {
      emit(current.copyWith(saving: true, justSaved: false));
    }
  }

  /// On a failed mutation surface the error; otherwise reload the list.
  Future<void> _afterMutation(
    Emitter<CostState> emit,
    Result<dynamic> result, {
    bool flagSaved = false,
  }) async {
    if (result.isFailure) {
      emit(CostState.error(result.error.toString()));
      return;
    }
    await _reload(emit, justSaved: flagSaved);
  }

  CostState _loaded(List<CostEntity> costs, {bool justSaved = false}) =>
      CostState.loaded(
        costs: costs,
        members: _members,
        isAdmin: _isAdmin,
        justSaved: justSaved,
      );
}
