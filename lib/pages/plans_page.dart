import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:raincheck/pages/plan_creation_page.dart';
import 'package:raincheck/pages/planner_page.dart';
import 'package:raincheck/service/database_service.dart';
import 'package:raincheck/widgets/navigation_bar.dart';
import 'package:raincheck/widgets/plan_tile.dart';
import 'package:raincheck/widgets/plans_top_menu.dart';
import 'package:raincheck/widgets/suggested_plan_tile.dart';
import '../helper/calendar_functions.dart';
import '../helper/helper_function.dart';
import '../service/notification_service.dart';
import '../widgets/app_bar.dart';
import '../widgets/widgets.dart';

enum PlanView { myPlans, pendingPlans, suggestedPlans }

class PlansPage extends StatefulWidget {
  final PlanView currentPlanView;
  const PlansPage({super.key, required this.currentPlanView});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> with WidgetsBindingObserver {
  int currentPageIndex = 1;
  int numOfPendingPlans = 0;
  String displayName = "";
  String email = "";

  Stream? plansStream;
  Stream? pendingPlansStream;

  List<Map<String, dynamic>> suggestedPlans = [];

  PlanType _planType = PlanType.friends;
  PlanView _planView = PlanView.myPlans;

  changePlanView(PlanView view) {
    setState(() {
      _planView = view;
    });
  }

  Map<String, dynamic> userData = {};
  final List<MultiSelectItem<Object?>> _items = [];

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

    List<Map<String, dynamic>> suggestedPlansList =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            .getSuggestedPlans(FirebaseAuth.instance.currentUser!.uid);
    if (mounted) {
      setState(() {
        suggestedPlans = suggestedPlansList;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUserInfo();
    getUserData();
    setState(() {
      _planView = widget.currentPlanView;
    });
  }

//// override this function

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

  Map<String, dynamic> objectToMap(Object? obj) {
    Map<String, dynamic> map = {};
    Map<String, dynamic> objMap = obj as Map<String, dynamic>;

    return objMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: MainAppBar(
          pageTitle: "Plans",
          displayName: displayName,
          email: email,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          choosePlanType(context);
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(
          Icons.edit_calendar_outlined,
          size: 30,
          color: Colors.white,
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlansTopMenu(
              planView: _planView,
              changePlanView: changePlanView,
              numOfPendingPlans: numOfPendingPlans),
          //Check if user is android or ios
          if (Platform.isAndroid)
            ElevatedButton(
                onPressed: () async {
                  await NotificationService().sendNotificationToDevice(
                      "eQMhyyOpSYC9aRO8l9YG9S:APA91bGkhEURLlyDND0V10zG3TX26i9uU5D8WQDem4ffYJc0vkfoCj9Zm7OMO8BTUTvJDWzZPQmoDBQGyPvaje40-SqZF7uQE79MoTVRsZfvPOz9UAwBNZ9EHTOVHmtm1in-feugcqB_",
                      'Test from Device',
                      "Sent from device",
                      "test");
                },
                child: const Text("Send Test Notification")),

          _planView == PlanView.myPlans
              ? plansList()
              : _planView == PlanView.pendingPlans
                  ? pendingPlansList()
                  : suggestedPlansList(),
          // SizedBox(
          //   height: MediaQuery.of(context).size.height - 300,
          //   child: ListView(
          //     clipBehavior: Clip.hardEdge,
          //     shrinkWrap: true,
          //     semanticChildCount: myPlans.length,
          //     children: [
          //       ...myPlanList(),
          //     ],
          //   ),
          // )
        ],
      ),
    );
  }

  plansList() {
    return StreamBuilder(
      stream: plansStream,
      builder: (context, AsyncSnapshot snapshot) {
        //Make checks
        if (snapshot.hasData) {
          if (snapshot.data!.docs.length != null) {
            if (snapshot.data.docs.length != 0) {
              return SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: ListView.builder(
                    clipBehavior: Clip.hardEdge,
                    itemCount: snapshot.data.docs.length,
                    itemBuilder: (context, index) {
                      //int reverseIndex = snapshot.data.docs.length - index - 1;
                      // bool isWinner = false;
                      // DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
                      //     .getIsWinner(
                      //         getId(snapshot.data["games"][reverseIndex]),
                      //         widget.groupId,
                      //         userName)
                      //     .then((value) {
                      //   setState(() {
                      //     isWinner = value;
                      //   });
                      // });
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: PlanTile(
                            planData:
                                objectToMap(snapshot.data.docs[index].data()),
                            isIncoming: false),
                      );
                    }),
              );
            } else {
              return Center(child: noPlansWidget());
            }
          } else {
            return Center(child: noPlansWidget());
          }
        } else {
          return Center(
              child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ));
        }
      },
    );
  }

  pendingPlansList() {
    return StreamBuilder(
      stream: pendingPlansStream,
      builder: (context, AsyncSnapshot snapshot) {
        //Make checks
        if (snapshot.hasData) {
          if (snapshot.data!.docs.length != null) {
            if (snapshot.data.docs.length != 0) {
              return SizedBox(
                height: MediaQuery.of(context).size.height - 300,
                child: ListView.builder(
                    clipBehavior: Clip.hardEdge,
                    itemCount: snapshot.data.docs.length,
                    itemBuilder: (context, index) {
                      // bool isWinner = false;
                      // DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
                      //     .getIsWinner(
                      //         getId(snapshot.data["games"][reverseIndex]),
                      //         widget.groupId,
                      //         userName)
                      //     .then((value) {
                      //   setState(() {
                      //     isWinner = value;
                      //   });
                      // });
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: PlanTile(
                            planData:
                                objectToMap(snapshot.data.docs[index].data()),
                            isIncoming: true),
                      );
                    }),
              );
            } else {
              return Center(child: noPendingPlansWidget());
            }
          } else {
            return Center(child: noPendingPlansWidget());
          }
        } else {
          return Center(
              child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ));
        }
      },
    );
  }

  suggestedPlansList() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 300,
      child: ListView.builder(
          clipBehavior: Clip.hardEdge,
          itemCount: suggestedPlans.length,
          itemBuilder: (context, index) {
            // bool isWinner = false;
            // DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            //     .getIsWinner(
            //         getId(snapshot.data["games"][reverseIndex]),
            //         widget.groupId,
            //         userName)
            //     .then((value) {
            //   setState(() {
            //     isWinner = value;
            //   });
            // });
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: SuggestedPlanTile(
                planData: suggestedPlans[index],
                displayName: userData["username"],
                email: userData["email"],
              ),
            );
          }),
    );
  }

  noPlansWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
          ),
          Text(
            "You haven't created any plans yet, tap on the add icon to create a plan.",
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  noPendingPlansWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
          ),
          Text(
            "You have no pending plans.",
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
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
}
