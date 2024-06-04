import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:raincheck/widgets/app_bar.dart';
import 'package:raincheck/widgets/friends_top_menu.dart';
import 'package:raincheck/widgets/friend_tile.dart';
import 'package:raincheck/widgets/outgoing_friend_request_tile.dart';

import '../helper/helper_function.dart';
import '../service/database_service.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/pending_friend_request_tile.dart';
import '../widgets/widgets.dart';

class FriendsPage extends StatefulWidget {
  static const route = '/friends-page';
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  int currentPageIndex = 0;
  String displayName = "";
  String email = "";
  int selectedMenuIndex = 0;

  String inviteUserName = "";

  Stream? userData;
  bool readMessage = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUserInfo();
    getFriendsFromDB();
  }

  getFriendsFromDB() {
    DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
        .getCurrentUserDataStream()
        .then((snapshot) {
      setState(() {
        userData = snapshot;
      });
    });
  }

  changeSelectedMenuIndex(int index) {
    setState(() {
      selectedMenuIndex = index;
    });
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
    final message =
        ModalRoute.of(context)!.settings.arguments as RemoteMessage?;
    if (message != null && !readMessage) {
      setState(() {
        selectedMenuIndex = 2;
        readMessage = true;
      });
      print("HANDLE MESSAGE IN FRIENDS PAGE");
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: MainAppBar(
          pageTitle: "Friends",
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
          addFriend(context);
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(
          Icons.person_add,
          size: 30,
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          FriendsTopMenu(
              selectedMenuIndex: selectedMenuIndex,
              changeSelectedMenuIndex: changeSelectedMenuIndex),
          if (selectedMenuIndex == 0) friendsList(),
          if (selectedMenuIndex == 1) outgoingRequestsList(),
          if (selectedMenuIndex == 2) pendingRequestsList(),
        ],
      ),
    );
  }

  friendsList() {
    return StreamBuilder(
      stream: userData,
      builder: (context, AsyncSnapshot snapshot) {
        //Make checks
        if (snapshot.hasData) {
          if (snapshot.data["friends"].length != null) {
            if (snapshot.data["friends"].length != 0) {
              return SizedBox(
                height: MediaQuery.of(context).size.height - 300,
                child: ListView.builder(
                    clipBehavior: Clip.hardEdge,
                    itemCount: snapshot.data["friends"].length,
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
                      return FriendTile(
                        displayName: getFriendDisplayName(
                            snapshot.data["friends"][index]),
                        userId: getFriendId(snapshot.data["friends"][index]),
                        username:
                            getFriendUsername(snapshot.data["friends"][index]),
                      );
                    }),
              );
            } else {
              return Center(child: noFriendsWidget());
            }
          } else {
            return Center(child: noFriendsWidget());
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

  outgoingRequestsList() {
    return StreamBuilder(
      stream: userData,
      builder: (context, AsyncSnapshot snapshot) {
        //Make checks
        if (snapshot.hasData) {
          if (snapshot.data["outgoingRequests"].length != null) {
            if (snapshot.data["outgoingRequests"].length != 0) {
              return SizedBox(
                height: MediaQuery.of(context).size.height - 300,
                child: ListView.builder(
                    clipBehavior: Clip.hardEdge,
                    itemCount: snapshot.data["outgoingRequests"].length,
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
                      return OutgoingFriendRequestTile(
                          displayName: getFriendDisplayName(
                              snapshot.data["outgoingRequests"][index]),
                          userId: getFriendId(
                              snapshot.data["outgoingRequests"][index]),
                          username: getFriendUsername(
                              snapshot.data["outgoingRequests"][index]));
                    }),
              );
            } else {
              return Center(child: noOutgoingWidget());
            }
          } else {
            return Center(child: noOutgoingWidget());
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

  pendingRequestsList() {
    return StreamBuilder(
      stream: userData,
      builder: (context, AsyncSnapshot snapshot) {
        //Make checks
        if (snapshot.hasData) {
          if (snapshot.data["pendingRequests"].length != null) {
            if (snapshot.data["pendingRequests"].length != 0) {
              return SizedBox(
                height: MediaQuery.of(context).size.height - 300,
                child: ListView.builder(
                    clipBehavior: Clip.hardEdge,
                    itemCount: snapshot.data["pendingRequests"].length,
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
                      return PendingFriendRequestTile(
                          displayName: getFriendDisplayName(
                              snapshot.data["pendingRequests"][index]),
                          userId: getFriendId(
                              snapshot.data["pendingRequests"][index]),
                          username: getFriendUsername(
                              snapshot.data["pendingRequests"][index]));
                    }),
              );
            } else {
              return Center(child: noPendingWidget());
            }
          } else {
            return Center(child: noPendingWidget());
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

  addFriend(context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                "Invite Friend",
                textAlign: TextAlign.left,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    autocorrect: false,
                    decoration: textInputDecoration.copyWith(
                        labelText: "Friend's Username",
                        hintText: "Enter Friend's Username",
                        prefixIcon: const Icon(Icons.person)),
                    validator: (val) {
                      return val!.isEmpty ? "Enter a username" : null;
                    },
                    onChanged: (val) {
                      setState(() {
                        inviteUserName = val;
                      });
                    },
                  )
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    bool doesUserExist = await DatabaseService()
                        .checkIfUsernameExists(inviteUserName);
                    if (!doesUserExist) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              "User with username $inviteUserName does not exist")));
                      return;
                    }

                    await DatabaseService(
                            uid: FirebaseAuth.instance.currentUser!.uid)
                        .inviteFriend(inviteUserName);
                    setState(() {
                      inviteUserName = "";
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text("Invite Friend"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      inviteUserName = "";
                    });
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

  noFriendsWidget() {
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
            "You haven't invited any friends yet, tap on the add icon to invite a friend.",
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  noPendingWidget() {
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
            "You have no pending friend requests.",
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  noOutgoingWidget() {
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
            "You have no outgoing friends requests yet, tap on the add icon to invite a friend.",
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}
