import 'package:flutter/material.dart';

class GroupMemberTile extends StatelessWidget {
  final String memberName;
  final String memberUsername;
  const GroupMemberTile(
      {super.key, required this.memberName, required this.memberUsername});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        title: Text(
          memberName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          memberUsername,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
