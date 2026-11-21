import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/errors/failures.dart' as errors;
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';
import 'package:mess_pilot/features/poll/domain/usecases/poll_usecases.dart';
import 'package:mess_pilot/features/poll/presentation/bloc/poll_event.dart';
import 'package:mess_pilot/features/poll/presentation/bloc/poll_state.dart';

/// Loads the poll list and runs create / edit / vote / close / delete actions,
/// reloading the list after each change.
@injectable
class PollBloc extends Bloc<PollEvent, PollState> {
  PollBloc(
    this._getPolls,
    this._createPoll,
    this._updatePoll,
    this._votePoll,
    this._withdrawVote,
    this._setClosed,
    this._deletePoll,
  ) : super(const PollState.initial()) {
    on<PollStarted>(_onStarted);
    on<PollRefresh>(_onRefresh);
    on<PollCreate>((event, emit) => _run(emit, () => _createPoll(event.draft), done: event.done));
    on<PollUpdate>((event, emit) => _run(
          emit,
          () => _updatePoll(UpdatePollParams(id: event.id, draft: event.draft, updateOptions: event.updateOptions)),
          done: event.done,
        ));
    on<PollVote>((event, emit) => _run(
          emit,
          () => _votePoll(VotePollParams(id: event.id, optionIds: event.optionIds)),
          done: event.done,
        ));
    on<PollWithdrawVote>((event, emit) => _run(emit, () => _withdrawVote(event.id), done: event.done));
    on<PollToggleClosed>((event, emit) => _run(
          emit,
          () => _setClosed(SetPollClosedParams(id: event.id, closed: event.closed)),
          done: event.done,
        ));
    on<PollDelete>((event, emit) => _run(emit, () => _deletePoll(event.id), done: event.done));
  }

  final GetPollsUseCase _getPolls;
  final CreatePollUseCase _createPoll;
  final UpdatePollUseCase _updatePoll;
  final VotePollUseCase _votePoll;
  final WithdrawPollVoteUseCase _withdrawVote;
  final SetPollClosedUseCase _setClosed;
  final DeletePollUseCase _deletePoll;

  List<PollEntity> _polls = const [];
  bool _canManage = false;
  Completer<void>? _running;

  Future<void> _onStarted(PollStarted event, Emitter<PollState> emit) async {
    emit(const PollState.loading());
    await _reload();
    final failure = _lastFailure;
    if (failure != null) {
      emit(PollState.error(failure.message));
      return;
    }
    _emitLoaded(emit);
  }

  Future<void> _onRefresh(PollRefresh event, Emitter<PollState> emit) async {
    final running = _running;
    if (running != null) {
      await running.future;
      event.done?.complete(null);
      return;
    }
    await _run(emit, null, done: event.done);
  }

  Future<void> _run(Emitter<PollState> emit, ResultFuture<Object?> Function()? action, {Completer<errors.Failure?>? done}) async {
    if (_running != null || state is! PollLoaded) return;
    final running = _running = Completer<void>();
    _emitLoaded(emit);

    final failure = await _failureOf(action) ?? await _reload();
    _running = null;
    _emitLoaded(emit);
    running.complete();
    done?.complete(failure);
  }

  Future<errors.Failure?> _failureOf(ResultFuture<Object?> Function()? action) async {
    if (action == null) return null;
    final result = await action();
    return result.when(success: (_) => null, failure: (failure) => failure.error as errors.Failure);
  }

  errors.Failure? _lastFailure;

  Future<errors.Failure?> _reload() async {
    final polls = <PollEntity>[];
    var canManage = false;
    var page = 1;
    _lastFailure = null;

    // The list has no "load more" UI, so follow the pages and keep every poll.
    // This also guarantees a poll opened from a deep link is present in state.
    for (var guard = 0; guard < 50; guard++) {
      final result = await _getPolls(GetPollsParams(page: page));
      final nextPage = await result.when(
        success: (success) async {
          polls.addAll(success.data.polls);
          canManage = success.data.canManage;
          final next = success.data.nextPage;
          return next != null && next > page ? next : null;
        },
        failure: (failure) async {
          _lastFailure = failure.error as errors.Failure;
          return null;
        },
      );
      if (_lastFailure != null) return _lastFailure;
      if (nextPage == null) break;
      page = nextPage;
    }

    _polls = polls;
    _canManage = canManage;
    return _lastFailure = null;
  }

  void _emitLoaded(Emitter<PollState> emit) => emit(PollState.loaded(polls: _polls, canManage: _canManage, busy: _running != null));
}
