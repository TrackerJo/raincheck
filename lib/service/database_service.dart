import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'package:device_calendar/device_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:raincheck/helper/helper_function.dart';
import 'package:raincheck/pages/profile_page.dart';
import 'package:raincheck/service/notification_service.dart';

import '../helper/calendar_functions.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection("users");
  final CollectionReference publicCollection =
      FirebaseFirestore.instance.collection("public");
  final CollectionReference groupCollection =
      FirebaseFirestore.instance.collection("groups");

  String generateRandomCode() {
    //generate a random 16 digit code with numbers and letters
    String code = "";
    Random random = Random();
    for (var i = 0; i < 16; i++) {
      int randomNum = random.nextInt(36);
      if (randomNum < 10) {
        code += randomNum.toString();
      } else {
        code += String.fromCharCode(randomNum + 87);
      }
    }
    return code;
  }

  //saving user data
  Future savingUserData(String fullName, String email, String username) async {
    String userFCMToken = await NotificationService().getFCMToken();
    // Set user data in the database
    await userCollection.doc(uid).set({
      "fullName": fullName, // set the user's full name
      "email": email, // set the user's email
      "username": username, // set the user's username
      "friends": [], // set the user's friends
      "pendingRequests": [], // set the user's pending requests
      "outgoingRequests": [], // set the user's outgoing requests
      "uid": uid, // set the user's uid
      "fcmToken": userFCMToken, // set the user's fcm token
      "friendsPlanStats":
          [], // [{"id": "id","totalPlans": 0, "lastPlan":"date"}]
      "groups": [], // set the user's groups
    });

    //Add the username to the public collection
    DocumentSnapshot snapshot = await publicCollection.doc("usernames").get();
    List<dynamic> usernames = snapshot["usernames"];
    usernames.add(username);
    await publicCollection.doc("usernames").update({
      "usernames": usernames,
    });
  }

  //Getting user data
  Future gettingUserData(String email) async {
    QuerySnapshot snapshot =
        await userCollection.where("email", isEqualTo: email).get();
    return snapshot;
  }

  //Updating user data
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await userCollection.doc(userId).update(data);
  }

  Future<List<Map<String, dynamic>>> getUserEvents() async {
    List<Map<String, dynamic>> eventsMap = [];
    QuerySnapshot snapshot =
        await userCollection.doc(uid).collection("events").get();
    for (var i = 0; i < snapshot.docs.length; i++) {
      Map<String, dynamic> event = objectToMap(snapshot.docs[i].data());
      event["id"] = snapshot.docs[i].id;
      eventsMap.add(event);
    }
    return eventsMap;
  }

  List<int> getIndexesOfId(
      List<Map<String, dynamic>> list, String value, String key) {
    List<int> indexes = [];
    for (var i = 0; i < list.length; i++) {
      if (list[i][key] == value) {
        indexes.add(i);
      }
    }
    return indexes;
  }

  //Sync user calendar
  Future syncUserCalendar(
      List<dynamic> calendars, DateTime startDay, DateTime endDay) async {
    List<String> eventIds = [];
    for (var c = 0; c < calendars.length; c++) {
      String calendarId = calendars[c].split("_")[0];
      List<Event> events = await CalendarFunctions()
          .getCalendarEvents(calendarId, startDay, endDay);
      List<Map<String, dynamic>> eventsMap = [];
      List<Map<String, dynamic>> userEvents = await getUserEvents();
      for (var i = 0; i < events.length; i++) {
        int startY = events[i].start!.year;
        int startM = events[i].start!.month;
        int startD = events[i].start!.day;
        int startH = events[i].start!.hour;
        int startMin = events[i].start!.minute;
        int endY = events[i].end!.year;
        int endM = events[i].end!.month;
        int endD = events[i].end!.day;
        int endH = events[i].end!.hour;
        int endMin = events[i].end!.minute;
        String eventId = events[i].eventId!;
        eventIds.add(eventId);
        DateTime dateTime = DateTime.now();
        Duration offset = dateTime.timeZoneOffset;
        print(offset.inHours);

        // //Check if all day event, by checking if the start time is 4:00 and the end time is 3:59, and the end date is the next day, then change the end date to start date, and change start time to 0:00 and end time to 23:59
        if (offset.isNegative) {
          if (startH == offset.inHours.abs() &&
              startMin == 0 &&
              endH == offset.inHours.abs() - 1 &&
              endMin == 59 &&
              endD == startD + 1) {
            endD = startD;
            startH = 0;
            startMin = 0;
            endH = 23;
            endMin = 59;
          }
        } else {
          if (startH == 24 - offset.inHours &&
              startMin == 0 &&
              endH == 23 - offset.inHours &&
              endMin == 59 &&
              startD == endD - 1) {
            startD = endD;
            startH = 0;
            startMin = 0;
            endH = 23;
            endMin = 59;
          }
        }

        DateTime start = DateTime(startY, startM, startD, startH, startMin);
        DateTime end = DateTime(endY, endM, endD, endH, endMin);

        //Check if event is already in the user's events
        List<int> eventIdIndexes =
            getIndexesOfId(userEvents, eventId, "eventId");

        if (eventIdIndexes.length != 0) {
          if (eventIdIndexes.length == 1) {
            if (userEvents[eventIdIndexes[0]]["startTime"] ==
                    "${start.hour}:${start.minute}" &&
                userEvents[eventIdIndexes[0]]["endTime"] ==
                    "${end.hour}:${end.minute}") {
              continue;
            }
          } else {
            for (var i = 0; i < eventIdIndexes.length; i++) {
              //Delete all events with the same eventId
              await userCollection
                  .doc(uid)
                  .collection("events")
                  .doc(userEvents[eventIdIndexes[i]]["id"])
                  .delete();
            }
          }
        }

        //Check if end is a different day from start
        if (end.day != start.day ||
            start.month != end.month ||
            end.year != start.year) {
          eventsMap.add({
            "startTime": "${start.hour}:${start.minute}",
            "endTime": "23:59",
            "date": "${start.month}-${start.day}-${start.year}",
            "eventId": eventId
          });
          //Chech how many days are between start and end

          int daysBetween = end.difference(start).inDays;
          start = start.add(const Duration(days: 1));
          for (var i = 1; i < daysBetween; i++) {
            eventsMap.add({
              "startTime": "00:00",
              "endTime": "23:59",
              "date": "${start.month}-${start.day}-${start.year}",
              "eventId": eventId
            });
          }
          eventsMap.add({
            "startTime": "00:00",
            "endTime": "${end.hour}:${end.minute}",
            "date": "${end.month}-${end.day}-${end.year}",
            "eventId": eventId
          });
        } else {
          eventsMap.add({
            "startTime": "${start.hour}:${start.minute}",
            "endTime": "${end.hour}:${end.minute}",
            "date": "${start.month}-${start.day}-${start.year}",
            "eventId": eventId
          });
        }
      }

      print("Syncing calendar");

      for (var i = 0; i < eventsMap.length; i++) {
        print("Adding event ${eventsMap[i]}");
        userCollection.doc(uid).collection("events").add(eventsMap[i]);
      }
    }
    //Delete all events that are not in the user's calendar
    List<Map<String, dynamic>> userEvents = await getUserEvents();
    for (var i = 0; i < userEvents.length; i++) {
      if (!eventIds.contains(userEvents[i]["eventId"])) {
        print(eventIds);
        //Delete doc where eventId == userEvents[i]["eventId"]
        QuerySnapshot docsToDelete = await userCollection
            .doc(uid)
            .collection("events")
            .where("eventId", isEqualTo: userEvents[i]["eventId"])
            .get();
        for (var i = 0; i < docsToDelete.docs.length; i++) {
          docsToDelete.docs[i].reference.delete();
        }
      }
    }
  }

  Future removeUserCalendar() async {
    QuerySnapshot snapshot =
        await userCollection.doc(uid).collection("events").get();
    for (var i = 0; i < snapshot.docs.length; i++) {
      snapshot.docs[i].reference.delete();
    }
  }

  Future<List<Map<String, DateTime>>> getUserEventsForDay(
      String date, String uid) async {
    QuerySnapshot snapshot = await userCollection
        .doc(uid)
        .collection("events")
        .where("date", isEqualTo: date)
        .get();
    List<Map<String, dynamic>> eventsMap = [];
    for (var i = 0; i < snapshot.docs.length; i++) {
      eventsMap.add(objectToMap(snapshot.docs[i].data()));
    }
    List<Map<String, DateTime>> cleanedEventsMap = [];
    for (var i = 0; i < eventsMap.length; i++) {
      int month = int.parse(eventsMap[i]["date"].split("-")[0]);
      int day = int.parse(eventsMap[i]["date"].split("-")[1]);
      int year = int.parse(eventsMap[i]["date"].split("-")[2]);
      int startH = int.parse(eventsMap[i]["startTime"].split(":")[0]);
      int startMin = int.parse(eventsMap[i]["startTime"].split(":")[1]);
      int endH = int.parse(eventsMap[i]["endTime"].split(":")[0]);
      int endMin = int.parse(eventsMap[i]["endTime"].split(":")[1]);
      DateTime start = DateTime(year, month, day, startH, startMin);
      DateTime end = DateTime(year, month, day, endH, endMin);
      cleanedEventsMap.add({
        "startTime": start,
        "endTime": end,
      });
    }
    return cleanedEventsMap;
  }

  Map<String, dynamic> objectToMap(Object? obj) {
    Map<String, dynamic> map = {};

    Map<String, dynamic> objMap = obj as Map<String, dynamic>;

    return objMap;
  }

  Future<Stream> getCurrentUserDataStream() async {
    Stream stream = userCollection.doc(uid).snapshots();
    return stream;
  }

  getUserData(String userId, {asMap = false}) async {
    DocumentSnapshot snapshot = await userCollection.doc(userId).get();
    if (asMap) {
      return objectToMap(snapshot.data());
    } else {
      return snapshot;
    }
    //return snapshot;
  }

  Future<bool> checkIfUsernameExists(String username) async {
    //Get all usernames from the "public" collection from the doc called "usernames"
    DocumentSnapshot snapshot = await publicCollection.doc("usernames").get();
    List<dynamic> usernames = snapshot["usernames"];
    //Check if the username exists in the list of usernames
    if (usernames.contains(username)) {
      return true;
    } else {
      return false;
    }
  }

  Future inviteFriend(String friendsUsername) async {
    //Get the friend's uid
    //Add the friend's uid to the current user's outgoing requests list
    //Add the current user's uid to the friend's pending requests list

    QuerySnapshot snapshot = await userCollection
        .where("username", isEqualTo: friendsUsername)
        .get();

    String friendsUid = snapshot.docs[0]["uid"];
    String friendsDisplayName = snapshot.docs[0]["fullName"];
    String friendRequestString =
        "${friendsUid}_${friendsUsername}_$friendsDisplayName";
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String? displayName = await HelperFunctions.getUserDisplayNameFromSF();
    String? username = await HelperFunctions.getUserNameFromSF();
    String myRequestString = "${uid}_${username}_$displayName";
    await userCollection.doc(uid).update({
      "outgoingRequests": FieldValue.arrayUnion([friendRequestString]),
    });
    await userCollection.doc(friendsUid).update({
      "pendingRequests": FieldValue.arrayUnion([myRequestString]),
    });
    //Send notification to friend
    String friendFCMToken = await userCollection
        .doc(friendsUid)
        .get()
        .then((value) => value["fcmToken"]);
    if (friendFCMToken != "") {
      await NotificationService().sendNotificationToDevice(
          friendFCMToken,
          "You have a new friend request!",
          "$displayName has sent you a friend request!",
          "friendRequest");
    }
  }

  Future deleteFriendRequest(
      String friendId, String friendUserName, String friendDisplayName) async {
    String friendRequestString =
        "${friendId}_${friendUserName}_$friendDisplayName";
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String? displayName = await HelperFunctions.getUserDisplayNameFromSF();
    String? username = await HelperFunctions.getUserNameFromSF();
    String myRequestString = "${uid}_${username}_$displayName";
    await userCollection.doc(uid).update({
      "outgoingRequests": FieldValue.arrayRemove([friendRequestString]),
    });
    await userCollection.doc(friendId).update({
      "pendingRequests": FieldValue.arrayRemove([myRequestString]),
    });
  }

  Future removeFriend(String fullFriendId) async {
    String friendId = fullFriendId.split("_")[0];
    String? displayName = await HelperFunctions.getUserDisplayNameFromSF();
    String? username = await HelperFunctions.getUserNameFromSF();
    String myRequestString = "${uid}_${username}_$displayName";
    await userCollection.doc(uid).update({
      "friends": FieldValue.arrayRemove([fullFriendId]),
    });
    await userCollection.doc(friendId).update({
      "friends": FieldValue.arrayRemove([myRequestString]),
    });
  }

  Future declineFriendRequest(
      String friendId, String friendUserName, String friendDisplayName) async {
    String friendRequestString =
        "${friendId}_${friendUserName}_$friendDisplayName";
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String? displayName = await HelperFunctions.getUserDisplayNameFromSF();
    String? username = await HelperFunctions.getUserNameFromSF();
    String myRequestString = "${uid}_${username}_$displayName";

    await userCollection.doc(uid).update({
      "pendingRequests": FieldValue.arrayRemove([friendRequestString]),
    });
    await userCollection.doc(friendId).update({
      "outgoingRequests": FieldValue.arrayRemove([myRequestString]),
    });
  }

  Future acceptFriendRequest(
      String friendId, String friendUserName, String friendDisplayName) async {
    String friendRequestString =
        "${friendId}_${friendUserName}_$friendDisplayName";
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String? displayName = await HelperFunctions.getUserDisplayNameFromSF();
    String? username = await HelperFunctions.getUserNameFromSF();
    String myRequestString = "${uid}_${username}_$displayName";

    await userCollection.doc(uid).update({
      "pendingRequests": FieldValue.arrayRemove([friendRequestString]),
    });
    await userCollection.doc(friendId).update({
      "outgoingRequests": FieldValue.arrayRemove([myRequestString]),
    });

    await userCollection.doc(uid).update({
      "friends": FieldValue.arrayUnion([friendRequestString]),
    });

    await userCollection.doc(friendId).update({
      "friends": FieldValue.arrayUnion([myRequestString]),
    });
  }

  Future<String> getFullUserId(String userId) async {
    //Get users uid, username, and display name
    //Combine them into a string
    //Return the string
    DocumentSnapshot snapshot = await userCollection.doc(userId).get();

    String username = snapshot["username"];
    String displayName = snapshot["fullName"];
    return "${userId}_${username}_$displayName";
  }

  bool containsId(List<dynamic> list, String id, String key) {
    return list.any((element) => element[key] == id);
  }

  int indexOfId(List<dynamic> list, String id, String key) {
    for (int i = 0; i < list.length; i++) {
      if (list[i][key] == id) {
        return i;
      }
    }
    return -1; // Return -1 if the item is not found
  }

  Future sendPlan(Map<String, dynamic> plan) async {
    plan["creator"] = await getFullUserId(uid!);
    DocumentSnapshot userData = await userCollection.doc(uid).get();

    //Add plan to current user's plans
    DocumentReference planUserDoc =
        await userCollection.doc(uid).collection("plans").add(plan);
    //Add plan id to current user's plans
    await planUserDoc.update({"id": planUserDoc.id});
    //Add plan to all invitees' pending plans
    for (var i = 0; i < plan["invitees"].length; i++) {
      plan["isInvitee"] = "Yes";
      DocumentSnapshot inviteeData =
          await userCollection.doc(plan["invitees"][i]["id"]).get();

      //Get day of the week
      DateTime date = plan["date"];

      String dayOfWeek = DateFormat('EEEE').format(date);
      if (userData["friendsPlanStats"].length != 0) {
        List<dynamic> friendsPlanStats = userData["friendsPlanStats"];
        //Check if users friendsPlanStats Array contains id matching inviteeId
        if (containsId(friendsPlanStats, plan["invitees"][i]["id"], "id")) {
          int statId =
              indexOfId(friendsPlanStats, plan["invitees"][i]["id"], "id");
          Map<String, dynamic> statData = friendsPlanStats[statId];
          statData["totalPlans"] = statData["totalPlans"] + 1;
          statData["lastPlan"] = plan["date"];
          //Check if planTimes contains a time matching the current plan
          if (containsId(statData["planTimes"],
              "$dayOfWeek ${plan["startTime"]} - ${plan["endTime"]}", "time")) {
            int timeId = indexOfId(statData["planTimes"],
                "$dayOfWeek ${plan["startTime"]} - ${plan["endTime"]}", "time");
            Map<String, dynamic> timeData = statData["planTimes"][timeId];
            timeData["count"] = timeData["count"] + 1;
            statData["planTimes"][timeId] = timeData;
          } else {
            statData["planTimes"].add({
              "time": "$dayOfWeek ${plan["startTime"]} - ${plan["endTime"]}",
              "count": 1,
            });
          }

          for (var j = 0; j < plan["invitees"].length; j++) {
            if (j == i) continue;

            if (containsId(
                statData["invitees"],
                "${plan["invitees"][j]["id"]}_${plan["invitees"][j]["username"]}_${plan["invitees"][j]["displayName"]}",
                "id")) {
              int inviteeId = indexOfId(
                  statData["invitees"],
                  "${plan["invitees"][j]["id"]}_${plan["invitees"][j]["username"]}_${plan["invitees"][j]["displayName"]}",
                  "id");
              Map<String, dynamic> inviteeData =
                  statData["invitees"][inviteeId];
              inviteeData["count"] = inviteeData["count"] + 1;
              statData["invitees"][inviteeId] = inviteeData;
            } else {
              statData["invitees"].add({
                "id":
                    "${plan["invitees"][j]["id"]}_${plan["invitees"][j]["username"]}_${plan["invitees"][j]["displayName"]}",
                "count": 1,
              });
            }
          }

          friendsPlanStats[statId] = statData;

          await userCollection.doc(uid).update({
            "friendsPlanStats": friendsPlanStats,
          });
        } else {
          List<Map<String, dynamic>> planInvitees = [];
          for (var j = 0; j < plan["invitees"].length; j++) {
            if (j == i) continue;
            planInvitees.add({
              "id":
                  "${plan["invitees"][j]["id"]}_${plan["invitees"][j]["username"]}_${plan["invitees"][j]["displayName"]}",
              "count": 1,
            });
          }
          //If not, add it
          await userCollection.doc(uid).update({
            "friendsPlanStats": FieldValue.arrayUnion([
              {
                "id": plan["invitees"][i]["id"],
                "totalPlans": 1,
                "lastPlan": plan["date"],
                "planTimes": [
                  {
                    "time":
                        "$dayOfWeek ${plan["startTime"]} - ${plan["endTime"]}",
                    "count": 1
                  }
                ],
                "invitees": planInvitees,
              }
            ]),
          });
        }
      } else {
        List<Map<String, dynamic>> planInvitees = [];
        for (var j = 0; j < plan["invitees"].length; j++) {
          if (j == i) continue;
          planInvitees.add({
            "id":
                "${plan["invitees"][j]["id"]}_${plan["invitees"][j]["username"]}_${plan["invitees"][j]["displayName"]}",
            "count": 1,
          });
        }
        //If not, add it
        await userCollection.doc(uid).update({
          "friendsPlanStats": FieldValue.arrayUnion([
            {
              "id": plan["invitees"][i]["id"],
              "totalPlans": 1,
              "lastPlan": plan["date"],
              "planTimes": [
                {
                  "time":
                      "$dayOfWeek ${plan["startTime"]} - ${plan["endTime"]}",
                  "count": 1
                }
              ],
              "invitees": planInvitees,
            }
          ]),
        });
      }
      //Get invitee's fcm token
      String inviteeFCMToken = inviteeData["fcmToken"];
      if (inviteeFCMToken != "") {
        //Send notification to invitee
        await NotificationService().sendNotificationToDevice(
            inviteeFCMToken,
            "You have a new plan request!",
            "${plan["creator"].split("_")[2]} has invited you to ${plan["name"]} on ${plan["date"]} from ${plan["startTime"]} to ${plan["endTime"]}",
            "planRequest");
      }
      DocumentReference planDoc = await userCollection
          .doc(plan["invitees"][i]["id"])
          .collection("planRequests")
          .add(plan);
      //Add plan id to all invitees' pending plans
      await planDoc.update({"id": planUserDoc.id, "planRequestId": planDoc.id});
    }
  }

  //Get User's plans
  Future getUserPlans() async {
    QuerySnapshot snapshot =
        await userCollection.doc(uid).collection("plans").get();
    //Convert the snapshot to a list of maps
    List<Map<String, dynamic>> plans = [];
    for (var i = 0; i < snapshot.docs.length; i++) {
      plans.add(objectToMap(snapshot.docs[i].data()));
    }
    return plans;
  }

  Future<Stream> getUserPlansStream() async {
    Stream snapshot = userCollection.doc(uid).collection("plans").snapshots();

    return snapshot;
  }

  Future<Stream> getUserPendingPlansStream() async {
    Stream snapshot =
        userCollection.doc(uid).collection("planRequests").snapshots();

    return snapshot;
  }

  Future userCanAttendPlan(String planId, String userId, String ownerFullId,
      String planRequestId) async {
    String ownerId = ownerFullId.split("_")[0];
    DocumentSnapshot userData = await userCollection.doc(uid).get();
    Map<String, dynamic> planData = (await userCollection
            .doc(ownerId)
            .collection("plans")
            .doc(planId)
            .get())
        .data() as Map<String, dynamic>;
    List<dynamic> invitees = planData["invitees"];
    invitees.firstWhere((element) => element["id"] == userId)["canAttend"] =
        "Yes";
    await userCollection.doc(ownerId).collection("plans").doc(planId).update({
      "invitees": invitees,
    });
    //Get day of the week
    DateTime date = planData["date"].toDate();
    Iterable otherInvitees =
        invitees.where((element) => element["id"] != userId);
    String dayOfWeek = DateFormat('EEEE').format(date);
    if (userData["friendsPlanStats"].length != 0) {
      List<dynamic> friendsPlanStats = userData["friendsPlanStats"];
      //Check if users friendsPlanStats Array contains id matching inviteeId
      if (containsId(friendsPlanStats, ownerId, "id")) {
        int statId = indexOfId(friendsPlanStats, ownerId, "id");
        Map<String, dynamic> statData = friendsPlanStats[statId];
        statData["totalPlans"] = statData["totalPlans"] + 1;
        statData["lastPlan"] = planData["date"];
        //Check if planTimes contains a time matching the current plan
        if (containsId(
            statData["planTimes"],
            "$dayOfWeek ${planData["startTime"]} - ${planData["endTime"]}",
            "time")) {
          int timeId = indexOfId(
              statData["planTimes"],
              "$dayOfWeek ${planData["startTime"]} - ${planData["endTime"]}",
              "time");

          Map<String, dynamic> timeData = statData["planTimes"][timeId];
          timeData["count"] = timeData["count"] + 1;
          statData["planTimes"][timeId] = timeData;
        } else {
          statData["planTimes"].add({
            "time":
                "$dayOfWeek ${planData["startTime"]} - ${planData["endTime"]}",
            "count": 1,
          });
        }

        for (var j = 0; j < otherInvitees.length; j++) {
          String otherInviteeId = otherInvitees.elementAt(j)["id"];
          String otherInviteeUsername = otherInvitees.elementAt(j)["username"];
          String otherInviteeDisplayName =
              otherInvitees.elementAt(j)["displayName"];
          if (containsId(
              statData["invitees"],
              "${otherInviteeId}_${otherInviteeUsername}_${otherInviteeDisplayName}",
              "id")) {
            int inviteeId = indexOfId(
                statData["invitees"],
                "${otherInviteeId}_${otherInviteeUsername}_${otherInviteeDisplayName}",
                "id");
            Map<String, dynamic> inviteeData = statData["invitees"][inviteeId];
            inviteeData["count"] = inviteeData["count"] + 1;
            statData["invitees"][inviteeId] = inviteeData;
          } else {
            statData["invitees"].add({
              "id":
                  "${otherInviteeId}_${otherInviteeUsername}_${otherInviteeDisplayName}",
              "count": 1,
            });
          }
        }

        friendsPlanStats[statId] = statData;

        //Update the stat

        await userCollection.doc(userId).update({
          "friendsPlanStats": friendsPlanStats,
        });
      } else {
        //If not, add it
        List<Map<String, dynamic>> planInvitees = [];
        for (var j = 0; j < otherInvitees.length; j++) {
          String otherInviteeId = otherInvitees.elementAt(j)["id"];
          String otherInviteeUsername = otherInvitees.elementAt(j)["username"];
          String otherInviteeDisplayName =
              otherInvitees.elementAt(j)["displayName"];

          planInvitees.add({
            "id":
                "${otherInviteeId}_${otherInviteeUsername}_${otherInviteeDisplayName}",
            "count": 1,
          });
        }
        await userCollection.doc(userId).update({
          "friendsPlanStats": FieldValue.arrayUnion([
            {
              "id": ownerId,
              "totalPlans": 1,
              "lastPlan": planData["date"],
              "planTimes": [
                {
                  "time":
                      "$dayOfWeek ${planData["startTime"]} - ${planData["endTime"]}",
                  "count": 1
                }
              ],
              "invitees": planInvitees,
            }
          ]),
        });
      }
    } else {
      //If not, add it
      List<Map<String, dynamic>> planInvitees = [];
      for (var j = 0; j < otherInvitees.length; j++) {
        String otherInviteeId = otherInvitees.elementAt(j)["id"];
        String otherInviteeUsername = otherInvitees.elementAt(j)["username"];
        String otherInviteeDisplayName =
            otherInvitees.elementAt(j)["displayName"];

        planInvitees.add({
          "id":
              "${otherInviteeId}_${otherInviteeUsername}_${otherInviteeDisplayName}",
          "count": 1,
        });
      }
      await userCollection.doc(userId).update({
        "friendsPlanStats": FieldValue.arrayUnion([
          {
            "id": ownerId,
            "totalPlans": 1,
            "lastPlan": planData["date"],
            "planTimes": [
              {
                "time":
                    "$dayOfWeek ${planData["startTime"]} - ${planData["endTime"]}",
                "count": 1
              }
            ],
            "invitees": planInvitees,
          }
        ]),
      });
    }

    for (var i = 0; i < otherInvitees.length; i++) {
      String otherInviteeId = otherInvitees.elementAt(i)["id"];
      List<dynamic> friendsPlanStats = userData["friendsPlanStats"];
      //Check if users friendsPlanStats Array contains id matching inviteeId
      if (containsId(friendsPlanStats, otherInviteeId, "id")) {
        int statId = indexOfId(friendsPlanStats, otherInviteeId, "id");
        Map<String, dynamic> statData = friendsPlanStats[statId];
        statData["totalPlans"] = statData["totalPlans"] + 1;
        statData["lastPlan"] = planData["date"];
        //Check if planTimes contains a time matching the current plan
        if (containsId(
            statData["planTimes"],
            "$dayOfWeek ${planData["startTime"]} - ${planData["endTime"]}",
            "time")) {
          int timeId = indexOfId(statData["planTimes"], dayOfWeek, "time");
          Map<String, dynamic> timeData = statData["planTimes"][timeId];
          timeData["count"] = timeData["count"] + 1;
          statData["planTimes"][timeId] = timeData;
        } else {
          statData["planTimes"].add({
            "time":
                "$dayOfWeek ${planData["startTime"]} - ${planData["endTime"]}",
            "count": 1,
          });
        }

        for (var j = 0; j < otherInvitees.length; j++) {
          String otherInviteeId = otherInvitees.elementAt(j)["id"];
          String otherInviteeUsername = otherInvitees.elementAt(j)["username"];
          String otherInviteeDisplayName =
              otherInvitees.elementAt(j)["displayName"];
          if (containsId(
              statData["invitees"],
              "${otherInviteeId}_${otherInviteeUsername}_${otherInviteeDisplayName}",
              "id")) {
            int inviteeId = indexOfId(
                statData["invitees"],
                "${otherInviteeId}_${otherInviteeUsername}_${otherInviteeDisplayName}",
                "id");
            Map<String, dynamic> inviteeData = statData["invitees"][inviteeId];
            inviteeData["count"] = inviteeData["count"] + 1;
            statData["invitees"][inviteeId] = inviteeData;
          } else {
            statData["invitees"].add({
              "id":
                  "${otherInviteeId}_${otherInviteeUsername}_${otherInviteeDisplayName}",
              "count": 1,
            });
          }
        }

        //Check if owner is in the invitees list
        if (containsId(statData["invitees"], ownerFullId, "id")) {
          int inviteeId = indexOfId(statData["invitees"], ownerFullId, "id");
          Map<String, dynamic> inviteeData = statData["invitees"][inviteeId];
          inviteeData["count"] = inviteeData["count"] + 1;
          statData["invitees"][inviteeId] = inviteeData;
        } else {
          statData["invitees"].add({
            "id": ownerFullId,
            "count": 1,
          });
        }

        friendsPlanStats[statId] = statData;

        //Update the stat
        await userCollection.doc(userId).update({
          "friendsPlanStats": friendsPlanStats,
        });
      } else {
        //If not, add it
        List<Map<String, dynamic>> planInvitees = [];
        for (var j = 0; j < otherInvitees.length; j++) {
          String otherInviteeId = otherInvitees.elementAt(j)["id"];
          String otherInviteeUsername = otherInvitees.elementAt(j)["username"];
          String otherInviteeDisplayName =
              otherInvitees.elementAt(j)["displayName"];
          if (j == i) continue;
          planInvitees.add({
            "id":
                "${otherInviteeId}_${otherInviteeUsername}_${otherInviteeDisplayName}",
            "count": 1,
          });
        }
        //Add owner to the invitees list
        planInvitees.add({
          "id": ownerFullId,
          "count": 1,
        });

        await userCollection.doc(userId).update({
          "friendsPlanStats": FieldValue.arrayUnion([
            {
              "id": otherInviteeId,
              "totalPlans": 1,
              "lastPlan": planData["date"],
              "planTimes": [
                {
                  "time":
                      "$dayOfWeek ${planData["startTime"]} - ${planData["endTime"]}",
                  "count": 1
                }
              ],
              "invitees": planInvitees,
            }
          ]),
        });
      }
    }
    //Move plan from pending plans to plans
    await userCollection
        .doc(userId)
        .collection("planRequests")
        .doc(planRequestId)
        .delete();
    await userCollection.doc(userId).collection("plans").add({
      "id": planId,
      "ownerId": ownerId,
      "name": planData["name"],
      "date": planData["date"],
      "startTime": planData["startTime"],
      "endTime": planData["endTime"],
      "isInvitee": "Yes",
    });
  }

  Future userCannotAttendPlan(String planId, String userId, String ownerId,
      String planRequestId) async {
    Map<String, dynamic> planData = (await userCollection
            .doc(ownerId)
            .collection("plans")
            .doc(planId)
            .get())
        .data() as Map<String, dynamic>;
    List<dynamic> invitees = planData["invitees"];
    invitees.firstWhere((element) => element["id"] == userId)["canAttend"] =
        "No";
    userCollection.doc(ownerId).collection("plans").doc(planId).update({
      "invitees": invitees,
    });
    await userCollection
        .doc(userId)
        .collection("planRequests")
        .doc(planRequestId)
        .delete();
  }

  Future getPlanData(String planId, String ownerId) async {
    Map<String, dynamic> snapshot = (await userCollection
            .doc(ownerId)
            .collection("plans")
            .doc(planId)
            .get())
        .data() as Map<String, dynamic>;
    return snapshot;
  }

  Future<String> getBestFriendId(String userId) async {
    DocumentSnapshot userData = await userCollection.doc(userId).get();
    List<dynamic> friendsPlanStats = userData["friendsPlanStats"];
    if (friendsPlanStats.length != 0) {
      friendsPlanStats
          .sort((a, b) => b["totalPlans"].compareTo(a["totalPlans"]));
      return friendsPlanStats[0]["id"];
    } else {
      return "";
    }
  }

  Future<Map<String, dynamic>> generateSuggestedPlanTime(
      List<dynamic> planTimes,
      String userId,
      Map<String, dynamic> friendData,
      Map<String, dynamic> inviteeData,
      bool hasInvitee) async {
    for (var i = 0; i < planTimes.length; i++) {
      String dayOfWeek = planTimes[i]["time"].split(" ")[0];
      String startTime = planTimes[i]["time"].split(" ")[1] +
          " " +
          planTimes[i]["time"].split(" ")[2];
      String endTime = planTimes[i]["time"].split(" ")[4] +
          " " +
          planTimes[i]["time"].split(" ")[5];
      DateTime date = DateTime.now();
      List<String> weekdays = [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday"
      ];
      int dayOfWeekIndex = weekdays.indexOf(dayOfWeek) + 1;
      // print(dayOfWeek);
      //also make sure if today is the day of the week, the time is in the future
      //print(DateFormat("hh:mm a").parse(startTime).isAfter(date));
      if (!DateFormat("hh:mm a").parse(startTime).isAfter(date)) {
        date = date.add(const Duration(days: 1));
      }
      while (date.weekday.toString() != dayOfWeekIndex.toString() &&
          !DateFormat("hh:mm a").parse(startTime).isAfter(date)) {
        date = date.add(const Duration(days: 1));
        //  print(date.weekday.toString());
      }
      String startTime24 =
          DateFormat("HH:mm").format(DateFormat("hh:mm a").parse(startTime));
      DateTime start = DateFormat("yyyy-MM-dd HH:mm")
          .parse("${date.year}-${date.month}-${date.day} $startTime24");

      //Convert start time to 24 hour time
      String endTime24 =
          DateFormat("HH:mm").format(DateFormat("hh:mm a").parse(endTime));
      DateTime end = DateFormat("yyyy-MM-dd HH:mm")
          .parse("${date.year}-${date.month}-${date.day} $endTime24");

      String dateStr = "${date.month}-${date.day}-${date.year}";
      List<Map<String, DateTime>> userEvents =
          await getUserEventsForDay(dateStr, userId);
      List<Map<String, DateTime>> bestFriendEvents =
          await getUserEventsForDay(dateStr, friendData["uid"]);
      List<Map<String, DateTime>> inviteeEvents = [];
      if (hasInvitee) {
        inviteeEvents =
            await getUserEventsForDay(dateStr, inviteeData["inviteeId"]);
      }

      List<Map<String, DateTime>> friendFreeList =
          CalendarFunctions.convertBusyListToFreeList(bestFriendEvents, date);
      List<Map<String, DateTime>> userFreeList =
          CalendarFunctions.convertBusyListToFreeList(userEvents, date);
      List<Map<String, DateTime>> inviteeFreeList = [];
      if (hasInvitee) {
        inviteeFreeList =
            CalendarFunctions.convertBusyListToFreeList(inviteeEvents, date);
      }

      print(friendFreeList);
      print(userFreeList);
      bool userFree = CalendarFunctions.compareFreeListToTimeRange(
          userFreeList, start, end);
      bool bestFriendFree = CalendarFunctions.compareFreeListToTimeRange(
          friendFreeList, start, end);

      bool inviteeFree = true;
      if (hasInvitee) {
        inviteeFree = CalendarFunctions.compareFreeListToTimeRange(
            inviteeFreeList, start, end);
      }
      if (userFree && bestFriendFree && inviteeFree) {
        List<Map<String, dynamic>> invitees = [];
        List<String> inviteesNames = [];
        if (hasInvitee) {
          invitees.add(inviteeData);
          inviteesNames.add(inviteeData["inviteeDisplayName"]);
        }
        invitees.add({
          "inviteeId": friendData["uid"],
          "inviteeUsername": friendData["username"],
          "inviteeDisplayName": friendData["fullName"],
        });
        inviteesNames.add(friendData["fullName"]);
        return {
          "name": generatePlanName(inviteesNames),
          "date": date,
          "startTime": startTime,
          "endTime": endTime,
          "invitees": invitees,
        };
      }
    }
    return {};
  }

  Future<Map<String, dynamic>> getBestFriendPlanStats(String userId) async {
    DocumentSnapshot userData = await userCollection.doc(userId).get();
    String bestFriendId = await getBestFriendId(userId);
    List<dynamic> friendsPlanStats = userData["friendsPlanStats"];
    int id = indexOfId(friendsPlanStats, bestFriendId, "id");
    if (id == -1) return {};
    Map<String, dynamic> bestFriendPlanStats = friendsPlanStats[id];
    return bestFriendPlanStats;
  }

  Future<Map<String, dynamic>> suggestBestFriendPlan(String userId) async {
    Map<String, dynamic> bestFriendPlanStats =
        await getBestFriendPlanStats(userId);

    if (bestFriendPlanStats["id"] == null) {
      return {};
    }
    Map<String, dynamic> bestFriendData =
        await getUserData(bestFriendPlanStats["id"], asMap: true);
    bool hasInvitee = bestFriendPlanStats["invitees"].length != 0;
    Map<String, dynamic> invitee = {};
    if (hasInvitee) {
      bestFriendPlanStats["invitees"]
          .sort((a, b) => (b["count"] as int).compareTo(a["count"]));
      String inviteeId = bestFriendPlanStats["invitees"][0]["id"].split("_")[0];
      String inviteeUsername =
          bestFriendPlanStats["invitees"][0]["id"].split("_")[1];
      String inviteeDisplayName =
          bestFriendPlanStats["invitees"][0]["id"].split("_")[2];
      invitee = {
        "inviteeId": inviteeId,
        "inviteeUsername": inviteeUsername,
        "inviteeDisplayName": inviteeDisplayName,
      };
    }
    List<dynamic> planTimes = bestFriendPlanStats["planTimes"];
    planTimes.sort((a, b) => b["count"].compareTo(a["count"]));
    if (hasInvitee) {
      Map<String, dynamic> suggestedPlan = await generateSuggestedPlanTime(
          planTimes, userId, bestFriendData, invitee, hasInvitee);
      if (suggestedPlan.isNotEmpty) {
        return suggestedPlan;
      }
    }
    return await generateSuggestedPlanTime(
        planTimes, userId, bestFriendData, invitee, false);
  }

  String generatePlanName(List<String> inviteeNames) {
    String planName = "Hangout with ";
    print("INVITEES");
    print(inviteeNames);
    for (var i = 0; i < inviteeNames.length; i++) {
      if (i == inviteeNames.length - 1 && inviteeNames.length > 1) {
        planName += "and ${inviteeNames[i]}";
      } else if (inviteeNames.length > 2) {
        planName += "${inviteeNames[i]}, ";
      } else {
        planName += "${inviteeNames[i]} ";
      }
    }
    return planName;
  }

  Future<FriendStatus> getFriendStatus(String fullFriendId) async {
    Map<String, dynamic> userData = await getUserData(uid!, asMap: true);
    List<dynamic> friends = userData["friends"];
    List<dynamic> friendRequests = userData["pendingRequests"];
    List<dynamic> sentFriendRequests = userData["outgoingRequests"];
    print(fullFriendId);
    if (friends.contains(fullFriendId)) {
      return FriendStatus.friend;
    } else if (friendRequests.contains(fullFriendId)) {
      return FriendStatus.requested;
    } else if (sentFriendRequests.contains(fullFriendId)) {
      return FriendStatus.pending;
    } else {
      return FriendStatus.notFriend;
    }
  }

  Future<String> getLeastPlannedFriendId(String userId) async {
    DocumentSnapshot userData = await userCollection.doc(userId).get();
    List<dynamic> friendsPlanStats = userData["friendsPlanStats"];
    //Remove best friend from friendsPlanStats
    String bestFriendId = await getBestFriendId(userId);
    friendsPlanStats.removeWhere((element) => element["id"] == bestFriendId);
    if (friendsPlanStats.length != 0) {
      //Sort the friendsPlanStats array from time since last plan
      friendsPlanStats.sort((a, b) =>
          (a["lastPlan"] as Timestamp).compareTo(b["lastPlan"] as Timestamp));
      //Return the id of the friend with the least recent plan
      return friendsPlanStats[0]["id"];
    } else {
      return "";
    }
  }

  Future<Map<String, dynamic>> getLeastPlannedFriendPlanStats(
      String userId) async {
    DocumentSnapshot userData = await userCollection.doc(userId).get();
    String leastPlannedFriendId = await getLeastPlannedFriendId(userId);
    List<dynamic> friendsPlanStats = userData["friendsPlanStats"];
    int id = indexOfId(friendsPlanStats, leastPlannedFriendId, "id");
    if (id == -1) return {};
    Map<String, dynamic> leastPlannedFriendPlanStats = friendsPlanStats[id];
    return leastPlannedFriendPlanStats;
  }

  Future<Map<String, dynamic>> suggestLeastPlannedFriendPlan(
      String userId) async {
    Map<String, dynamic> leastPlannedFriendPlanStats =
        await getLeastPlannedFriendPlanStats(userId);

    if (leastPlannedFriendPlanStats["id"] == null) {
      return {};
    }
    Map<String, dynamic> leastPlannedFriendData =
        await getUserData(leastPlannedFriendPlanStats["id"], asMap: true);
    bool hasInvitee = leastPlannedFriendPlanStats["invitees"].length != 0;
    Map<String, dynamic> invitee = {};
    if (hasInvitee) {
      leastPlannedFriendPlanStats["invitees"]
          .sort((a, b) => (b["count"] as int).compareTo(a["count"]));
      String inviteeId =
          leastPlannedFriendPlanStats["invitees"][0]["id"].split("_")[0];
      String inviteeUsername =
          leastPlannedFriendPlanStats["invitees"][0]["id"].split("_")[1];
      String inviteeDisplayName =
          leastPlannedFriendPlanStats["invitees"][0]["id"].split("_")[2];
      invitee = {
        "inviteeId": inviteeId,
        "inviteeUsername": inviteeUsername,
        "inviteeDisplayName": inviteeDisplayName,
      };
    }
    List<dynamic> planTimes = leastPlannedFriendPlanStats["planTimes"];
    planTimes.sort((a, b) => b["count"].compareTo(a["count"]));
    if (hasInvitee) {
      Map<String, dynamic> suggestedPlan = await generateSuggestedPlanTime(
          planTimes, userId, leastPlannedFriendData, invitee, hasInvitee);
      if (suggestedPlan.isNotEmpty) {
        return suggestedPlan;
      }
    }
    return await generateSuggestedPlanTime(
        planTimes, userId, leastPlannedFriendData, invitee, false);
  }

  Future<String> getRandomFriendId(String userId) async {
    DocumentSnapshot userData = await userCollection.doc(userId).get();
    List<dynamic> friendsPlanStats = userData["friendsPlanStats"];
    //Remove best friend from friendsPlanStats
    String bestFriendId = await getBestFriendId(userId);
    friendsPlanStats.removeWhere((element) => element["id"] == bestFriendId);
    String leastPlannedFriendId = await getLeastPlannedFriendId(userId);

    friendsPlanStats
        .removeWhere((element) => element["id"] == leastPlannedFriendId);

    if (friendsPlanStats.length != 0) {
      int randomIndex = Random().nextInt(friendsPlanStats.length);

      //Return the id of the friend with the least recent plan
      return friendsPlanStats[randomIndex]["id"];
    } else {
      return "";
    }
  }

  Future<Map<String, dynamic>> getRandomFriendPlanStats(String userId) async {
    DocumentSnapshot userData = await userCollection.doc(userId).get();
    String randomFriendId = await getRandomFriendId(userId);
    List<dynamic> friendsPlanStats = userData["friendsPlanStats"];
    int id = indexOfId(friendsPlanStats, randomFriendId, "id");
    if (id == -1) return {};
    Map<String, dynamic> randomFriendPlanStats = friendsPlanStats[id];
    return randomFriendPlanStats;
  }

  Future<Map<String, dynamic>> suggestRandomFriendPlan(String userId) async {
    Map<String, dynamic> randomFriendPlanStats =
        await getRandomFriendPlanStats(userId);

    if (randomFriendPlanStats["id"] == null) {
      return {};
    }
    Map<String, dynamic> randomFriendData =
        await getUserData(randomFriendPlanStats["id"], asMap: true);
    bool hasInvitee = randomFriendPlanStats["invitees"].length != 0;
    Map<String, dynamic> invitee = {};
    if (hasInvitee) {
      randomFriendPlanStats["invitees"]
          .sort((a, b) => (b["count"] as int).compareTo(a["count"]));
      String inviteeId =
          randomFriendPlanStats["invitees"][0]["id"].split("_")[0];
      String inviteeUsername =
          randomFriendPlanStats["invitees"][0]["id"].split("_")[1];
      String inviteeDisplayName =
          randomFriendPlanStats["invitees"][0]["id"].split("_")[2];
      invitee = {
        "inviteeId": inviteeId,
        "inviteeUsername": inviteeUsername,
        "inviteeDisplayName": inviteeDisplayName,
      };
    }
    List<dynamic> planTimes = randomFriendPlanStats["planTimes"];
    planTimes.sort((a, b) => b["count"].compareTo(a["count"]));
    if (hasInvitee) {
      Map<String, dynamic> suggestedPlan = await generateSuggestedPlanTime(
          planTimes, userId, randomFriendData, invitee, hasInvitee);
      if (suggestedPlan.isNotEmpty) {
        return suggestedPlan;
      }
    }
    return await generateSuggestedPlanTime(
        planTimes, userId, randomFriendData, invitee, false);
  }

  Future<List<Map<String, dynamic>>> getSuggestedPlans(String userId) async {
    List<Map<String, dynamic>> suggestedPlans = [];
    Map<String, dynamic> bestFriendPlan = await suggestBestFriendPlan(userId);
    Map<String, dynamic> leastPlannedFriendPlan =
        await suggestLeastPlannedFriendPlan(userId);
    Map<String, dynamic> randomFriendPlan =
        await suggestRandomFriendPlan(userId);
    if (bestFriendPlan["name"] != null) {
      suggestedPlans.add(bestFriendPlan);
    }
    if (leastPlannedFriendPlan["name"] != null) {
      suggestedPlans.add(leastPlannedFriendPlan);
    }
    if (randomFriendPlan["name"] != null) {
      suggestedPlans.add(randomFriendPlan);
    }
    return suggestedPlans;
  }

  Future<Map<String, dynamic>> getGroupData(String groupId) async {
    DocumentSnapshot groupData = await groupCollection.doc(groupId).get();
    if (groupData.data() == null) return Map<String, dynamic>();
    Map<String, dynamic> groupDataMap = objectToMap(groupData.data());
    return groupDataMap;
  }

  Future<List<dynamic>> getUserGroups(String userId) async {
    //Get user data
    Map<String, dynamic> userData = await getUserData(userId, asMap: true);
    //Get user's groups
    return userData["groups"];
  }

  Future<String> createGroup(
      String groupName, List<String> groupMembers, String owner) async {
    //Create group
    DocumentReference newGroup = await groupCollection.add({
      "name": groupName,
      "members": groupMembers,
      "owner": owner,
      "lastMessage": "",
      "lastMessageSender": "",
    });
    //Get group id
    String groupId = newGroup.id;
    //Update group id in group document
    await groupCollection.doc(groupId).update({
      "groupId": groupId,
    });

    String groupFullId = "$groupId" + "_" + "$groupName";
    //Add group to each member's groups list
    for (var i = 0; i < groupMembers.length; i++) {
      await userCollection.doc(groupMembers[i].split("_")[0]).update({
        "groups": FieldValue.arrayUnion([groupFullId]),
      });
    }

    //Add group to owner's groups list
    await userCollection.doc(owner.split("_")[0]).update({
      "groups": FieldValue.arrayUnion([groupFullId]),
    });

    return groupFullId;
  }

  getGroupChats(String groupId) async {
    return groupCollection
        .doc(groupId)
        .collection("messages")
        .orderBy("time")
        .snapshots();
  }

  sendGroupMessage(String groupId, Map<String, dynamic> chatMessageData) async {
    groupCollection.doc(groupId).collection("messages").add(chatMessageData);
    groupCollection.doc(groupId).update({
      "lastMessage": chatMessageData["message"],
      "lastMessageSender": chatMessageData["senderDisplayName"]
    });
  }

  Future leaveGroup(String fullGroupId, String fullUserId) async {
    //Remove group from user's groups list
    await userCollection.doc(fullUserId.split("_")[0]).update({
      "groups": FieldValue.arrayRemove([fullGroupId]),
    });
    //Remove user from group's members list
    await groupCollection.doc(fullGroupId.split("_")[0]).update({
      "members": FieldValue.arrayRemove([fullUserId]),
    });
  }

  Future deleteGroup(String fullGroupId) async {
    //Get group data
    Map<String, dynamic> groupData =
        await getGroupData(fullGroupId.split("_")[0]);
    //Remove group from each member's groups list
    for (var i = 0; i < groupData["members"].length; i++) {
      await userCollection.doc(groupData["members"][i].split("_")[0]).update({
        "groups": FieldValue.arrayRemove([fullGroupId]),
      });
    }

    //Remove group from owner's groups list
    await userCollection.doc(groupData["owner"].split("_")[0]).update({
      "groups": FieldValue.arrayRemove([fullGroupId]),
    });
    //Delete group
    await groupCollection.doc(fullGroupId.split("_")[0]).delete();
  }

  Future addGroupMember(String fullGroupId, String fullUserId) async {
    //Add group to user's groups list
    await userCollection.doc(fullUserId.split("_")[0]).update({
      "groups": FieldValue.arrayUnion([fullGroupId]),
    });
    //Add user to group's members list
    await groupCollection.doc(fullGroupId.split("_")[0]).update({
      "members": FieldValue.arrayUnion([fullUserId]),
    });
  }
}
