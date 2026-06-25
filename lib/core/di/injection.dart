import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/core/di/injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  preferRelativeImports: true,
)
Future<void> configureDependencies() async => getIt.init();
