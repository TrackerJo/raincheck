import 'package:flutter/material.dart';

class FriendsTopMenu extends StatelessWidget {
  final int selectedMenuIndex;
  final Function(int) changeSelectedMenuIndex;

  const FriendsTopMenu(
      {super.key,
      required this.selectedMenuIndex,
      required this.changeSelectedMenuIndex});

  @override
  Widget build(BuildContext context) {
    const Color selectedColor = Colors.orange;
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () {
                changeSelectedMenuIndex(0);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  border: Border(
                    bottom: BorderSide(
                      color: selectedColor,
                      width: selectedMenuIndex != 0 ? 0 : 5,
                    ),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Friends",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () {
                changeSelectedMenuIndex(1);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  border: Border(
                    bottom: BorderSide(
                      color: selectedColor,
                      width: selectedMenuIndex != 1 ? 0 : 5,
                    ),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Center(
                    child: Text(
                      "Outgoing Requests",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () {
                changeSelectedMenuIndex(2);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  border: Border(
                    bottom: BorderSide(
                      color: selectedColor,
                      width: selectedMenuIndex != 2 ? 0 : 5,
                    ),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Center(
                    child: Text(
                      "Pending Requests",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
