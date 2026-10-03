import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/features/membership/data/membership_api_service.dart';
import 'package:clean_boilerplate/features/membership/domain/entities/mess_details_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class MessDetailsState {
  const MessDetailsState();
}

/// The first load is running (nothing to show yet).
class MessDetailsLoading extends MessDetailsState {
  const MessDetailsLoading();
}

/// The mess is shown. [refreshing] / [leaving] flag a running reload or
/// leave, so the page shows progress and disables its actions meanwhile.
class MessDetailsLoaded extends MessDetailsState {
  const MessDetailsLoaded(this.mess, {this.refreshing = false, this.leaving = false});
  final MessDetailsEntity mess;
  final bool refreshing;
  final bool leaving;

  bool get busy => refreshing || leaving;
}

/// The first load failed, with the backend's reason.
class MessDetailsError extends MessDetailsState {
  const MessDetailsError(this.message);
  final String message;
}

/// The signed-in user's current mess: load, refresh and leave.
class MessDetailsCubit extends Cubit<MessDetailsState> {
  MessDetailsCubit(this._service) : super(const MessDetailsLoading());

  final MembershipApiService _service;

  Future<void> load() async {
    emit(const MessDetailsLoading());
    try {
      emit(MessDetailsLoaded(await _service.getMessDetails()));
    } catch (e) {
      emit(MessDetailsError(_message(e, 'Could not load your mess. Please try again.')));
    }
  }

  /// Reloads while keeping the page shown; returns the error message, if any.
  Future<String?> refresh() async {
    final current = state;
    if (current is! MessDetailsLoaded) {
      await load();
      return null;
    }
    if (current.busy) return null;
    emit(MessDetailsLoaded(current.mess, refreshing: true));
    try {
      emit(MessDetailsLoaded(await _service.getMessDetails()));
      return null;
    } catch (e) {
      emit(MessDetailsLoaded(current.mess));
      return _message(e, 'Could not refresh your mess. Please try again.');
    }
  }

  /// Leaves the mess. `left` is true once done; otherwise `error` says why
  /// (null when the tap was ignored because another action is running).
  Future<({bool left, String? error})> leave() async {
    final current = state;
    if (current is! MessDetailsLoaded || current.busy) return (left: false, error: null);
    emit(MessDetailsLoaded(current.mess, leaving: true));
    try {
      await _service.leaveMess();
      return (left: true, error: null);
    } catch (e) {
      emit(MessDetailsLoaded(current.mess));
      return (left: false, error: _message(e, 'Could not leave the mess. Please try again.'));
    }
  }

  /// Backend message when the API returned one, otherwise [fallback].
  String _message(Object error, String fallback) => switch (error) {
    ServerException(:final message) || NoInternetException(:final message) || RequestTimeoutException(:final message) || UnauthorizedException(:final message) => message,
    _ => fallback,
  };
}
