import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:raincheck/widgets/widgets.dart';

import '../pages/profile_page.dart';
import '../service/database_service.dart';

class PendingFriendRequestTile extends StatefulWidget {
  final String displayName;
  final String userId;
  final String username;

  const PendingFriendRequestTile({
    super.key,
    required this.displayName,
    required this.userId,
    required this.username,
  });

  @override
  State<PendingFriendRequestTile> createState() =>
      _PendingFriendRequestTileState();
}

class _PendingFriendRequestTileState extends State<PendingFriendRequestTile> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: ListTile(
        onTap: () {
          nextScreen(
              context,
              ProfilePage(
                uid: widget.userId,
              ));
        },
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(widget.displayName.substring(0, 1).toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 30)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                onPressed: () {
                  DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
                      .acceptFriendRequest(
                          widget.userId, widget.username, widget.displayName);
                },
                icon: const Icon(Icons.check_circle)),
            IconButton(
                onPressed: () {
                  DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
                      .declineFriendRequest(
                          widget.userId, widget.username, widget.displayName);
                },
                icon: const Icon(Icons.cancel)),
          ],
        ),
        title: Text(widget.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(widget.username,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
