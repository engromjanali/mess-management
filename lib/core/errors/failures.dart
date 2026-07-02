/// Base class for all failures in the application
abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});
}

/// Server failure
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Network failure
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}

/// Authentication failure
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message, super.statusCode});
}