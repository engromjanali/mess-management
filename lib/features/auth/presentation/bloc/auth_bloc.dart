import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/auth/data/datasources/local/auth_local_data_source_impl.dart';
import 'package:mess_pilot/features/auth/data/models/user_model.dart';
import 'package:mess_pilot/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mess_pilot/features/auth/domain/usecases/google_login_usecase.dart';
import 'package:mess_pilot/features/auth/domain/usecases/login_usecase.dart';
import 'package:mess_pilot/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mess_pilot/features/auth/domain/usecases/register_usecase.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_event.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';

/// Auth BLoC - Handles authentication logic with Freezed
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final GoogleLoginUseCase _googleLoginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final AuthLocalDataSourceImpl _localDataSource = AuthLocalDataSourceImpl();

  AuthBloc(this._loginUseCase, this._googleLoginUseCase, this._registerUseCase, this._logoutUseCase, this._getCurrentUserUseCase) : super(const AuthState.initial()) {
    on<AuthEvent>(_onAuthEvent);
  }

  /// Handle all auth events using pattern matching
  Future<void> _onAuthEvent(AuthEvent event, Emitter<AuthState> emit) async {
    await event.when(
      loginRequested: (email, password) => _handleLogin(email, password, emit),
      googleLoginRequested: (idToken) => _handleGoogleLogin(idToken, emit),
      registerRequested: (fullName, email, password, phone) => _handleRegister(fullName, email, password, phone, emit),
      logoutRequested: () => _handleLogout(emit),
      checkAuthStatus: () => _handleCheckAuthStatus(emit),
      userUpdated: (user) async {
        _localDataSource.saveUser(UserModel.fromEntity(user));
        emit(AuthState.authenticated(user));
      },
      refreshProfileRequested: (done) async {
        try {
          await _handleRefreshProfile(emit);
          done.complete();
        } catch (error, stackTrace) {
          done.completeError(error, stackTrace);
        }
      },
    );
  }

  /// Handle login request
  Future<void> _handleLogin(String email, String password, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());

    final result = await _loginUseCase(LoginParams(email: email, password: password));

    result.when(
      success: (success) {
        _localDataSource.saveUser(UserModel.fromEntity(success.data));
        emit(AuthState.authenticated(success.data));
      },
      failure: (failure) => emit(AuthState.error(failure.message.toString())),
    );
  }

  /// Handle Google login request
  Future<void> _handleGoogleLogin(String idToken, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());

    final result = await _googleLoginUseCase(GoogleLoginParams(idToken: idToken));

    result.when(
      success: (success) {
        _localDataSource.saveUser(UserModel.fromEntity(success.data));
        emit(AuthState.authenticated(success.data));
      },
      failure: (failure) => emit(AuthState.error(failure.message.toString())),
    );
  }

  /// Handle register request (auto-signs the user in on success)
  Future<void> _handleRegister(String fullName, String email, String password, String? phone, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());

    final result = await _registerUseCase(RegisterParams(fullName: fullName, email: email, password: password, phone: phone));

    result.when(
      success: (success) {
        _localDataSource.saveUser(UserModel.fromEntity(success.data));
        emit(AuthState.authenticated(success.data));
      },
      failure: (failure) => emit(AuthState.error(failure.message.toString())),
    );
  }

  /// Handle logout request
  Future<void> _handleLogout(Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    _localDataSource.clearUser();

    final result = await _logoutUseCase(const NoParams());

    result.when(success: (_) => emit(const AuthState.unauthenticated()), failure: (failure) => emit(AuthState.error(failure.message.toString())));
  }

  Future<void> refreshProfile() {
    final done = Completer<void>();
    add(AuthEvent.refreshProfileRequested(done));
    return done.future;
  }

  Future<void> _handleRefreshProfile(Emitter<AuthState> emit) async {
    final userId = state.maybeWhen(authenticated: (user) => user.id, orElse: () => null);
    if (userId == null) return;
    final result = await _getCurrentUserUseCase(const NoParams());
    if (emit.isDone || state.maybeWhen(authenticated: (user) => user.id, orElse: () => null) != userId) return;
    result.when(
      success: (success) {
        if (success.data == null) {
          _localDataSource.clearUser();
          emit(const AuthState.unauthenticated());
        } else {
          _localDataSource.saveUser(UserModel.fromEntity(success.data!));
          emit(AuthState.authenticated(success.data!));
        }
      },
      failure: (failure) => throw failure.error,
    );
  }

  /// Check authentication status
  Future<void> _handleCheckAuthStatus(Emitter<AuthState> emit) async {
    final cached = _localDataSource.getCachedUser();
    final cachedEntity = cached?.toEntity();

    if (cachedEntity != null) {
      emit(AuthState.authenticated(cachedEntity));
    } else {
      emit(const AuthState.loading());
    }

    final result = await _getCurrentUserUseCase(const NoParams());

    result.when(
      success: (success) {
        final user = success.data;
        if (user != null) {
          _localDataSource.saveUser(UserModel.fromEntity(user));
          emit(AuthState.authenticated(user));
        } else {
          _localDataSource.clearUser();
          emit(const AuthState.unauthenticated());
        }
      },
      failure: (_) {
        if (cachedEntity == null) {
          emit(const AuthState.unauthenticated());
        }
      },
    );
  }
}
