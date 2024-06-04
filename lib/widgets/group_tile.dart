import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raincheck/pages/group_chat_page.dart';
import 'package:raincheck/pages/plan_page.dart';
import 'package:raincheck/widgets/widgets.dart';

import '../service/database_service.dart';

class GroupTile extends StatefulWidget {
  final String groupName;
  final String groupId;
  final String username;
  const GroupTile(
      {super.key,
      required this.groupName,
      required this.groupId,
      required this.username});

  @override
  State<GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends State<GroupTile> {
  Map<String, dynamic> groupData = {};

  void getGroupData() async {
    groupData =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            .getGroupData(widget.groupId);
    setState(() {
      groupData = groupData;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getGroupData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: () {
          nextScreen(
              context,
              GroupChatPage(
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                  username: widget.username));
        },
        title: Text(widget.groupName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          groupData['lastMessageSender'] != ""
              ? "${groupData['lastMessageSender']}:${groupData['lastMessage']}"
              : "No messages yet",
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}
