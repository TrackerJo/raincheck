import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});
  static const route = '/notification-page';

  @override
  Widget build(BuildContext context) {
    final message =
        ModalRoute.of(context)!.settings.arguments as RemoteMessage?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Title: ${message!.notification?.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Body: ${message.notification?.body}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Data: ${message.data}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
