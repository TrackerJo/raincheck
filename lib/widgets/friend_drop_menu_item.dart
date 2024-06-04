import 'package:flutter/material.dart';

class FriendDropMenuItem extends StatelessWidget {
  final String displayName;
  final String userId;
  final bool isSelected;
  final Function() toggleSelected;
  const FriendDropMenuItem(
      {super.key,
      required this.displayName,
      required this.userId,
      required this.isSelected,
      required this.toggleSelected});

  @override
  Widget build(BuildContext context) {
    return DropdownMenuItem(
        child: ListTile(
      title: Text(displayName),
      onTap: () {},
    ));
  }
}
