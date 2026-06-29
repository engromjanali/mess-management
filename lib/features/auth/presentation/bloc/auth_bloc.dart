import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/login_usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/logout_usecase.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_event.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';

/// Auth BLoC - Handles authentication logic with Freezed
@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthBloc(this._loginUseCase, this._logoutUseCase, this._getCurrentUserUseCase) : super(const AuthState.initial()) {
    on<AuthEvent>(_onAuthEvent);
  }

  /// Handle all auth events using pattern matching
  Future<void> _onAuthEvent(AuthEvent event, Emitter<AuthState> emit) async {
    await event.when(loginRequested: (email, password) => _handleLogin(email, password, emit), logoutRequested: () => _handleLogout(emit), checkAuthStatus: () => _handleCheckAuthStatus(emit));
  }

  /// Handle login request
  Future<void> _handleLogin(String email, String password, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());

    final result = await _loginUseCase(LoginParams(email: email, password: password));

    result.when(success: (success) => emit(AuthState.authenticated(success.data)), failure: (failure) => emit(AuthState.error(failure.error.toString())));
  }

  /// Handle logout request
  Future<void> _handleLogout(Emitter<AuthState> emit) async {
    emit(const AuthState.loading());

    final result = await _logoutUseCase(const NoParams());

    result.when(success: (_) => emit(const AuthState.unauthenticated()), failure: (failure) => emit(AuthState.error(failure.error.toString())));
  }

  /// Check authentication status
  Future<void> _handleCheckAuthStatus(Emitter<AuthState> emit) async {
    emit(const AuthState.loading());

    final result = await _getCurrentUserUseCase(const NoParams());

    result.when(
      success: (success) {
        final user = success.data;
        if (user != null) {
          emit(AuthState.authenticated(user));
        } else {
          emit(const AuthState.unauthenticated());
        }
      },
      failure: (_) => emit(const AuthState.unauthenticated()),
    );
  }
}
