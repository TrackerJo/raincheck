import 'package:device_calendar/device_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:raincheck/pages/planner_page.dart';
import 'package:raincheck/pages/plans_page.dart';
import 'package:raincheck/pages/plan_creation_page.dart';

import '../helper/calendar_functions.dart';
import '../helper/helper_function.dart';
import '../service/auth_service.dart';
import '../service/database_service.dart';

import '../widgets/widgets.dart';
import 'auth/login_page.dart';

enum FriendStatus {
  pending,
  friend,
  notFriend,
  requested,
}

class ProfilePage extends StatefulWidget {
  final String uid;

  const ProfilePage({
    super.key,
    required this.uid,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AuthService authService = AuthService();
  bool isCurrentUser = false;

  Map<String, dynamic> userData = {};
  List<Calendar> userCalendars = [];
  final List<MultiSelectItem<Object?>> calendars = [];
  List<dynamic> selectedCalendars = [];
  List<DropdownMenuItem> calendarDropdownItems = [];
  String defaultCalendarId = "";
  FriendStatus friendStatus = FriendStatus.notFriend;
  getUserData() async {
    var userData = await DatabaseService().getUserData(widget.uid, asMap: true);
    List<Calendar> calendars = await CalendarFunctions().getCalendars();
    setState(() {
      this.userData = userData;
      userCalendars = calendars;
      defaultCalendarId = userData["defaultCalendar"];
      selectedCalendars = userData["calendars"];
    });
    await checkIfCurrentUser();
    generateCalendarMultiSelectItems();
    generateCalendarDropdownItems();
    if (!isCurrentUser) {
      String fullId =
          "${widget.uid}_${userData["username"]}_${userData["fullName"]}";
      FriendStatus tempFriendStatus =
          await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
              .getFriendStatus(fullId);
      setState(() {
        friendStatus = tempFriendStatus;
      });
      print(friendStatus);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //Get user data
    getUserData();
  }

  checkIfCurrentUser() async {
    String? userEmailSF = await HelperFunctions.getUserEmailFromSF();

    if (userEmailSF == userData["email"]) {
      setState(() {
        isCurrentUser = true;
      });
    }
  }

  generateCalendarMultiSelectItems() {
    for (var element in userCalendars) {
      setState(() {
        calendars.add(MultiSelectItem(
          "${element.id}_${element.name}",
          element.name!,
        ));
      });
    }
  }

  generateCalendarDropdownItems() {
    calendarDropdownItems = [];
    bool isDefaultCalendarInSelectedCalendars = false;
    for (var element in selectedCalendars) {
      String calendarId = element.split("_")[0];
      String calendarName = element.split("_")[1];
      if (element == defaultCalendarId) {
        isDefaultCalendarInSelectedCalendars = true;
      }
      print("Calendar ID: $calendarId Calendar Name: $calendarName");
      setState(() {
        calendarDropdownItems.add(DropdownMenuItem(
          child: Text(calendarName),
          value: element,
        ));
      });
    }
    if (!isDefaultCalendarInSelectedCalendars) {
      setState(() {
        defaultCalendarId = selectedCalendars[0];
      });
    }
  }

  void changeSelectedCalendars() {
    DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid).updateUserData(
        FirebaseAuth.instance.currentUser!.uid,
        {"calendars": selectedCalendars});
    setState(() {
      userData["calendars"] = selectedCalendars;
    });
  }

  void changeDefaultCalendar() {
    DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid).updateUserData(
        FirebaseAuth.instance.currentUser!.uid,
        {"defaultCalendar": defaultCalendarId});
    setState(() {
      userData["defaultCalendar"] = defaultCalendarId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: const Text(
            "Profile",
            style: TextStyle(
                color: Colors.white, fontSize: 27, fontWeight: FontWeight.bold),
          ),
          actions: [
            isCurrentUser
                ? IconButton(
                    onPressed: () async {
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Logout"),
                              content: const Text(
                                  "Are you sure you want to log out?"),
                              actions: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    color: Colors.red,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await authService.signOut();
                                    Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginPage()),
                                        (route) => false);
                                  },
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            );
                          });
                    },
                    icon: const Icon(Icons.exit_to_app),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: friendStatus == FriendStatus.friend
                        ? IconButton(
                            onPressed: () async {
                              String fullId =
                                  "${widget.uid}_${userData["username"]}_${userData["fullName"]}";
                              await DatabaseService(
                                      uid: FirebaseAuth
                                          .instance.currentUser!.uid)
                                  .removeFriend(fullId);
                              setState(() {
                                friendStatus = FriendStatus.notFriend;
                              });
                              //Show snackbar
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Friend removed")));
                            },
                            tooltip: "Remove Friend",
                            splashRadius: 20,
                            icon:
                                const Icon(Icons.person_remove_alt_1_outlined),
                          )
                        : friendStatus == FriendStatus.notFriend
                            ? IconButton(
                                onPressed: () async {
                                  String fullId =
                                      "${widget.uid}_${userData["username"]}_${userData["fullName"]}";
                                  await DatabaseService(
                                          uid: FirebaseAuth
                                              .instance.currentUser!.uid)
                                      .inviteFriend(userData["username"]);
                                  setState(() {
                                    friendStatus = FriendStatus.requested;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text("Friend request sent")));
                                },
                                tooltip: "Add Friend",
                                splashRadius: 20,
                                icon:
                                    const Icon(Icons.person_add_alt_1_outlined),
                              )
                            : friendStatus == FriendStatus.pending
                                ? IconButton(
                                    onPressed: () async {
                                      await DatabaseService(
                                              uid: FirebaseAuth
                                                  .instance.currentUser!.uid)
                                          .deleteFriendRequest(
                                              widget.uid,
                                              userData["username"],
                                              userData["fullName"]);
                                      setState(() {
                                        friendStatus = FriendStatus.notFriend;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  "Friend request cancelled")));
                                    },
                                    tooltip: "Cancel Friend Request",
                                    splashRadius: 20,
                                    icon: const Icon(
                                        Icons.person_remove_alt_1_outlined),
                                  )
                                : friendStatus == FriendStatus.requested
                                    ? IconButton(
                                        onPressed: () async {
                                          await DatabaseService(
                                                  uid: FirebaseAuth.instance
                                                      .currentUser!.uid)
                                              .acceptFriendRequest(
                                                  widget.uid,
                                                  userData["username"],
                                                  userData["fullName"]);
                                          setState(() {
                                            friendStatus = FriendStatus.friend;
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                                  content: Text(
                                                      "Friend request accepted")));
                                        },
                                        tooltip: "Accept Friend Request",
                                        splashRadius: 20,
                                        icon: const Icon(
                                            Icons.person_add_alt_1_outlined),
                                      )
                                    : Container(),
                  ),
          ],
        ),
        body: userData.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(children: [
                    Icon(
                      Icons.account_circle,
                      size: 200,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 10),
                    Text(userData["fullName"],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                    const SizedBox(height: 10),
                    Text("Email: ${userData["email"]}",
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 15)),
                    const SizedBox(height: 10),
                    !isCurrentUser
                        ? ElevatedButton(
                            onPressed: () {
                              nextScreen(
                                  context,
                                  PlanCreationPage(
                                    displayName: userData["fullName"],
                                    email: userData["email"],
                                    planType: PlanType.friends,
                                    friends: const [],
                                    selectedFriends: [widget.uid],
                                  ));
                            },
                            child: Text("Create Plan"))
                        : Container(),
                    isCurrentUser
                        ? MultiSelectDialogField(
                            initialValue: selectedCalendars,
                            items: calendars,
                            searchable: true,
                            title: const Text("Calendars"),
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4)),
                              border: Border(
                                bottom: BorderSide(
                                    color: Color.fromARGB(255, 100, 197, 238),
                                    width: 2.0),
                                top: BorderSide(
                                    color: Color.fromARGB(255, 100, 197, 238),
                                    width: 2.0),
                                left: BorderSide(
                                    color: Color.fromARGB(255, 100, 197, 238),
                                    width: 2.0),
                                right: BorderSide(
                                    color: Color.fromARGB(255, 100, 197, 238),
                                    width: 2.0),
                              ),
                            ),
                            dialogHeight:
                                (calendars.length * 50).toDouble(), //To Double,

                            onConfirm: (vals) {
                              setState(() {
                                selectedCalendars =
                                    vals.map((e) => e.toString()).toList();
                                print(selectedCalendars);
                              });
                              generateCalendarDropdownItems();
                              changeSelectedCalendars();
                            },
                          )
                        : Container(),
                    isCurrentUser ? const SizedBox(height: 10) : Container(),
                    isCurrentUser
                        ? DropdownButtonFormField(
                            decoration: textInputDecoration.copyWith(
                                labelText: "Default Calendar",
                                prefixIcon: Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).primaryColor,
                                )),
                            value: defaultCalendarId,
                            onChanged: (val) {
                              setState(() {
                                defaultCalendarId = val.toString();
                              });
                              changeDefaultCalendar();
                            },
                            items: calendarDropdownItems,
                          )
                        : Container(),
                  ]),
                ),
              ));
  }
}
