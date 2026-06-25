import 'package:clean_boilerplate/config/util/result.dart';

/// Base class for all use cases
/// 
/// [Type] is the return type
/// [Params] is the input parameter type
abstract class UseCase<Type, Params> {
  ResultFuture<Type> call(Params params);
}

/// Use this class when use case doesn't need any parameters
class NoParams {
  const NoParams();
}
