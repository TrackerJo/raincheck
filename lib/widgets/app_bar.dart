import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:raincheck/pages/profile_page.dart';
import 'package:raincheck/widgets/widgets.dart';

class MainAppBar extends StatefulWidget {
  final String pageTitle;
  final String displayName;
  final String email;

  const MainAppBar(
      {super.key,
      required this.pageTitle,
      required this.displayName,
      required this.email});

  @override
  State<MainAppBar> createState() => _MainAppBarState();
}

class _MainAppBarState extends State<MainAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        widget.pageTitle,
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            onPressed: () {
              nextScreen(
                  context,
                  ProfilePage(
                    uid: FirebaseAuth.instance.currentUser!.uid,
                  ));
            },
            icon: const Icon(
              Icons.account_circle,
              size: 35,
            ),
            splashRadius: 25,
          ),
        )
      ],
    );
  }
}
