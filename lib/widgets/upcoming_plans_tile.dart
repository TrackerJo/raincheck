import 'package:flutter/material.dart';
import 'package:raincheck/widgets/plan_tile.dart';

class UpcomingPlans extends StatelessWidget {
  final Function onTap;
  final Function(BuildContext) onEdit;
  final Stream? upcomingPlansStream;
  const UpcomingPlans(
      {super.key,
      required this.onTap,
      required this.onEdit,
      required this.upcomingPlansStream});

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
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.edit_calendar_outlined),
                  onPressed: () {
                    onEdit(context);
                  },
                  splashRadius: 20,
                ),
              ),
              Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Upcoming Plans",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 40.0, bottom: 5),
                child: upcomingPlansList(),
              ),
            ],
          )),
    );
  }

  upcomingPlansList() {
    return StreamBuilder(
      stream: upcomingPlansStream,
      builder: (context, AsyncSnapshot snapshot) {
        //Make checks
        if (snapshot.hasData) {
          if (snapshot.data!.docs.length != null) {
            if (snapshot.data.docs.length != 0) {
              return SizedBox(
                height: MediaQuery.of(context).size.height,
                child: ListView.builder(
                    clipBehavior: Clip.hardEdge,
                    shrinkWrap: true,
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

  noPlansWidget() {
    return Container(
      child: Text("No upcoming plans"),
    );
  }
}
