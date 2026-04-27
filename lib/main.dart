import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mess_management/authantication/Sign_up.dart';
import 'package:mess_management/authantication/landing_screen.dart';
import 'package:mess_management/authantication/sign_in.dart';
import 'package:mess_management/constants.dart';
import 'package:mess_management/firebase_options.dart';
import 'package:mess_management/home.dart';
import 'package:flutter/material.dart';
import 'package:mess_management/notice_and_announcement.dart';
import 'package:mess_management/providers/authantication_provider.dart';
import 'package:mess_management/providers/bazer_provider.dart';
import 'package:mess_management/providers/deposit_provider.dart';
import 'package:mess_management/providers/fund_provider.dart';
import 'package:mess_management/providers/firstScreen_provider.dart';
import 'package:mess_management/providers/meal_provider.dart';
import 'package:mess_management/providers/mess_provider.dart';
import 'package:mess_management/providers/notice_provider.dart';
import 'package:mess_management/providers/testProvider.dart';
import 'package:mess_management/services/notification_services.dart';
import 'package:provider/provider.dart';

// void main() {
//   runApp(const MyApp());
// }

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHendler);

  runApp(
    MultiProvider(
      providers: [
        // add all provider here
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
        ChangeNotifierProvider(create: (_) => FirstScreenProvider()),
        ChangeNotifierProvider(create: (_) => Testprovider()),
        ChangeNotifierProvider(create: (_) => FundProvider()),
        ChangeNotifierProvider(create: (_) => DepositProvider()),
        ChangeNotifierProvider(create: (_) => MealProvider()),
        ChangeNotifierProvider(create: (_) => BazerProvider()),
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (_) => MessProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// system tray এ notification দেখাবে। যদি data payload থাকে,
/// তাহলে _firebaseMessagingBackgroundHandler trigger হবে।
/// we can show it in local notification,
/// we can done some opration from here also.

@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHendler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Message Received ---");

  // if app is "terminated, backgrounded" this function will triggered for (notification receive).
  // for local notification (receive and open/close) behave normal mean won't trigger .
  if (message.notification == null) {
    debugPrint("silent message received we can synce data, or so some special opration.");
    debugPrint("silent message dosen't show in status tray by OS by default");

    NotificationServices.getInstance.showNotification(
      RemoteMessage(
        notification: RemoteNotification(
          title: "without notification field",
          body: "",
        ),
      ),
    );
  }

  // in here we can perform light weight opration like store/update few data locally.
  // for 20-30 second.
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      navigatorKey: navigatorKey,
      // home:  TestScreen(),
      initialRoute: Constants.LandingScreen,
      // home: MyVideoUI(),
      routes: {
        Constants.LandingScreen: (context) => const LandingScreen(),
        Constants.HomeScreen: (context) => const HomeScreen(),
        Constants.logInScreen: (context) => const SignInScreen(),
        Constants.SignUpScreen: (context) => const SignUpScreen(),
        Constants.noticeScreen:
            (context) => const NoticeAndAnnouncementScreen(),
      },
    );
  }
}