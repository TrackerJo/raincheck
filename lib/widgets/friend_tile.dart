import 'package:flutter/material.dart';
import 'package:raincheck/pages/profile_page.dart';
import 'package:raincheck/widgets/widgets.dart';

import '../service/database_service.dart';

class FriendTile extends StatefulWidget {
  final String displayName;
  final String userId;
  final String username;

  const FriendTile({
    super.key,
    required this.displayName,
    required this.userId,
    required this.username,
  });

  @override
  State<FriendTile> createState() => _FriendTileState();
}

class _FriendTileState extends State<FriendTile> {
  String email = "";

  @override
  void initState() {
    super.initState();
    //Get user data
    getUserEmail();
  }

  getUserEmail() async {
    var userData = await DatabaseService().getUserData(widget.userId);
    setState(() {
      email = userData["email"];
    });
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
        title: Text(widget.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(widget.username,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
