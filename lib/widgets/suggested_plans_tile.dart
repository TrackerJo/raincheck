import 'package:flutter/material.dart';
import 'package:raincheck/widgets/plan_tile.dart';
import 'package:raincheck/widgets/suggested_plan_tile.dart';

class SuggestedPlans extends StatelessWidget {
  final onTap;
  final List<Map<String, dynamic>> suggestedPlansList;
  final String displayName;
  final String email;
  const SuggestedPlans(
      {super.key,
      required this.suggestedPlansList,
      required this.onTap,
      required this.displayName,
      required this.email});

  Map<String, dynamic> objectToMap(Object? obj) {
    Map<String, dynamic> map = {};
    Map<String, dynamic> objMap = obj as Map<String, dynamic>;

    return objMap;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 200,
          decoration: BoxDecoration(
            color: const Color.fromARGB(80, 33, 149, 243),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              // Positioned(
              //   top: 0,
              //   right: 0,
              //   child: IconButton(
              //     icon: Icon(Icons.edit_calendar_outlined),
              //     onPressed: () {
              //       onEdit(context);
              //     },
              //     splashRadius: 20,
              //   ),
              // ),
              Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Suggested Plans",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 40.0, bottom: 5),
                child: upcomingPlansList(context),
              ),
            ],
          )),
    );
  }

  upcomingPlansList(context) {
    if (suggestedPlansList.length == 0) {
      return noPlansWidget();
    } else {
      return SizedBox(
        height: MediaQuery.of(context).size.height,
        child: ListView.builder(
          clipBehavior: Clip.hardEdge,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: suggestedPlansList.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: SuggestedPlanTile(
                planData: objectToMap(suggestedPlansList[index]),
                displayName: displayName,
                email: email,
              ),
            );
          },
        ),
      );
    }
  }

  noPlansWidget() {
    return Container(
      child: Text("No upcoming plans"),
    );
  }
}
