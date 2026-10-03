import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/failures.dart' as errors;
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/notice/domain/entities/notice_entity.dart';
import 'package:clean_boilerplate/features/notice/domain/usecases/notice_usecases.dart';
import 'package:clean_boilerplate/features/notice/presentation/bloc/notice_event.dart';
import 'package:clean_boilerplate/features/notice/presentation/bloc/notice_state.dart';

/// Notice BLoC — loads the notice list and runs publish / edit / pin / delete,
/// reloading the list after each change.
///
/// While a refresh or change runs the list stays on screen as `busy`. Each
/// action reports its outcome through the event's `done` completer.
@injectable
class NoticeBloc extends Bloc<NoticeEvent, NoticeState> {
  final GetNoticesUseCase _getNotices;
  final AddNoticeUseCase _addNotice;
  final UpdateNoticeUseCase _updateNotice;
  final SetNoticePinnedUseCase _setPinned;
  final DeleteNoticeUseCase _deleteNotice;

  bool _isAdmin = false;
  List<NoticeEntity> _notices = const [];

  /// The running refresh / change, if any; completes when it finishes.
  Completer<void>? _running;

  NoticeBloc(this._getNotices, this._addNotice, this._updateNotice, this._setPinned, this._deleteNotice) : super(const NoticeState.initial()) {
    on<NoticeStarted>(_onStarted);
    on<NoticeRefresh>(_onRefresh);
    on<NoticeAdd>(
      (event, emit) => _run(
        emit,
        () => _addNotice(AddNoticeParams(title: event.title, description: event.description)),
        done: event.done,
      ),
    );
    on<NoticeUpdate>(
      (event, emit) => _run(
        emit,
        () => _updateNotice(UpdateNoticeParams(id: event.id, title: event.title, description: event.description)),
        done: event.done,
      ),
    );
    on<NoticeTogglePin>(
      (event, emit) => _run(
        emit,
        () => _setPinned(SetNoticePinnedParams(id: event.id, pinned: event.pinned)),
        done: event.done,
      ),
    );
    on<NoticeDelete>((event, emit) => _run(emit, () => _deleteNotice(event.id), done: event.done));
  }

  Future<void> _onStarted(NoticeStarted event, Emitter<NoticeState> emit) async {
    _isAdmin = event.isAdmin;
    emit(const NoticeState.loading());

    final result = await _getNotices(const NoParams());
    result.when(
      success: (success) {
        _notices = success.data;
        _emitLoaded(emit);
      },
      failure: (failure) => emit(NoticeState.error(failure.error.toString())),
    );
  }

  /// A refresh during a running change just waits for it: that change
  /// reloads the list anyway.
  Future<void> _onRefresh(NoticeRefresh event, Emitter<NoticeState> emit) async {
    final running = _running;
    if (running != null) {
      await running.future;
      event.done?.complete(null);
      return;
    }
    await _run(emit, null, done: event.done);
  }

  /// Runs [action] (null for a plain refresh) and then reloads the list, with
  /// the list kept on screen as `busy` meanwhile.
  ///
  /// A change that arrives while another runs is dropped and its `done` never
  /// completes: the UI disables every action while busy, so this only catches
  /// a double tap, which must not send the change twice.
  Future<void> _run(Emitter<NoticeState> emit, ResultFuture<Object?> Function()? action, {Completer<errors.Failure?>? done}) async {
    if (_running != null || state is! NoticeLoaded) return;
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

  /// Reloads the list into [_notices]; returns the failure, if any.
  Future<errors.Failure?> _reload() async {
    final result = await _getNotices(const NoParams());
    return result.when(
      success: (success) {
        _notices = success.data;
        return null;
      },
      failure: (failure) => failure.error as errors.Failure,
    );
  }

  void _emitLoaded(Emitter<NoticeState> emit) => emit(NoticeState.loaded(notices: _notices, isAdmin: _isAdmin, busy: _running != null));
}
