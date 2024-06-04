import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:raincheck/widgets/widgets.dart';

import '../pages/profile_page.dart';
import '../service/database_service.dart';

class OutgoingFriendRequestTile extends StatefulWidget {
  final String displayName;
  final String userId;
  final String username;

  const OutgoingFriendRequestTile({
    super.key,
    required this.displayName,
    required this.userId,
    required this.username,
  });

  @override
  State<OutgoingFriendRequestTile> createState() =>
      _OutgoingFriendRequestTileState();
}

class _OutgoingFriendRequestTileState extends State<OutgoingFriendRequestTile> {
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
        trailing: IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: () async {
            await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
                .deleteFriendRequest(
                    widget.userId, widget.username, widget.displayName);
          },
        ),
        title: Text(widget.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(widget.username,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
