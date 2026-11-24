import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/errors/failures.dart' as errors;
import 'package:mess_pilot/features/meal/domain/entities/meal_request_entity.dart';
import 'package:mess_pilot/features/meal/domain/repositories/meal_request_repository.dart';
import 'package:mess_pilot/features/meal/presentation/bloc/meal_request_event.dart';
import 'package:mess_pilot/features/meal/presentation/bloc/meal_request_state.dart';

@injectable
class MealRequestBloc extends Bloc<MealRequestEvent, MealRequestState> {
  MealRequestBloc(this._repository) : super(const MealRequestInitial()) {
    on<MealRequestLoad>(_load);
    on<MealRequestCreate>(_create);
    on<MealRequestUpdate>(_update);
    on<MealRequestDelete>(_delete);
    on<MealRequestClose>(_close);
    on<MealRequestReopen>(_reopen);
    on<MealRequestSelect>(_select);
  }

  final MealRequestRepository _repository;
  MealRequestOverviewEntity? _overview;
  bool _busy = false;

  Future<void> _load(MealRequestLoad event, Emitter<MealRequestState> emit) async {
    emit(const MealRequestLoading());
    final result = await _repository.getRequests();
    result.when(
      success: (success) {
        _overview = success.data;
        emit(MealRequestLoaded(overview: success.data));
      },
      failure: (failure) => emit(MealRequestError(failure.error.toString())),
    );
  }

  Future<void> _create(MealRequestCreate event, Emitter<MealRequestState> emit) async {
    await _run(emit, event.done, () => _repository.createRequest(event.draft));
  }

  Future<void> _update(MealRequestUpdate event, Emitter<MealRequestState> emit) async {
    await _run(emit, event.done, () => _repository.updateRequest(id: event.id, draft: event.draft));
  }

  Future<void> _delete(MealRequestDelete event, Emitter<MealRequestState> emit) async {
    await _run(emit, event.done, () => _repository.deleteRequest(event.id));
  }

  Future<void> _close(MealRequestClose event, Emitter<MealRequestState> emit) async {
    await _run(emit, event.done, () => _repository.closeRequest(event.id));
  }

  Future<void> _reopen(MealRequestReopen event, Emitter<MealRequestState> emit) async {
    await _run(emit, event.done, () => _repository.reopenRequest(event.id));
  }

  Future<void> _select(MealRequestSelect event, Emitter<MealRequestState> emit) async {
    await _run(
      emit,
      event.done,
      () => _repository.saveSelection(id: event.id, breakfast: event.breakfast, lunch: event.lunch, dinner: event.dinner),
    );
  }

  Future<void> _run(Emitter<MealRequestState> emit, Completer<errors.Failure?>? done, ResultFuture<void> Function() action) async {
    if (_busy) {
      done?.complete(null);
      return;
    }
    _busy = true;
    final current = _overview;
    if (current != null) emit(MealRequestLoaded(overview: current, busy: true));

    final result = await action();
    final failure = result.onFailure((value) => value.error as errors.Failure);
    if (failure == null) {
      final refreshed = await _repository.getRequests();
      refreshed.when(
        success: (success) => _overview = success.data,
        failure: (_) {},
      );
    }
    _busy = false;
    final latest = _overview;
    if (latest != null) emit(MealRequestLoaded(overview: latest));
    done?.complete(failure);
  }
}
