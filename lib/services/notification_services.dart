import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:app_settings/app_settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mess_management/constants.dart';
import 'package:mess_management/core/function/f_is_null.dart';
import 'package:mess_management/main.dart';
import 'package:mess_management/model/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:mess_management/providers/authantication_provider.dart';

class NotificationServices {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? fcmServerKey;
  UserModel? _usermodel;

  static final NotificationServices getInstance = NotificationServices._();

  NotificationServices._() {
    // checkDeviceTockenHasChanged();
    // FmcServerKey().getServerTockenFCM().then((token){
    //   fcmServerKey = token;
    // });
    // if(authProvider.getUserModel!.deviceId==null){
    //   getDeviceToken((_){});
    // }

    // getUserInfo();
    initLocalNotifications();
    setupInterectMessage();
    firebaseMessageInit();
    setForgroundMessagingOptions();
  }

  void initLocalNotifications() async {
    const androidInitializationSettings = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosInitializationSettings = const DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (paylod) {
        // when i click to notification this function or "onDidReceiveNotificationResponse" will be called.
        navigateOnNoticeScreen();
      },
    );
  }

  Future<void> sendMessage({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final projectId = "mess-management-b82d9";
    debugPrint("DeviceToken: ${deviceToken}");
    debugPrint("server token: $fcmServerKey");

    final responce = await http.post(
      Uri.parse(
        "https://fcm.googleapis.com/v1/projects/$projectId/messages:send",
      ),
      headers: <String, String>{
        "Content-Type": "application/json",
        "Authorization": "Bearer $fcmServerKey",
      },
      body: jsonEncode(<String, dynamic>{
        "message": {
          "token": deviceToken,
          "notification": {"title": title, "body": body},
          "data": data,
        },
      }),
    );

    debugPrint("status code ${responce.statusCode.toString()}");
  }

  Future<void> setupInterectMessage() async {
    // when app is terminited
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("terminited----------");
      navigateOnNoticeScreen();
    }

    // when app is background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("background----------");
      navigateOnNoticeScreen();
    });
  }

  Future<void> firebaseMessageInit() async {
    // when foreground, for background see setupInterectMessage Function
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(message.notification?.title.toString());
      debugPrint(message.notification?.body.toString());
      debugPrint(message.senderId.toString());
      debugPrint(message.sentTime.toString());
      debugPrint(message.from.toString());
      debugPrint(message.messageId.toString());
      debugPrint(message.messageType.toString());

      if (message.notification != null) {
        // in here android opration are not work for ios that's why we have write code as depand on platform.
        if (Platform.isAndroid) {
          // initLocalNotifications(context: context, message: message);
          showNotification(message);
        }
        if (Platform.isIOS) {
          // iOS shows system notification automatically; handle data-only payloads
          setForgroundMessagingOptions();
          if (message.notification == null && message.data.isNotEmpty) {
            showNotification(message);
          }
        }
      } else {
        // we receive a notification what dose not contain notification field.
        // if we want we can perform some opration.
      }
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    debugPrint("called showNotification");
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      Random.secure().nextInt(100000).toString(),
      'High Importance Notification',
      importance: Importance.max,
    );

    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          channel.id.toString(),
          channel.name.toString(),
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          icon: '@mipmap/launcher_icon', // required otherwise we get an error.
        );

    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    Future.delayed(Duration.zero, () {
      _flutterLocalNotificationsPlugin.show(
        message.notification.hashCode,
        message.notification?.title ?? "Notification",
        message.notification?.body ?? "You have a new message",
        notificationDetails,
        payload: json.encode(message.data),
      );
    });
  }

  void openAppSettings() async {
    if (Platform.isAndroid) {
      await AppSettings.openAppSettings(
        type:
            AppSettingsType
                .notification, // android navigate to notification permision page.
        asAnotherTask: true,
      );
    }
    // reopen to check has permision or not.
  }

  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true, // show notificition on display
      announcement: true, // siri can't read for false,
      badge: true, // to show index
      carPlay: true, //
      criticalAlert: true,
      // provisional: true, //Note that on iOS, if [provisional] is set to true, silent notification permissions will be automatically granted. When notifications are delivered to the device, the user will be presented with an option to disable notifications, keep receiving them silently or enable prominent notifications.
      sound: true,
      providesAppNotificationSettings: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('⚠️ User granted provisional permission');
    } else {
      debugPrint("❌ User declined permission");
      openAppSettings();
    }
  }

  // for ios semolator we have to
  Future<String> getDeviceToken(
    Function(String) onFail,
    AuthenticationProvider authProvider,
  ) async {
    String? deviceToken;
    try {
      // // for web
      // final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      // deviceToken =  await messaging.getToken(vapidKey: apnsToken);

      // for ios or android
      deviceToken = await messaging.getToken();

      await authProvider.setDeviceToken(deviceToken);
    } catch (e) {
      onFail(e.toString());
      debugPrint(e.toString());
    }
    return deviceToken ?? "";
  }

  // check device token has changed or not
  void checkDeviceTockenHasChanged(AuthenticationProvider authProvider) {
    messaging.onTokenRefresh
        .listen((fcmToken) {
          // Note: This callback is fired at each app startup and whenever a new
          // token is generated.
          debugPrint("device token has changed (new token) : $fcmToken");

          // save device/fcm tocken in firebase firestore
          getDeviceToken((_) {}, authProvider);
        })
        .onError((err) {
          debugPrint("Error \'checkDeviceTockenHasChanged\' : $err");
        });
  }

  void navigateOnNoticeScreen() {
    navigatorKey.currentState?.pushNamed(Constants.noticeScreen);
  }

  Future setForgroundMessagingOptions() async {
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: false,
    );
  }
}

/// system tray এ notification দেখাবে। যদি data payload থাকে,
/// তাহলে _firebaseMessagingBackgroundHandler trigger হবে।
/// we can show it in local notification,
/// we can done some opration from here also.

@pragma("vm:entry-point")
Future<void> firebaseMessagingBackgroundHendler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Message Received ---");

  // if app is "terminated, backgrounded" this function will triggered for (notification receive).
  // if the app is in backgrounded i receive a notification and remove/clear the notification this function will be triger again. with a null map-data demo given below
  // {senderId: null, category: null, collapseKey: null, contentAvailable: false, data: {}, from: null, messageId: null, messageType: null, mutableContent: false, notification: null, sentTime: 0, threadId: null, ttl: 0}
  // for local notification (receive and open/close) behave normal mean won't trigger .
  if (isNull(message.notification) && isNotNull(message.senderId)) {
    debugPrint(
      "silent message received we can synce data, or so some special opration.",
    );
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
