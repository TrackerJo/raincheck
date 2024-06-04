import 'dart:collection';

import 'package:device_calendar/device_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:raincheck/service/database_service.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class CalendarFunctions {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  static Future<bool> checkPermission() async {
    DeviceCalendarPlugin dc = DeviceCalendarPlugin();
    var permissionsGranted = await dc.hasPermissions();
    return permissionsGranted.isSuccess && permissionsGranted.data!;
  }

  static Future<bool> requestPermission() async {
    DeviceCalendarPlugin dc = DeviceCalendarPlugin();
    var permissionStatus = await dc.requestPermissions();
    return permissionStatus.isSuccess && permissionStatus.data!;
  }

  getCalendars() async {
    Result<UnmodifiableListView<Calendar>> calendar =
        await _deviceCalendarPlugin.retrieveCalendars();
    return calendar.data;
  }

  getCalendarEvents(
      String calendarId, DateTime startDay, DateTime endDay) async {
    Result<UnmodifiableListView<Event>> events =
        await _deviceCalendarPlugin.retrieveEvents(calendarId,
            RetrieveEventsParams(startDate: startDay, endDate: endDay));
    return events.data;
  }

  //Checks if time range is within time range
  static bool isWithinTimeRange(
      DateTime start, DateTime end, DateTime startRange, DateTime endRange) {
    print(startRange);
    print(endRange);
    print(start);
    print(end);
    if (startRange.isBefore(start) && endRange.isAfter(end)) {
      return true;
    } else if (startRange == start && endRange == end) {
      return true;
    } else if (startRange.isBefore(start) && endRange == end) {
      return true;
    } else if (startRange == start && endRange.isAfter(end)) {
      return true;
    } else {
      return false;
    }
  }

  static List<Map<String, DateTime>> convertBusyListToFreeList(
      List<Map<String, DateTime>> busyTimes, DateTime baseDate) {
    List<Map<String, DateTime>> freeTimes = [];
    //Check if busy times is empty
    if (busyTimes.isEmpty) {
      freeTimes.add({
        "startTime":
            DateTime(baseDate.year, baseDate.month, baseDate.day, 0, 0),
        "endTime": DateTime(baseDate.year, baseDate.month, baseDate.day, 23, 59)
      });
      return freeTimes;
    }
    //Sort busy times by start time
    busyTimes.sort((a, b) => a["startTime"]!.compareTo(b["startTime"]!));
    for (var i = 0; i < busyTimes.length; i++) {
      int startMonth = busyTimes[i]["startTime"]!.month;
      int startDay = busyTimes[i]["startTime"]!.day;
      int startYear = busyTimes[i]["startTime"]!.year;

      if (i == 0) {
        freeTimes.add({
          "startTime": DateTime(startYear, startMonth, startDay, 0, 0),
          "endTime": busyTimes[i]["startTime"]!,
        });
      } else {
        if (busyTimes[i - 1]["endTime"]!.isAfter(busyTimes[i]["startTime"]!) ||
            busyTimes[i - 1]["endTime"]!
                .isAtSameMomentAs(busyTimes[i]["startTime"]!)) {
          break;
        }
        freeTimes.add({
          "startTime": busyTimes[i - 1]["endTime"]!,
          "endTime": busyTimes[i]["startTime"]!,
        });
      }
    }
    //Sort busy times by end time
    busyTimes.sort((a, b) => a["endTime"]!.compareTo(b["endTime"]!));

    int endMonth = busyTimes[busyTimes.length - 1]["endTime"]!.month;
    int endDay = busyTimes[busyTimes.length - 1]["endTime"]!.day;
    int endYear = busyTimes[busyTimes.length - 1]["endTime"]!.year;
    freeTimes.add({
      "startTime": busyTimes[busyTimes.length - 1]["endTime"]!,
      "endTime": DateTime(endYear, endMonth, endDay, 23, 59)
    });
    return freeTimes;
  }

  static bool compareFreeListToTimeRange(
      List<Map<String, DateTime>> freeList, DateTime start, DateTime end) {
    for (var i = 0; i < freeList.length; i++) {
      if (isWithinTimeRange(
          start, end, freeList[i]["startTime"]!, freeList[i]["endTime"]!)) {
        return true;
      }
    }
    return false;
  }

  static List<Map<String, DateTime>> compareFreeLists(
      List<Map<String, DateTime>> freeList1,
      List<Map<String, DateTime>> freeList2) {
    List<Map<String, DateTime>> freeList = [];
    //Sort both lists by start time
    freeList1.sort((a, b) => a["startTime"]!.compareTo(b["startTime"]!));
    freeList2.sort((a, b) => a["startTime"]!.compareTo(b["startTime"]!));
    for (var i = 0; i < freeList1.length; i++) {
      for (var j = 0; j < freeList2.length; j++) {
        if (isWithinTimeRange(
            freeList1[i]["startTime"]!,
            freeList1[i]["endTime"]!,
            freeList2[j]["startTime"]!,
            freeList2[j]["endTime"]!)) {
          freeList.add({
            "startTime": freeList1[i]["startTime"]!,
            "endTime": freeList1[i]["endTime"]!,
          });
        } else if (isWithinTimeRange(
            freeList2[j]["startTime"]!,
            freeList2[j]["endTime"]!,
            freeList1[i]["startTime"]!,
            freeList1[i]["endTime"]!)) {
          freeList.add({
            "startTime": freeList2[j]["startTime"]!,
            "endTime": freeList2[j]["endTime"]!,
          });
        }
      }
    }
    return freeList;
  }

  Future compareFreeListsBetweenUsers(
      String startDate, String endDate, List<String> users) async {
    List<Map<String, DateTime>> freeList = [];
    DateTime start = DateFormat("MM-dd-yyyy").parse(startDate);
    DateTime end = DateFormat("MM-dd-yyyy").parse(endDate);
    int daysBetween = end.difference(start).inDays;
    for (var i = 0; i <= daysBetween; i++) {
      List<List<Map<String, DateTime>>> freeLists = [];
      DateTime startDay = start.add(Duration(days: i));
      List<Map<String, DateTime>> userBusyList =
          await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
              .getUserEventsForDay(
                  "${startDay.month}-${startDay.day}-${startDay.year}",
                  FirebaseAuth.instance.currentUser!.uid);
      List<Map<String, DateTime>> userFreeList =
          convertBusyListToFreeList(userBusyList, startDay);
      freeLists.add(userFreeList);
      for (var i = 0; i < users.length; i++) {
        List<Map<String, DateTime>> friendBusyList = await DatabaseService(
                uid: FirebaseAuth.instance.currentUser!.uid)
            .getUserEventsForDay(
                "${startDay.month}-${startDay.day}-${startDay.year}", users[i]);
        List<Map<String, DateTime>> friendFreeList =
            convertBusyListToFreeList(friendBusyList, startDay);
        freeLists.add(friendFreeList);
      }
      List<Map<String, DateTime>> newFreeList =
          compareListsOfFreeTimes(freeLists)!;
      freeList = newFreeList;
    }
    return freeList;
  }

  Future<List<Map<String, dynamic>>> checkWhosFreeBetweenRange(
      String startDate,
      String endDate,
      String startTime,
      String endTime,
      List<String> users) async {
    List<Map<String, dynamic>> freeList = [];

    DateTime start = DateFormat("MMMM d, yyyy").parse(startDate);
    DateTime end = DateFormat("MMMM d, yyyy").parse(endDate);
    int daysBetween = end.difference(start).inDays;
    for (var i = 0; i <= daysBetween; i++) {
      DateTime startDay = start.add(Duration(days: i));
      Map<String, dynamic> dayFreeMap = {
        "date": startDay,
        "users": <Map<String, dynamic>>[],
      };
      // List<Map<String, DateTime>> userBusyList =
      //     await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
      //         .getUserEventsForDay(
      //             "${startDay.month}-${startDay.day}-${startDay.year}",
      //             FirebaseAuth.instance.currentUser!.uid);
      // List<Map<String, DateTime>> userFreeList =
      //     convertBusyListToFreeList(userBusyList);

      for (var i = 0; i < users.length; i++) {
        List<Map<String, DateTime>> friendBusyList = await DatabaseService(
                uid: FirebaseAuth.instance.currentUser!.uid)
            .getUserEventsForDay(
                "${startDay.month}-${startDay.day}-${startDay.year}", users[i]);
        List<Map<String, DateTime>> friendFreeList =
            convertBusyListToFreeList(friendBusyList, startDay);
        // print(startTime);
        print(
            DateFormat("HH:mm").format(DateFormat("hh:mm a").parse(startTime)));
        String startTime24 =
            DateFormat("HH:mm").format(DateFormat("hh:mm a").parse(startTime));
        DateTime start = DateFormat("yyyy-MM-dd HH:mm").parse(
            "${startDay.year}-${startDay.month}-${startDay.day} $startTime24");

        //Convert start time to 24 hour time
        String endTime24 =
            DateFormat("HH:mm").format(DateFormat("hh:mm a").parse(endTime));
        DateTime end = DateFormat("yyyy-MM-dd HH:mm").parse(
            "${startDay.year}-${startDay.month}-${startDay.day} $endTime24");
        print(end);
        print("FRINED FREE LIST");
        print(friendFreeList);
        bool isFree = compareFreeListToTimeRange(friendFreeList, start, end);

        String friendUserId =
            await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
                .getFullUserId(users[i]);

        dayFreeMap["users"].add({
          "isFree": isFree,
          "id": friendUserId,
        });
      }
      freeList.add(dayFreeMap);
    }
    return freeList;
  }

  List<Map<String, DateTime>>? compareListsOfFreeTimes(
      List<List<Map<String, DateTime>>> freeLists) {
    int length = freeLists.length;
    bool isOdd = false;
    if (length == 1) {
      return freeLists[0];
    }
    //Check if length is odd
    if (length % 2 != 0) {
      length = length - 1;
      isOdd = true;
      //Add last list to newFreeLists
      freeLists.add(freeLists[freeLists.length - 1]);
      //Remove last list
      freeLists.removeLast();
    }
    List<List<Map<String, DateTime>>> newFreeLists = [];
    for (var i = 1; i <= length / 2; i++) {
      //Compare two lists
      List<Map<String, DateTime>> freeList =
          compareFreeLists(freeLists[i - 1], freeLists[length - i]);
      newFreeLists.add(freeList);
    }
    compareListsOfFreeTimes(newFreeLists);
    return null;
  }

  Future<List<Map<String, DateTime>>> getUserFreeList(
      String userId, DateTime date) async {
    List<Map<String, DateTime>> busyList = await DatabaseService(
            uid: FirebaseAuth.instance.currentUser!.uid)
        .getUserEventsForDay("${date.month}-${date.day}-${date.year}", userId);
    List<Map<String, DateTime>> freeList =
        convertBusyListToFreeList(busyList, date);
    return freeList;
  }

  Future<List<Map<String, dynamic>>> suggestBetterTimes(
      DateTime startDateRange,
      DateTime endDateRange,
      int planTimeLength,
      int minInvitiees,
      List<String> invitees) async {
    //loop through each day in range
    int daysBetween = endDateRange.difference(startDateRange).inDays;
    List<Map<String, dynamic>> suggestedTimes = [];
    for (var i = 0; i <= daysBetween; i++) {
      DateTime currentDay = startDateRange.add(Duration(days: i));
      List<List<Map<String, dynamic>>> userComparedFriendsLists = [];
      //Get free times for current day for current user

      List<Map<String, DateTime>> userFreeList = await getUserFreeList(
          FirebaseAuth.instance.currentUser!.uid, currentDay);

      for (var i = 0; i < invitees.length; i++) {
        String friendId = invitees[i];

        String fullFriendId =
            await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
                .getFullUserId(friendId);

        List<Map<String, DateTime>> friendFreeList =
            await getUserFreeList(friendId, currentDay);
        //Compare user free list to friend free list
        List<Map<String, DateTime>> freeList =
            compareFreeLists(userFreeList, friendFreeList);
        List<Map<String, dynamic>> freeListWithInvitees = [];
        for (var j = 0; j < freeList.length; j++) {
          //Check if plan time length is met
          if (freeList[j]["endTime"]!
                  .difference(freeList[j]["startTime"]!)
                  .inMinutes >=
              planTimeLength) {
            freeListWithInvitees.add({
              "startTime": freeList[j]["startTime"],
              "endTime": freeList[j]["endTime"],
              "invitees": [fullFriendId],
            });
          }
        }
        userComparedFriendsLists.add(freeListWithInvitees);
      }
      //Condense free lists
      List<Map<String, dynamic>>? condensedFreeLists = condenseFreeLists(
          minInvitiees, planTimeLength, userComparedFriendsLists, []);
      //Add to suggested times
      Map<String, dynamic> suggestedTimesForDay = {
        "date": currentDay,
        "times": condensedFreeLists,
      };
      suggestedTimes.add(suggestedTimesForDay);
    }
    return suggestedTimes;
  }

  static List<Map<String, dynamic>> compareFreeListsWithInvitees(
      List<Map<String, dynamic>> freeList1,
      List<Map<String, dynamic>> freeList2) {
    List<Map<String, dynamic>> freeList = [];
    //Sort both lists by start time
    freeList1.sort((a, b) => a["startTime"]!.compareTo(b["startTime"]!));
    freeList2.sort((a, b) => a["startTime"]!.compareTo(b["startTime"]!));
    for (var i = 0; i < freeList1.length; i++) {
      for (var j = 0; j < freeList2.length; j++) {
        if (isWithinTimeRange(
            freeList1[i]["startTime"]!,
            freeList1[i]["endTime"]!,
            freeList2[j]["startTime"]!,
            freeList2[j]["endTime"]!)) {
          List<String> invitees = [];
          invitees.addAll(freeList1[i]["invitees"]);
          invitees.addAll(freeList2[j]["invitees"]);
          freeList.add({
            "startTime": freeList1[i]["startTime"]!,
            "endTime": freeList1[i]["endTime"]!,
            "invitees": invitees,
          });
        } else if (isWithinTimeRange(
            freeList2[j]["startTime"]!,
            freeList2[j]["endTime"]!,
            freeList1[i]["startTime"]!,
            freeList1[i]["endTime"]!)) {
          List<String> invitees = [];
          invitees.addAll(freeList1[i]["invitees"]);
          invitees.addAll(freeList2[j]["invitees"]);
          freeList.add({
            "startTime": freeList2[j]["startTime"]!,
            "endTime": freeList2[j]["endTime"]!,
            "invitees": invitees,
          });
        }
      }
    }
    return freeList;
  }

  List<Map<String, dynamic>>? condenseFreeLists(
      int minInvitees,
      int minPlanLength,
      List<List<Map<String, dynamic>>> freeLists,
      List<Map<String, dynamic>> comparedFreeList) {
    int length = freeLists.length;
    bool isOdd = false;
    if (length == 1) {
      comparedFreeList.addAll(freeLists[0]);
      return comparedFreeList;
    }
    List<List<Map<String, dynamic>>> newFreeLists = [];
    for (var i = 0; i < length; i++) {
      List<Map<String, dynamic>> freeDateList1 = freeLists[i];
      for (var j = 0; j < length; j++) {
        if (i == j) {
          continue;
        }
        List<Map<String, dynamic>> freeDateList2 = freeLists[j];
        //Compare two lists
        List<Map<String, dynamic>> freeList =
            compareFreeListsWithInvitees(freeDateList1, freeDateList2);
        List<Map<String, dynamic>> timeFilteredFreeList = [];
        //Combine invitees

        for (var j = 0; j < timeFilteredFreeList.length; j++) {
          //Check if plan time length is met
          if (timeFilteredFreeList[j]["endTime"]
                  .difference(timeFilteredFreeList[j]["startTime"])
                  .inMinutes >=
              minPlanLength) {
            timeFilteredFreeList.add({
              "startTime": timeFilteredFreeList[j]["startTime"],
              "endTime": timeFilteredFreeList[j]["endTime"],
              "invitees": timeFilteredFreeList[j]["invitees"],
            });
            //Check if min invitees is met
            if (timeFilteredFreeList[j]["invitees"].length >= minInvitees) {
              comparedFreeList.add({
                "startTime": timeFilteredFreeList[j]["startTime"],
                "endTime": timeFilteredFreeList[j]["endTime"],
                "invitees": timeFilteredFreeList[j]["invitees"],
              });
            }
          }
        }

        newFreeLists.add(timeFilteredFreeList);
      }
    }

    condenseFreeLists(
        minInvitees, minPlanLength, newFreeLists, comparedFreeList);
    return null;
  }

  void addCalendarEvent(String eventName, String eventDescription,
      DateTime startTime, DateTime endTime, String userId) async {
    Location currentLocation =
        getLocation(await FlutterNativeTimezone.getLocalTimezone());
    //Set start and end time date to date

    TZDateTime start = TZDateTime.from(startTime, currentLocation);
    TZDateTime end = TZDateTime.from(endTime, currentLocation);
    //get user Data
    Map<String, dynamic> userData =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            .getUserData(userId, asMap: true);
    // print("ADDING EVENT");
    Event event = Event(userData["defaultCalendar"].split("_")[0],
        title: eventName,
        description: eventDescription,
        start: start,
        end: end);
    //print("Event: $eventName, $eventDescription, $startTime, $endTime");
    _deviceCalendarPlugin.createOrUpdateEvent(event);
  }

  Future<List<Map<String, dynamic>>> checkWhosFreeInGroup(
      String startDate,
      String endDate,
      String startTime,
      String endTime,
      int minAttendees,
      String groupId) async {
    Map<String, dynamic> groupData =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            .getGroupData(groupId);
    List<String> memberIdsList = [];
    for (var member in groupData["members"]) {
      memberIdsList.add(member.split("_")[0]);
    }
    List<Map<String, dynamic>> freeList = await checkWhosFreeBetweenRange(
        startDate, endDate, startTime, endTime, memberIdsList);
    print("GROUP FREE LIST");
    print(freeList);
    List<Map<String, dynamic>> filteredFreeList = [];
    for (var i = 0; i < freeList.length; i++) {
      List<Map<String, dynamic>> freeListForDay = freeList[i]["users"];
      int freeUsers = 0;
      for (var j = 0; j < freeListForDay.length; j++) {
        if (freeListForDay[j]["isFree"]) {
          freeUsers++;
        }
      }
      if (freeUsers >= minAttendees) {
        filteredFreeList.add(freeList[i]);
      }
    }
    return filteredFreeList;
  }
}
