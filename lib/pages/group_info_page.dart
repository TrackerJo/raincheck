import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:raincheck/pages/plan_creation_page.dart';
import 'package:raincheck/pages/plan_page.dart';
import 'package:raincheck/pages/planner_page.dart';
import 'package:raincheck/widgets/group_member_tile.dart';

import '../service/database_service.dart';
import '../widgets/app_bar.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/widgets.dart';

class GroupInfoPage extends StatefulWidget {
  final String email;
  final String displayName;
  final String groupId;
  final String username;
  const GroupInfoPage(
      {super.key,
      required this.email,
      required this.displayName,
      required this.groupId,
      required this.username});

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  Map<String, dynamic> groupData = {};
  Map<String, dynamic> userData = {};
  bool isOwner = false;

  List<DropdownMenuItem> friends = [];
  String selectedFriend = "";

  final addMemberFormKey = GlobalKey<FormState>();
  final createPlanFormKey = GlobalKey<FormState>();

  int minAttendees = 0;

  getGroupData() async {
    Map<String, dynamic> groupDataDB =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            .getGroupData(widget.groupId);
    String fullUserId =
        "${FirebaseAuth.instance.currentUser!.uid}_${widget.username}_${widget.displayName}";
    setState(() {
      groupData = groupDataDB;
      isOwner = groupData["owner"] == fullUserId;
      if (!isOwner) {
        groupData["members"].remove(fullUserId);
        groupData["members"].insert(0, groupData["owner"]);
      }
      minAttendees = groupData["members"].length;
    });
    getUserData();
  }

  getUserData() async {
    Map<String, dynamic> userDataDB =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            .getUserData(FirebaseAuth.instance.currentUser!.uid, asMap: true);
    setState(() {
      userData = userDataDB;
    });
    generateFriendsList();
  }

  generateFriendsList() {
    List<DropdownMenuItem> friendsList = [];
    for (var friend in userData["friends"]) {
      if (groupData["members"].contains(friend)) {
        continue;
      }
      friendsList.add(DropdownMenuItem(
        child: Text(friend.split("_")[2]),
        value: friend,
      ));
    }
    setState(() {
      friends = friendsList;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getGroupData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
            title: const Text(
              "Group Info",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold),
            ),
            actions: [
              isOwner
                  ? IconButton(
                      onPressed: () {
                        confirmDeleteGroupDialog(context);
                      },
                      icon: const Icon(Icons.delete),
                      color: Colors.white,
                    )
                  : IconButton(
                      onPressed: () {
                        confirmLeaveGroupDialog(context);
                      },
                      icon: const Icon(Icons.exit_to_app),
                      color: Colors.white,
                    ),
            ]),
        body: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                ),
                Text(
                  "Group Name: ${groupData['name']}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                    onPressed: () {
                      createGroupPlanDialog(context);
                    },
                    child: const Text("Create Plan")),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Members',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(
                      width: 10,
                    ),
                    IconButton(
                      onPressed: () {
                        addGroupMemberDialog(context);
                      },
                      icon: const Icon(Icons.person_add),
                      splashRadius: 20,
                    )
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: groupData['members'] != null
                      ? ListView.builder(
                          itemCount: groupData['members'].length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GroupMemberTile(
                                memberName:
                                    groupData["members"][index].split("_")[2],
                                memberUsername:
                                    groupData["members"][index].split("_")[1],
                              ),
                            );
                          },
                        )
                      : const CircularProgressIndicator(),
                ),
              ],
            ),
          ),
        ));
  }

  confirmLeaveGroupDialog(context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Leave Group"),
            content: Text("Are you sure you want to leave this group?"),
            actions: [
              ElevatedButton(
                  onPressed: () async {
                    await DatabaseService(
                            uid: FirebaseAuth.instance.currentUser!.uid)
                        .leaveGroup("${widget.groupId}_${groupData['name']}",
                            "${FirebaseAuth.instance.currentUser!.uid}_${widget.username}_${widget.displayName}");
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text("Yes")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("No")),
            ],
          );
        });
  }

  confirmDeleteGroupDialog(context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Delete Group"),
            content: Text("Are you sure you want to delete this group?"),
            actions: [
              ElevatedButton(
                  onPressed: () async {
                    await DatabaseService(
                            uid: FirebaseAuth.instance.currentUser!.uid)
                        .deleteGroup("${widget.groupId}_${groupData['name']}");
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text("Yes")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("No")),
            ],
          );
        });
  }

  addGroupMemberDialog(context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Add Member"),
            content: Form(
              key: addMemberFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Select a friend to add to the group"),
                  const SizedBox(
                    height: 10,
                  ),
                  friends.length > 0
                      ? DropdownButtonFormField(
                          decoration: textInputDecoration.copyWith(
                              hintText: "Select a friend"),
                          items: friends,
                          onChanged: (value) {
                            setState(() {
                              selectedFriend = value.toString();
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return "Please select a friend";
                            }
                            return null;
                          },
                        )
                      : Text("No friends to add"),
                ],
              ),
            ),
            actions: [
              friends.length > 0
                  ? ElevatedButton(
                      onPressed: () async {
                        if (addMemberFormKey.currentState!.validate()) {
                          await DatabaseService(
                                  uid: FirebaseAuth.instance.currentUser!.uid)
                              .addGroupMember(
                                  "${widget.groupId}_${groupData['name']}",
                                  selectedFriend);
                          await getGroupData();
                          Navigator.pop(context);
                        }
                      },
                      child: Text("Add Memeber"))
                  : ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Ok")),
              friends.length > 0
                  ? ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Cancel"))
                  : Container(),
            ],
          );
        });
  }

  createGroupPlanDialog(context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                "Create Group",
                textAlign: TextAlign.left,
              ),
              content: Form(
                key: createPlanFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 200,
                            child: Text(
                              "What is the minimum number of people who can attend to be a possible plan?",
                              style: TextStyle(fontSize: 16),
                            )),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      decoration: textInputDecoration.copyWith(
                        hintText: "Minimum attendees",
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: groupData["members"].length.toString(),
                      onChanged: (val) {
                        setState(() {
                          if (val == null || val.isEmpty) {
                            minAttendees = 0;
                          } else {
                            minAttendees = int.parse(val);
                          }
                        });
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "Please enter a number";
                        } else if (int.parse(val) >
                            groupData["members"].length) {
                          return "Please enter a number less than the number of group members";
                        } else if (int.parse(val) < 1) {
                          return "Please enter a number greater than 0";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (createPlanFormKey.currentState!.validate()) {
                      print("VALIDATING");
                      Navigator.pop(context);
                      nextScreen(
                          context,
                          PlanCreationPage(
                            displayName: widget.displayName,
                            email: widget.email,
                            planType: PlanType.group,
                            friends: [],
                            minAttendees: minAttendees,
                            groupId: widget.groupId,
                          ));
                    }
                  },
                  child: const Text("Create"),
                ),
              ],
            );
          });
        });
  }
}
