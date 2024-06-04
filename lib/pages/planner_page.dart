import 'dart:io';

import 'package:device_calendar/device_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:raincheck/pages/plan_creation_page.dart';
import 'package:raincheck/pages/plans_page.dart';
import 'package:raincheck/widgets/suggested_plans_tile.dart';
import 'package:raincheck/widgets/upcoming_plans_tile.dart';
import 'package:raincheck/widgets/widgets.dart';

import '../helper/calendar_functions.dart';
import '../helper/helper_function.dart';
import '../service/database_service.dart';
import '../widgets/app_bar.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/pending_plans_tile.dart';

enum PlanType { friends, group }

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> with WidgetsBindingObserver {
  int currentPageIndex = 1;
  int numOfPendingPlans = 0;
  String displayName = "";
  String email = "";

  Stream? plansStream;
  Stream? pendingPlansStream;

  List<Map<String, dynamic>> suggestedPlansList = [];

  PlanType _planType = PlanType.friends;

  Map<String, dynamic> userData = {};
  final List<MultiSelectItem<Object?>> _items = [];

  handleUpcomingPlansTap() {
    nextScreen(
        context,
        PlansPage(
          currentPlanView: PlanView.myPlans,
        ));
  }

  handleUpcomingPlansEdit(context) {
    choosePlanType(context);
  }

  handleSuggestedPlansTap() {
    nextScreen(
        context,
        PlansPage(
          currentPlanView: PlanView.suggestedPlans,
        ));
  }

  choosePlanType(context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                "What type of plan is this?",
                textAlign: TextAlign.left,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _planType = PlanType.friends;
                        });
                        Navigator.pop(context);
                        nextScreen(
                            context,
                            PlanCreationPage(
                                displayName: displayName,
                                email: email,
                                planType: _planType,
                                friends: _items));
                      },
                      child: const Text(
                        "Plan with Friends",
                        textAlign: TextAlign.center,
                      )),
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _planType = PlanType.group;
                        });
                        Navigator.pop(context);
                        nextScreen(
                            context,
                            PlanCreationPage(
                                displayName: displayName,
                                email: email,
                                planType: _planType,
                                friends: _items));
                      },
                      child: const Text(
                        "Plan with Group",
                        textAlign: TextAlign.center,
                      ))
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text("Cancel"),
                ),
              ],
            );
          });
        });
  }

  handlePendingPlansTap() {
    nextScreen(
        context,
        PlansPage(
          currentPlanView: PlanView.pendingPlans,
        ));
  }

  checkPermissions() async {
    bool permission = await CalendarFunctions.checkPermission();
    if (!permission) {
      bool permissionGranted = await CalendarFunctions.requestPermission();
      if (!permissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Permission not granted"),
          ),
        );
      }
    }

    List<Calendar> calendars = await CalendarFunctions().getCalendars();
    print(calendars[3].id);
    print(calendars[3].name);
    String? username = await HelperFunctions.getUserNameFromSF();

    if (username == "trackerjo") {
      if (Platform.isAndroid) {
        // DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
        //     .syncUserCalendar(calendars[3].id!, DateTime.now(),
        //         DateTime.now().add(const Duration(days: 30)));
      } else {
        await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            .syncUserCalendar(userData["calendars"], DateTime.now(),
                DateTime.now().add(const Duration(days: 31)));
      }
    } else {
      await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
          .syncUserCalendar(userData["calendars"], DateTime.now(),
              DateTime.now().add(const Duration(days: 31)));
    }

    List<Map<String, dynamic>> suggestedPlans =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            .getSuggestedPlans(FirebaseAuth.instance.currentUser!.uid);

    if (mounted) {
      setState(() {
        suggestedPlansList = suggestedPlans;
      });
    }

    print("DONE");
  }

  getUserData() async {
    DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
        .getUserData(FirebaseAuth.instance.currentUser!.uid)
        .then((value) {
      setState(() {
        userData = value.data()!;
        numOfPendingPlans = value.data()!["pendingRequests"].length;
        print(userData);
        for (var i = 0; i < userData["friends"].length; i++) {
          _items.add(MultiSelectItem(getFriendId(userData["friends"][i]),
              getFriendDisplayName(userData["friends"][i])));
        }
        checkPermissions();
      });
    });
    DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
        .getUserPlansStream()
        .then((value) {
      setState(() {
        plansStream = value;
      });
    });

    DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
        .getUserPendingPlansStream()
        .then((value) {
      setState(() {
        pendingPlansStream = value;
      });
    });
  }

  void loadPageData() async {
    await getCurrentUserInfo();
    await getUserData();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadPageData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

//// override this function
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      /// when user opens app again you can launch url if not already launched.
      checkPermissions();
    }
  }

  getCurrentUserInfo() async {
    String? userDisplayNameSF =
        await HelperFunctions.getUserDisplayNameFromSF();
    String? emailSF = await HelperFunctions.getUserEmailFromSF();
    setState(() {
      displayName = userDisplayNameSF!;
      email = emailSF!;
    });
  }

  String getFriendId(String res) {
    return res.split("_")[0];
  }

  String getFriendUsername(String res) {
    return res.split("_")[1];
  }

  String getFriendDisplayName(String res) {
    return res.split("_")[2];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: MainAppBar(
            pageTitle: "Planner",
            displayName: displayName,
            email: email,
          ),
        ),
        bottomNavigationBar: MainNavBar(
            currentPageIndex: currentPageIndex,
            displayName: displayName,
            email: email),
        body: SizedBox(
          height: MediaQuery.of(context).size.height - 100,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                  height: 10,
                ),
                UpcomingPlans(
                  onTap: handleUpcomingPlansTap,
                  onEdit: handleUpcomingPlansEdit,
                  upcomingPlansStream: plansStream,
                ),
                const SizedBox(
                  height: 10,
                ),
                PendingPlans(
                    onTap: handlePendingPlansTap,
                    pendingPlansStream: pendingPlansStream),
                const SizedBox(
                  height: 10,
                ),
                SuggestedPlans(
                    suggestedPlansList: suggestedPlansList,
                    onTap: handleSuggestedPlansTap,
                    displayName: displayName,
                    email: email),
              ])
            ]),
          ),
        ));
  }
}
