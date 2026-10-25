import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/core/extensions/screen_matres_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResponsiveHelper {
  const ResponsiveHelper._();

  static const double smallMobile = 420;
  static const double mobile = 650;
  static const double smallTab = 850;
  static const double tab = Dimensions.webMaxWidth + 60;

  static bool isMobilePhone() => !kIsWeb;
  static bool isWeb() => kIsWeb;

  static bool isMobile(BuildContext context) => context.screenWidth <= mobile;
  static bool isSmallMobile(BuildContext context) => context.screenWidth <= smallMobile;
  static bool isBigMobile(BuildContext context) => context.screenWidth > smallMobile && context.screenWidth <= mobile;

  static bool isTab(BuildContext context) => context.screenWidth > mobile && context.screenWidth <= tab;
  static bool isSmallTab(BuildContext context) => context.screenWidth > mobile && context.screenWidth <= smallTab;
  static bool isBigTab(BuildContext context) => context.screenWidth > smallTab && context.screenWidth <= tab;

  static bool isDesktop(BuildContext context) => context.screenWidth > tab;
}
