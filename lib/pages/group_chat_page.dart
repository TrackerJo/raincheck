import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:raincheck/pages/group_info_page.dart';
import 'package:raincheck/widgets/widgets.dart';

import '../helper/helper_function.dart';
import '../service/database_service.dart';
import '../widgets/message_tile.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String username;

  const GroupChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.username,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  Stream<QuerySnapshot>? chats;
  TextEditingController messageController = TextEditingController();
  String displayName = "";
  String email = "";

  @override
  void initState() {
    // TODO: implement initState
    getChats();
    getUserData();
    super.initState();
  }

  getUserData() async {
    String? displayNameSF = await HelperFunctions.getUserDisplayNameFromSF();
    String? emailSF = await HelperFunctions.getUserEmailFromSF();
    if (displayNameSF != null && emailSF != null) {
      setState(() {
        displayName = displayNameSF;
        email = emailSF;
      });
    }
  }

  getChats() {
    DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
        .getGroupChats(widget.groupId)
        .then((val) {
      setState(() {
        chats = val;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.groupName),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            onPressed: () {
              nextScreen(
                  context,
                  GroupInfoPage(
                    email: email,
                    displayName: displayName,
                    groupId: widget.groupId,
                    username: widget.username,
                  ));
            },
            icon: const Icon(Icons.info),
            splashRadius: 20,
          ),
        ],
      ),
      body: Stack(
        children: [
          //Chat Messages
          chatMessages(),
          Container(
            alignment: Alignment.bottomCenter,
            width: MediaQuery.of(context).size.width,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              width: MediaQuery.of(context).size.width,
              color: Theme.of(context).primaryColor,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: messageController,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Type a message",
                        hintStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      sendMessage();
                    },
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  chatMessages() {
    return StreamBuilder(
        stream: chats,
        builder: (context, AsyncSnapshot snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    return MessageTile(
                        message: snapshot.data.docs[index]['message'],
                        sender: snapshot.data.docs[index]['senderDisplayName'],
                        sentByMe: widget.username ==
                            snapshot.data.docs[index]['senderUsername'],
                        time: snapshot.data.docs[index]['time'].toDate());
                  })
              : Container();
        });
  }

  sendMessage() {
    if (messageController.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        "message": messageController.text,
        "senderUsername": widget.username,
        "senderId": FirebaseAuth.instance.currentUser!.uid,
        "senderDisplayName": displayName,
        "time": DateTime.now(),
      };

      DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
          .sendGroupMessage(widget.groupId, chatMessageMap);
      setState(() {
        messageController.clear();
      });
    }
  }
}
