import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raincheck/helper/calendar_functions.dart';
import 'package:raincheck/service/database_service.dart';

import '../widgets/plan_attendee_tile.dart';

class PlanPage extends StatefulWidget {
  final bool isIncoming;
  final Map<String, dynamic> planData;
  const PlanPage({super.key, required this.isIncoming, required this.planData});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  String getFriendId(String res) {
    return res.split("_")[0];
  }

  String getFriendUsername(String res) {
    return res.split("_")[1];
  }

  String getFriendDisplayName(String res) {
    return res.split("_")[2];
  }

  getPlanData() async {
    DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
        .getPlanData(
            widget.planData["id"],
            widget.planData["ownerId"] ??
                getFriendId(widget.planData["creator"]))
        .then((value) {
      setState(() {
        print("Getting plan data");
        widget.planData["invitees"] = value["invitees"];
        //Add the creator to the invitees list
        widget.planData["invitees"].add({
          "displayName": getFriendDisplayName(value["creator"]),
          "username": getFriendUsername(value["creator"]),
          "id": getFriendId(value["creator"]),
          "canAttend": "Yes",
          "isCreator": "Yes",
        });
        //Remove yourself from the invitees list
        widget.planData["invitees"].removeWhere((element) =>
            element["id"] == FirebaseAuth.instance.currentUser!.uid);
      });
    });
  }

  changeAttendance(String val) async {
    if (val == "Yes") {
      DateTime startTime =
          DateFormat("hh:mm a").parse(widget.planData["startTime"]);
      startTime = DateTime(
          widget.planData["date"].toDate().year,
          widget.planData["date"].toDate().month,
          widget.planData["date"].toDate().day,
          startTime.hour,
          startTime.minute);
      DateTime endTime =
          DateFormat("hh:mm a").parse(widget.planData["endTime"]);
      endTime = DateTime(
          widget.planData["date"].toDate().year,
          widget.planData["date"].toDate().month,
          widget.planData["date"].toDate().day,
          endTime.hour,
          endTime.minute);
      CalendarFunctions().addCalendarEvent(
          widget.planData["name"],
          widget.planData["description"],
          startTime,
          endTime,
          FirebaseAuth.instance.currentUser!.uid);
      DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
          .userCanAttendPlan(
              widget.planData["id"],
              FirebaseAuth.instance.currentUser!.uid,
              widget.planData["creator"],
              widget.planData["planRequestId"]);
    } else {
      DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
          .userCannotAttendPlan(
              widget.planData["id"],
              FirebaseAuth.instance.currentUser!.uid,
              getFriendId(widget.planData["creator"]),
              widget.planData["planRequestId"]);
    }
    //Pop the page
    Navigator.pop(context);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.planData["isInvitee"] != null) {
      getPlanData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plan Viewer"),
      ),
      body: Center(
          child: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          Text(
            "Plan: ${widget.planData["name"]}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 10,
          ),
          widget.planData["description"] != ""
              ? Text(
                  "Description: ${widget.planData["description"]}",
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                )
              : Container(),
          widget.planData["description"] != ""
              ? const SizedBox(
                  height: 10,
                )
              : Container(),
          Text(
            "Date: ${DateFormat("MMMM dd, yyyy").format(widget.planData["date"].toDate())}",
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            "Time: ${widget.planData["startTime"]} - ${widget.planData["endTime"]}",
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          widget.isIncoming
              ? const Text(
                  "Can you attend?",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                )
              : Container(),
          widget.isIncoming
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        onPressed: () {
                          changeAttendance("Yes");
                        },
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        splashRadius: 20),
                    IconButton(
                      onPressed: () {
                        changeAttendance("No");
                      },
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      splashRadius: 20,
                    ),
                  ],
                )
              : Container(),
          const SizedBox(
            height: 10,
          ),
          const Text(
            "Attendees:",
            style: TextStyle(
              fontSize: 15,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Expanded(
            child: widget.planData["invitees"] != null
                ? ListView.builder(
                    itemCount: widget.planData["invitees"].length,
                    itemBuilder: (context, index) {
                      return PlanAttendeeTile(
                        attendeeData: widget.planData["invitees"][index],
                      );
                    },
                  )
                : Container(),
          ),
        ],
      )),
    );
  }
}
