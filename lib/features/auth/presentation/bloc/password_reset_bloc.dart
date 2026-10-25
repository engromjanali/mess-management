import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:clean_boilerplate/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/password_reset_event.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/password_reset_state.dart';

/// Drives the two-step forgot-password flow: request an OTP, then reset the
/// password with that OTP.
@injectable
class PasswordResetBloc extends Bloc<PasswordResetEvent, PasswordResetState> {
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  PasswordResetBloc(this._forgotPasswordUseCase, this._resetPasswordUseCase) : super(const PasswordResetState.initial()) {
    on<PasswordResetEvent>(_onEvent);
  }

  Future<void> _onEvent(PasswordResetEvent event, Emitter<PasswordResetState> emit) async {
    await event.when(
      otpRequested: (email) => _handleOtpRequested(email, emit),
      passwordSubmitted: (email, otp, password) => _handlePasswordSubmitted(email, otp, password, emit),
      restarted: () async => emit(const PasswordResetState.initial()),
    );
  }

  Future<void> _handleOtpRequested(String email, Emitter<PasswordResetState> emit) async {
    emit(const PasswordResetState.loading());

    final result = await _forgotPasswordUseCase(email);

    result.when(
      success: (_) => emit(PasswordResetState.otpSent(email)),
      failure: (failure) => emit(PasswordResetState.error(failure.error.toString())),
    );
  }

  Future<void> _handlePasswordSubmitted(String email, String otp, String password, Emitter<PasswordResetState> emit) async {
    emit(const PasswordResetState.loading());

    final result = await _resetPasswordUseCase(ResetPasswordParams(email: email, otp: otp, password: password));

    result.when(
      success: (_) => emit(const PasswordResetState.success()),
      failure: (failure) => emit(PasswordResetState.error(failure.error.toString(), email: email)),
    );
  }
}
