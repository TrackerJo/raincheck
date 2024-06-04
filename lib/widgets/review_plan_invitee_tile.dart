import 'package:flutter/material.dart';

class ReviewPlanInviteeTile extends StatelessWidget {
  final String displayName;
  final String username;
  final String id;
  final Function(String) deleteInvitee;

  const ReviewPlanInviteeTile(
      {super.key,
      required this.displayName,
      required this.username,
      required this.deleteInvitee,
      required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
        child: ListTile(
            title: Text(displayName),
            subtitle: Text(username),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                deleteInvitee(id);
              },
            )));
  }
}
