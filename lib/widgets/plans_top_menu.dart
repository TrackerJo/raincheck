import 'package:flutter/material.dart';
import 'package:raincheck/pages/plans_page.dart';

class PlansTopMenu extends StatelessWidget {
  final PlanView planView;
  final Function(PlanView) changePlanView;
  final int numOfPendingPlans;

  const PlansTopMenu(
      {super.key,
      required this.planView,
      required this.changePlanView,
      required this.numOfPendingPlans});

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
                changePlanView(PlanView.myPlans);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  border: Border(
                    bottom: BorderSide(
                      color: selectedColor,
                      width: planView != PlanView.myPlans ? 0 : 5,
                    ),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Plans",
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
                changePlanView(PlanView.pendingPlans);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  border: Border(
                    bottom: BorderSide(
                      color: selectedColor,
                      width: planView != PlanView.pendingPlans ? 0 : 5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Plan Requests",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              numOfPendingPlans.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                changePlanView(PlanView.suggestedPlans);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  border: Border(
                    bottom: BorderSide(
                      color: selectedColor,
                      width: planView != PlanView.suggestedPlans ? 0 : 5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Plan Suggestions",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
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
