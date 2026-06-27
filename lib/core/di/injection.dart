import 'package:clean_boilerplate/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/core/di/injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(preferRelativeImports: true)
Future<void> configureDependencies() async {
  await Firebase.initializeApp(  
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await getIt.init();
}
