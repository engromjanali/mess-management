import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/failures.dart' as errors;
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/season/domain/entities/season_overview_entity.dart';
import 'package:clean_boilerplate/features/season/domain/usecases/season_usecases.dart';
import 'package:clean_boilerplate/features/season/presentation/bloc/season_event.dart';
import 'package:clean_boilerplate/features/season/presentation/bloc/season_state.dart';

/// Season management BLoC — loads the mess's seasons and runs create / edit /
/// end / disable / switch / delete / auto-create changes, reloading after each.
///
/// While a refresh or change runs the list stays on screen as `busy`. Each
/// action reports its outcome through the event's `done` completer.
@injectable
class SeasonBloc extends Bloc<SeasonEvent, SeasonState> {
  final GetSeasonsUseCase _getSeasons;
  final CreateSeasonUseCase _createSeason;
  final UpdateSeasonUseCase _updateSeason;
  final EndSeasonUseCase _endSeason;
  final SetSeasonDisabledUseCase _setDisabled;
  final SwitchSeasonUseCase _switchSeason;
  final DeleteSeasonUseCase _deleteSeason;
  final UpdateAutoCreateSeasonUseCase _updateAutoCreate;

  SeasonOverviewEntity? _overview;

  /// The running refresh / change, if any; completes when it finishes.
  Completer<void>? _running;

  SeasonBloc(
    this._getSeasons,
    this._createSeason,
    this._updateSeason,
    this._endSeason,
    this._setDisabled,
    this._switchSeason,
    this._deleteSeason,
    this._updateAutoCreate,
  ) : super(const SeasonState.initial()) {
    on<SeasonStarted>(_onStarted);
    on<SeasonRefresh>(_onRefresh);
    on<SeasonCreate>(
      (event, emit) => _run(
        emit,
        () => _createSeason(CreateSeasonParams(name: event.name, startDate: event.startDate, sourceSeasonId: event.sourceSeasonId)),
        done: event.done,
      ),
    );
    on<SeasonUpdate>(
      (event, emit) => _run(
        emit,
        () => _updateSeason(UpdateSeasonParams(id: event.id, name: event.name, startDate: event.startDate, endDate: event.endDate)),
        done: event.done,
      ),
    );
    on<SeasonEnd>((event, emit) => _run(emit, () => _endSeason(event.id), done: event.done));
    on<SeasonSetDisabled>(
      (event, emit) => _run(emit, () => _setDisabled(SetSeasonDisabledParams(id: event.id, disabled: event.disabled)), done: event.done),
    );
    on<SeasonSwitchTo>((event, emit) => _run(emit, () => _switchSeason(event.id), done: event.done));
    on<SeasonDelete>((event, emit) => _run(emit, () => _deleteSeason(event.id), done: event.done));
    on<SeasonSetAutoCreate>(
      (event, emit) => _run(emit, () => _updateAutoCreate(UpdateAutoCreateSeasonParams(enabled: event.enabled, day: event.day)), done: event.done),
    );
  }

  Future<void> _onStarted(SeasonStarted event, Emitter<SeasonState> emit) async {
    emit(const SeasonState.loading());
    final failure = await _reload();
    if (failure != null) {
      emit(SeasonState.error(failure.message));
    } else {
      _emitLoaded(emit);
    }
  }

  /// A refresh during a running change just waits for it: that change
  /// reloads the list anyway.
  Future<void> _onRefresh(SeasonRefresh event, Emitter<SeasonState> emit) async {
    final running = _running;
    if (running != null) {
      await running.future;
      event.done?.complete(null);
      return;
    }
    await _run(emit, null, done: event.done);
  }

  /// Runs [action] (null for a plain refresh) and then reloads, with the list
  /// kept on screen as `busy` meanwhile.
  ///
  /// A change that arrives while another runs is dropped and its `done` never
  /// completes: the UI disables every action while busy, so this only catches
  /// a double tap, which must not send the change twice.
  Future<void> _run(Emitter<SeasonState> emit, ResultFuture<Object?> Function()? action, {Completer<errors.Failure?>? done}) async {
    if (_running != null || state is! SeasonLoaded) return;
    final running = _running = Completer<void>();
    _emitLoaded(emit);

    final failure = await _failureOf(action) ?? await _reload();
    _running = null;
    _emitLoaded(emit);
    running.complete();
    done?.complete(failure);
  }

  /// The failure of [action], or null when it succeeded (or there is none).
  Future<errors.Failure?> _failureOf(ResultFuture<Object?> Function()? action) async {
    if (action == null) return null;
    final result = await action();
    return result.when(success: (_) => null, failure: (failure) => failure.error as errors.Failure);
  }

  /// Reloads into [_overview]; returns the failure, if any.
  Future<errors.Failure?> _reload() async {
    final result = await _getSeasons(const NoParams());
    return result.when(
      success: (success) {
        _overview = success.data;
        return null;
      },
      failure: (failure) => failure.error as errors.Failure,
    );
  }

  void _emitLoaded(Emitter<SeasonState> emit) => emit(SeasonState.loaded(overview: _overview!, busy: _running != null));
}
