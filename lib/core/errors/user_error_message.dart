import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';

String userErrorMessage(Object error, AppLocalizations local) {
  if (error is RequestTimeoutException) return local.requestTimedOut;
  if (error is NoInternetException || error is NetworkException) return local.connectionFailed;
  final status = error is Failure ? error.statusCode : error is ServerException ? error.statusCode : error is UnauthorizedException ? error.statusCode : null;
  if (status == 401) return local.signInAgain;
  if (status == 403) return local.actionNotAllowed;
  if (status != null && status >= 500) return local.serviceUnavailable;
  final message = switch (error) {
    Failure(:final message) || ServerException(:final message) || UnauthorizedException(:final message) => message,
    String() => error,
    _ => '',
  };
  final normalized = message.trim().toLowerCase();
  if (normalized.startsWith('server error')) return local.serviceUnavailable;
  if (normalized == 'forbidden' || normalized == 'permission denied' || normalized == 'you do not have permission to perform this action.') return local.actionNotAllowed;
  if (normalized.contains('timeout') || normalized.contains('timed out') || normalized.startsWith('request took too long')) return local.requestTimedOut;
  if (error is NetworkFailure || normalized.contains('no internet') || normalized.contains('network error') || normalized.contains('connection error') || normalized.contains('failed host lookup') || normalized.contains('socketexception')) return local.connectionFailed;
  if (normalized == 'unauthorized access' || normalized == 'authentication credentials were not provided.' || normalized == 'given token not valid for any token type' || normalized == 'your session has expired. please sign in again.') return local.signInAgain;
  if (normalized.isEmpty || normalized == 'an error occurred' || normalized.startsWith('server error') || normalized.startsWith('an unexpected error occurred') || normalized.startsWith('something went wrong') || normalized.contains('dioexception') || normalized.contains('typeerror') || normalized.contains('stack trace') || normalized.contains('traceback') || normalized.contains('<html') || normalized.contains('<!doctype') || normalized.contains('instance of ') || normalized.contains('exception:') || normalized.contains('authorization:') || normalized.contains('bearer ') || normalized.contains('access_token') || normalized.contains('refresh_token')) return local.actionFailed;
  return message.trim();
}
