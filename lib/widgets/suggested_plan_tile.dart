import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raincheck/pages/plan_creation_page.dart';
import 'package:raincheck/pages/plan_page.dart';
import 'package:raincheck/pages/planner_page.dart';
import 'package:raincheck/widgets/widgets.dart';

class SuggestedPlanTile extends StatelessWidget {
  final Map<String, dynamic> planData;
  final String displayName;
  final String email;
  const SuggestedPlanTile(
      {super.key,
      required this.planData,
      required this.displayName,
      required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: () {
          List<Map<String, dynamic>> invitees = [];
          planData["invitees"].forEach((invitee) {
            invitees.add({
              "id": invitee["inviteeId"],
              "displayName": invitee["inviteeDisplayName"],
              "username": invitee["inviteeUsername"],
              "canAttend": "pending",
            });
          });
          print(planData["date"].toString());
          nextScreen(
              context,
              PlanCreationPage(
                  displayName: displayName,
                  email: email,
                  planType: PlanType.friends,
                  friends: [],
                  invitees: invitees,
                  startTime: planData["startTime"],
                  endTime: planData["endTime"],
                  date: planData["date"].toString(),
                  planName: planData["name"]));
        },
        title: Text(planData["name"],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "${planData['startTime']}-${planData['endTime']}",
          style: const TextStyle(fontSize: 13),
        ),
        trailing: CircleAvatar(
          //Make the circle avatar a big enough to fit all the text
          radius: 30,
          backgroundColor: Colors.orange,

          // Show day of the week and below it show the date of the month in big text, and the time below it in smaller text
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              // Make fit in circle avater
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                Text(DateFormat('MMM').format(planData["date"]),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center),
                Text(DateFormat('dd').format(planData["date"]),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
