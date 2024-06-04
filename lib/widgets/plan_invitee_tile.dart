import 'package:flutter/material.dart';

class PlanInviteeTile extends StatelessWidget {
  final String displayName;
  final String username;
  final bool isAvailable;

  const PlanInviteeTile(
      {super.key,
      required this.displayName,
      required this.username,
      required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Container(
        child: ListTile(
      title: Text(displayName),
      subtitle: Text(username),
      trailing: isAvailable
          ? const Icon(
              Icons.check,
              color: Colors.green,
            )
          : const Icon(
              Icons.close,
              color: Colors.red,
            ),
    ));
  }
}
