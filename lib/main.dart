import 'dart:io';

import 'package:flutter/material.dart';
import 'package:raincheck/pages/friends_page.dart';
import 'package:raincheck/pages/notification_page.dart';
import 'package:raincheck/pages/planner_page.dart';
import 'package:raincheck/service/notification_service.dart';
import 'helper/calendar_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:raincheck/pages/plans_page.dart';

import 'pages/auth/login_page.dart';
import 'firebase_options.dart';
import 'helper/helper_function.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //Check if user is using android or ios

  if (Platform.isAndroid) {
    await NotificationService().initNotifications();
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isSignedIn = false;

  checkPermissions() async {
    bool permission = await CalendarFunctions.checkPermission();
    if (!permission) {
      bool permissionGranted = await CalendarFunctions.requestPermission();
      if (!permissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Permission not granted"),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserLoggedInStatus();

    checkPermissions();
    print("init state");
  }

  getUserLoggedInStatus() async {
    await HelperFunctions.getUserLoggedInStatus().then((value) {
      if (value != null) {
        setState(() {
          _isSignedIn = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raincheck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: _isSignedIn ? const PlannerPage() : const LoginPage(),
      navigatorKey: navigatorKey,
      routes: {
        NotificationPage.route: (context) => const NotificationPage(),
        FriendsPage.route: (context) => const FriendsPage(),
      },
    );
  }
}
