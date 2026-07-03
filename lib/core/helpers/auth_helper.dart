import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  const AuthHelper._();

  static bool isLogin() {
    final token = getIt<SharedPreferences>().getString(AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }
}
