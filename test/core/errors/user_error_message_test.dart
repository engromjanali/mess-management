import 'package:clean_boilerplate/core/errors/error_handler.dart';
import 'package:clean_boilerplate/core/errors/exceptions.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';
import 'package:clean_boilerplate/core/errors/user_error_message.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final language in ['en', 'bn', 'ar']) {
    final local = lookupAppLocalizations(Locale(language));
    test('Common errors are localized in $language', () {
      expect(userErrorMessage(NoInternetException(message: 'SocketException: private host'), local), local.connectionFailed);
      expect(userErrorMessage(RequestTimeoutException(message: 'debug timeout'), local), local.requestTimedOut);
      expect(userErrorMessage(const NetworkFailure(message: 'Request timeout. Please try again.'), local), local.requestTimedOut);
      expect(userErrorMessage(UnauthorizedException(message: 'private token'), local), local.signInAgain);
      expect(userErrorMessage(const ServerFailure(message: 'private query', statusCode: 403), local), local.actionNotAllowed);
      expect(userErrorMessage(ServerException(message: 'private query', statusCode: 500), local), local.serviceUnavailable);
      expect(userErrorMessage('Server error. Please try again later.', local), local.serviceUnavailable);
    });
    test('Validation messages stay useful and technical details stay hidden in $language', () {
      expect(userErrorMessage(const ValidationFailure(message: 'Please select a member.'), local), 'Please select a member.');
      expect(userErrorMessage(ServerException(message: 'This invitation has expired.', statusCode: 400), local), 'This invitation has expired.');
      for (final error in [Exception('private query'), 'DioException: secret', 'Traceback: private query', '<html>secret</html>', 'Authorization: Bearer secret', 'access_token=secret', 'An unexpected error occurred: secret']) {
        expect(userErrorMessage(error, local), local.actionFailed);
      }
    });
  }

  test('Failure mapping keeps field errors without leaking unexpected exceptions', () {
    final failure = mapErrorToFailure(ServerException(message: 'Invalid details.', statusCode: 400, fieldErrors: {'email': 'Enter a valid email address.'})) as ServerFailure;
    expect(failure.fieldErrors, {'email': 'Enter a valid email address.'});
    expect(mapErrorToFailure(Exception('PRIVATE_SERVER_TRACE')).message, 'Something went wrong. Please try again.');
  });

  test('HTTP server errors and HTML authentication responses are safe', () {
    final options = RequestOptions(path: '/example');
    final server = DioException(requestOptions: options, type: DioExceptionType.badResponse, response: Response(requestOptions: options, statusCode: 500, data: {'message': 'PRIVATE_SERVER_TRACE', 'email': ['private error']})).toAppException() as ServerException;
    expect(server.message, 'Server error. Please try again later.');
    expect(server.fieldErrors, isEmpty);
    final unauthorized = DioException(requestOptions: options, type: DioExceptionType.badResponse, response: Response(requestOptions: options, statusCode: 401, data: '<html>secret</html>')).toAppException() as UnauthorizedException;
    expect(unauthorized.message, 'Your session has expired. Please sign in again.');
  });
}
