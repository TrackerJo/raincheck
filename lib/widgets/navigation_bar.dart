import 'package:flutter/material.dart';
import 'package:raincheck/pages/friends_page.dart';
import 'package:raincheck/pages/groups_page.dart';
import 'package:raincheck/pages/planner_page.dart';
import 'package:raincheck/pages/plans_page.dart';

import 'custom_page_route.dart';

class MainNavBar extends StatefulWidget {
  final int currentPageIndex;
  final String displayName;
  final String email;

  const MainNavBar({
    super.key,
    required this.currentPageIndex,
    required this.displayName,
    required this.email,
  });

  @override
  State<MainNavBar> createState() => _MainNavBarState();
}

class _MainNavBarState extends State<MainNavBar> {
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 75,
      onDestinationSelected: (int index) {
        if (index == 0 && widget.currentPageIndex != 0) {
          Navigator.of(context).pushReplacement(
            CustomPageRoute(
              builder: (BuildContext context) {
                return const FriendsPage();
              },
            ),
          );
          //nextScreen(context, const HomePage());
        } else if (index == 1 && widget.currentPageIndex != 1) {
          Navigator.of(context).pushReplacement(
            CustomPageRoute(
              builder: (BuildContext context) {
                return const PlannerPage();
              },
            ),
          );
        } else if (index == 2 && widget.currentPageIndex != 2) {
          Navigator.of(context).pushReplacement(
            CustomPageRoute(
              builder: (BuildContext context) {
                return const GroupsPage();
              },
            ),
          );
        }
      },
      selectedIndex: widget.currentPageIndex,
      destinations: <Widget>[
        NavigationDestination(
          icon: widget.currentPageIndex != 0
              ? const Icon(Icons.group_outlined)
              : const Icon(Icons.group),
          label: 'Friends',
          tooltip: "Friends",
        ),
        NavigationDestination(
          icon: widget.currentPageIndex != 1
              ? const Icon(Icons.calendar_month_outlined)
              : const Icon(Icons.calendar_month),
          label: 'Planner',
          tooltip: "Planner",
        ),
        NavigationDestination(
          icon: widget.currentPageIndex != 2
              ? const Icon(Icons.groups_outlined)
              : const Icon(Icons.groups),
          label: 'Groups',
          tooltip: "Groups",
        ),
      ],
    );
  }
}
