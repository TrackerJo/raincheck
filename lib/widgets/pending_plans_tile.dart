import 'package:flutter/material.dart';
import 'package:raincheck/widgets/plan_tile.dart';

class PendingPlans extends StatelessWidget {
  final Function onTap;
  final Stream? pendingPlansStream;
  const PendingPlans(
      {super.key, required this.onTap, required this.pendingPlansStream});

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
              Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Pending Plans",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  )),
              Padding(
                padding: const EdgeInsets.only(top: 50.0),
                child: pendingPlansList(),
              ),
            ],
          )),
    );
  }

  pendingPlansList() {
    return StreamBuilder(
      stream: pendingPlansStream,
      builder: (context, AsyncSnapshot snapshot) {
        //Make checks
        if (snapshot.hasData) {
          if (snapshot.data!.docs.length != null) {
            if (snapshot.data.docs.length != 0) {
              return SizedBox(
                height: MediaQuery.of(context).size.height,
                child: ListView.builder(
                    clipBehavior: Clip.hardEdge,
                    itemCount: snapshot.data.docs.length,
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
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: PlanTile(
                            planData:
                                objectToMap(snapshot.data.docs[index].data()),
                            isIncoming: true),
                      );
                    }),
              );
            } else {
              return Center(child: noPendingPlansWidget());
            }
          } else {
            return Center(child: noPendingPlansWidget());
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

  noPendingPlansWidget() {
    return Container(
      child: Text("No pending plans"),
    );
  }
}
