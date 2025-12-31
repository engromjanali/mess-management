import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ফায়ারবেস ব্যাকগ্রাউন্ড মেসেজ হ্যান্ডলার
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('ব্যাকগ্রাউন্ড মেসেজ রিসিভড: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/call': (context) => CallScreen(),
      },
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
    _initializeLocalNotifications();
  }

  // ফায়ারবেস মেসেজিং ইনিশিয়ালাইজ
  Future<void> _initializeFirebaseMessaging() async {
    // নোটিফিকেশন পারমিশন রিকোয়েস্ট
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // ডিভাইস টোকেন পাওয়া
    String? token = await _firebaseMessaging.getToken();
    print('FCM টোকেন: $token');

    // ফোরগ্রাউন্ডে নোটিফিকেশন রিসিভ
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('ফোরগ্রাউন্ড মেসেজ রিসিভড: ${message.data}');
      _showLocalNotification(message);
      // স্বয়ংক্রিয়ভাবে কল স্ক্রিনে নেভিগেট
      if (message.data['screen'] == 'call') {
        navigatorKey.currentState?.pushNamed('/call');
      }
    });

    // ব্যাকগ্রাউন্ড বা টার্মিনেটেড থেকে নোটিফিকেশনে ট্যাপ করলে
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('নোটিফিকেশনে ট্যাপ করা হয়েছে: ${message.data}');
      if (message.data['screen'] == 'call') {
        navigatorKey.currentState?.pushNamed('/call');
      }
    });

    // অ্যাপ টার্মিনেটেড থেকে চালু হলে
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && initialMessage.data['screen'] == 'call') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamed('/call');
      });
    }
  }

  // লোকাল নোটিফিকেশন ইনিশিয়ালাইজ
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // নোটিফিকেশনে ট্যাপ করলে কল স্ক্রিনে নেভিগেট
        if (response.payload == 'call') {
          navigatorKey.currentState?.pushNamed('/call');
        }
      },
    );
  }

  // লোকাল নোটিফিকেশন দেখানো
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'call_channel',
      'Call Notifications',
      channelDescription: 'Notifications for incoming calls',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('ringtone'),
      fullScreenIntent: true, // ফুল-স্ক্রিন ইনটেন্ট সক্রিয়
      autoCancel: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'ইনকামিং কল',
      message.notification?.body ?? 'নতুন কল এসেছে!',
      platformChannelSpecifics,
      payload: message.data['screen'],
    );

    // স্বয়ংক্রিয়ভাবে কল স্ক্রিনে নেভিগেট (ফোরগ্রাউন্ড/ব্যাকগ্রাউন্ড)
    if (message.data['screen'] == 'call') {
      navigatorKey.currentState?.pushNamed('/call');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('হোম স্ক্রিন')),
      body: Center(
        child: Text('ইনকামিং কলের জন্য অপেক্ষা করুন...'),
      ),
    );
  }
}

class CallScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('কল স্ক্রিন')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ইনকামিং কল!'),
            ElevatedButton(
              onPressed: () {
                // কল গ্রহণ লজিক
              },
              child: Text('কল গ্রহণ করুন'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('কল বন্ধ করুন'),
            ),
          ],
        ),
      ),
    );
  }
}