import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../config/util/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/notice_entity.dart';
import '../../domain/usecases/notice_usecases.dart';
import 'notice_event.dart';
import 'notice_state.dart';

/// Notice BLoC — loads the notice list and applies add / update / delete
/// mutations, reloading the list afterwards.
@injectable
class NoticeBloc extends Bloc<NoticeEvent, NoticeState> {
  final GetNoticesUseCase _getNotices;
  final AddNoticeUseCase _addNotice;
  final UpdateNoticeUseCase _updateNotice;
  final DeleteNoticeUseCase _deleteNotice;

  bool _isAdmin = false;

  NoticeBloc(
    this._getNotices,
    this._addNotice,
    this._updateNotice,
    this._deleteNotice,
  ) : super(const NoticeState.initial()) {
    on<NoticeStarted>(_onStarted);
    on<NoticeRefresh>(_onRefresh);
    on<NoticeAdd>(_onAdd);
    on<NoticeUpdate>(_onUpdate);
    on<NoticeDelete>(_onDelete);
  }

  Future<void> _onStarted(
    NoticeStarted event,
    Emitter<NoticeState> emit,
  ) async {
    _isAdmin = event.isAdmin;
    emit(const NoticeState.loading());
    await _reload(emit);
  }

  Future<void> _onRefresh(
    NoticeRefresh event,
    Emitter<NoticeState> emit,
  ) async {
    await _reload(emit);
  }

  Future<void> _onAdd(NoticeAdd event, Emitter<NoticeState> emit) async {
    _emitSaving(emit);
    final result = await _addNotice(
      AddNoticeParams(title: event.title, description: event.description),
    );
    await _afterMutation(emit, result);
  }

  Future<void> _onUpdate(NoticeUpdate event, Emitter<NoticeState> emit) async {
    _emitSaving(emit);
    final result = await _updateNotice(
      UpdateNoticeParams(
        id: event.id,
        title: event.title,
        description: event.description,
      ),
    );
    await _afterMutation(emit, result);
  }

  Future<void> _onDelete(NoticeDelete event, Emitter<NoticeState> emit) async {
    _emitSaving(emit);
    final result = await _deleteNotice(event.id);
    await _afterMutation(emit, result);
  }

  /// Loads the notice list and emits a loaded state.
  Future<void> _reload(Emitter<NoticeState> emit) async {
    final result = await _getNotices(const NoParams());
    result.when(
      success: (s) => emit(_loaded(s.data)),
      failure: (f) => emit(NoticeState.error(f.error.toString())),
    );
  }

  /// Keeps current data visible while a mutation is in flight.
  void _emitSaving(Emitter<NoticeState> emit) {
    final current = state;
    if (current is NoticeLoaded) {
      emit(current.copyWith(saving: true));
    }
  }

  /// On a failed mutation surface the error; otherwise reload the list.
  Future<void> _afterMutation(
    Emitter<NoticeState> emit,
    Result<dynamic> result,
  ) async {
    if (result.isFailure) {
      emit(NoticeState.error(result.error.toString()));
      return;
    }
    await _reload(emit);
  }

  NoticeState _loaded(List<NoticeEntity> notices) =>
      NoticeState.loaded(notices: notices, isAdmin: _isAdmin);
}
