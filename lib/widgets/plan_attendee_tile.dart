import 'package:flutter/material.dart';
import 'package:raincheck/widgets/widgets.dart';

import '../pages/profile_page.dart';

class PlanAttendeeTile extends StatelessWidget {
  final Map<String, dynamic> attendeeData;

  const PlanAttendeeTile({super.key, required this.attendeeData});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        onTap: () {
          nextScreen(
              context,
              ProfilePage(
                uid: attendeeData["id"],
              ));
        },
        title: Text(attendeeData["displayName"]),
        subtitle: Text(attendeeData["username"]),
        leading: attendeeData["isCreator"] != null
            ? CircleAvatar(
                backgroundColor: Colors.transparent,
                child: Image.asset(
                  "assets/crown.png",
                  height: 30,
                  width: 30,
                ))
            : Container(
                width: 0,
              ),
        trailing: attendeeData["canAttend"] == "Yes"
            ? const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
              )
            : attendeeData["canAttend"] == "No"
                ? const Icon(
                    Icons.cancel_outlined,
                    color: Colors.red,
                  )
                : const Icon(
                    Icons.watch_later,
                    color: Colors.orange,
                  ));
  }
}
