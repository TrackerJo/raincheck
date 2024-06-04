import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:raincheck/service/database_service.dart';
import 'package:raincheck/widgets/widgets.dart';

import '../helper/helper_function.dart';
import '../widgets/app_bar.dart';
import '../widgets/group_tile.dart';
import '../widgets/navigation_bar.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  int currentPageIndex = 2;
  String displayName = "";
  String email = "";
  String username = "";

  List<dynamic> userGroups = [];
  final List<MultiSelectItem<Object?>> friends = [];
  List<String> selectedGroupMembers = [];
  String groupName = "";
  final formKey = GlobalKey<FormState>();

  void getGroups() async {
    List<dynamic> groupsList =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            .getUserGroups(FirebaseAuth.instance.currentUser!.uid);
    setState(() {
      userGroups = groupsList;
    });
    getFriends();
  }

  void getFriends() async {
    Map<String, dynamic> userData =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            .getUserData(FirebaseAuth.instance.currentUser!.uid, asMap: true);
    setState(() {
      for (var i = 0; i < userData["friends"].length; i++) {
        friends.add(MultiSelectItem(
            "${getFriendId(userData["friends"][i])}_${getFriendUsername(userData["friends"][i])}_${getFriendDisplayName(userData["friends"][i])}",
            getFriendDisplayName(userData["friends"][i])));
      }
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
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUserInfo();
  }

  getCurrentUserInfo() async {
    String? userDisplayNameSF =
        await HelperFunctions.getUserDisplayNameFromSF();
    String? emailSF = await HelperFunctions.getUserEmailFromSF();
    String? usernameSF = await HelperFunctions.getUserNameFromSF();

    setState(() {
      displayName = userDisplayNameSF!;
      email = emailSF!;
      username = usernameSF!;
    });
    getGroups();
  }

  createGroup(context) async {
    String groupFullId = await DatabaseService(
            uid: FirebaseAuth.instance.currentUser!.uid)
        .createGroup(groupName, selectedGroupMembers,
            "${FirebaseAuth.instance.currentUser!.uid}_${username}_${displayName}");
    setState(() {
      userGroups.add(groupFullId);
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: MainAppBar(
          pageTitle: "Groups",
          displayName: displayName,
          email: email,
        ),
      ),
      bottomNavigationBar: MainNavBar(
          currentPageIndex: currentPageIndex,
          displayName: displayName,
          email: email),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          createGroupDialog(context);
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(
          Icons.add,
          size: 30,
          color: Colors.white,
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          groupsList(),
        ],
      ),
    );
  }

  groupsList() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 300,
      child: ListView.builder(
        itemCount: userGroups.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GroupTile(
              groupName: userGroups[index].split("_")[1],
              groupId: userGroups[index].split("_")[0],
              username: username,
            ),
          );
        },
      ),
    );
  }

  createGroupDialog(context) {
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
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      decoration: textInputDecoration.copyWith(
                        hintText: "Group Name",
                      ),
                      onChanged: (val) {
                        setState(() {
                          groupName = val;
                        });
                      },
                      validator: (val) {
                        return val!.isEmpty ? "Enter a group name" : null;
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    MultiSelectDialogField(
                      items: friends,
                      title: const Text("Select Group Members"),
                      dialogHeight: (friends.length * 50).toDouble(),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
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
                      buttonIcon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black,
                      ),
                      buttonText: const Text(
                        "Select Group Members",
                        style: TextStyle(color: Colors.black),
                      ),
                      onConfirm: (vals) {
                        setState(() {
                          selectedGroupMembers =
                              vals.map((e) => e.toString()).toList();
                          ;
                        });
                      },
                    )
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
                    if (formKey.currentState!.validate()) {
                      if (selectedGroupMembers.isNotEmpty) {
                        createGroup(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Please select at least one group member")));
                      }
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
