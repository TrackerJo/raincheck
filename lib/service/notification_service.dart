import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:raincheck/main.dart';
import 'package:raincheck/pages/friends_page.dart';

import '../pages/notification_page.dart';
import 'package:http/http.dart' as http;

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
}

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;

  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  final _localNotifications = FlutterLocalNotificationsPlugin();

  void handleMessage(RemoteMessage? message) {
    print("HANDLE MESSAGE");
    if (message == null) return;
    print(message);

    if (message.data['id'] == 'friendRequest') {
      print("Friend Request");
      navigatorKey.currentState
          ?.pushNamed(FriendsPage.route, arguments: message);
      return;
    }
    navigatorKey.currentState
        ?.pushNamed(NotificationPage.route, arguments: message);
  }

  Future initLocalNotifications() async {
    const iOS = DarwinInitializationSettings();
    const android = AndroidInitializationSettings('@drawable/ic_launcher');
    const settings = InitializationSettings(iOS: iOS, android: android);

    await _localNotifications.initialize(settings,
        onDidReceiveNotificationResponse: (payload) async {
      print("PAYLOAD: ${payload.payload}");
      if (payload.payload == null) return;

      final message = RemoteMessage.fromMap(jsonDecode(payload.payload!));

      handleMessage(message);
    });

    final platform = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()!;
    await platform.createNotificationChannel(_androidChannel);
  }

  Future initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: _androidChannel.importance,
              icon: '@drawable/ic_launcher',
            ),
          ),
          payload: jsonEncode(message.toMap()));
    });
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    print(fCMToken);
    initPushNotifications();
    initLocalNotifications();
  }

  Future<String> getFCMToken() async {
    String? fCMToken = "";
    //Check if andriod
    if (Platform.isAndroid) {
      fCMToken = await _firebaseMessaging.getToken();
    }

    print(fCMToken);
    return fCMToken!;
  }

  Future sendNotificationToDevice(String token, String title, String bodyText,
      String notificationId) async {
    try {
      final body = {
        "to": token,
        "notification": {"title": title, "body": bodyText},
        "data": {"id": notificationId}
      };
      print(body);

      var response =
          await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                HttpHeaders.authorizationHeader:
                    'key=AAAA004-CYg:APA91bGBygw_6Xqda9KQXSMylyyvzvcoJYV0Orl0qUhJMnOCqjwyHFYJ2yREemEwnJZc-PlisvheHmsAnRJWfwch9g9BP-2rZrpGQH1Bu4YPwsQGyqwa8SbfwstZdt_bmVBNyBfMPphr'
              },
              body: jsonEncode(body));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    } on Exception catch (e) {
      print("Error: $e");
    }
  }
}
