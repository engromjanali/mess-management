import 'package:mess_pilot/config/util/app_constants.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  const AuthHelper._();

  static bool isLogin() {
    final token = getIt<SharedPreferences>().getString(AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }
}
