import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raincheck/widgets/plan_invitee_tile.dart';

class SuggestedPlanTimeTile extends StatefulWidget {
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> invitees;
  final Function(DateTime, DateTime, DateTime, List<String>) selectTime;

  const SuggestedPlanTimeTile(
      {super.key,
      required this.startTime,
      required this.endTime,
      required this.invitees,
      required this.selectTime,
      required this.date});

  @override
  State<SuggestedPlanTimeTile> createState() => _SuggestedPlanTimeTileState();
}

class _SuggestedPlanTimeTileState extends State<SuggestedPlanTimeTile> {
  ExpandableController controller = ExpandableController(initialExpanded: true);

  String getFriendId(String res) {
    return res.split("_")[0];
  }

  String getFriendUsername(String res) {
    return res.split("_")[1];
  }

  String getFriendDisplayName(String res) {
    return res.split("_")[2];
  }

  generateInviteeTiles() {
    List<Widget> inviteeTiles = [];
    for (var i = 0; i < widget.invitees.length; i++) {
      inviteeTiles.add(PlanInviteeTile(
          displayName: getFriendDisplayName(widget.invitees[i]),
          username: getFriendUsername(widget.invitees[i]),
          isAvailable: true));
    }
    return inviteeTiles;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: SizedBox(
          width: 300,
          child: ExpandablePanel(
            controller: controller,
            theme: const ExpandableThemeData(
              headerAlignment: ExpandablePanelHeaderAlignment.center,
              tapBodyToCollapse: false,
              tapBodyToExpand: false,
              hasIcon: true,
            ),
            header: Row(
              children: [
                Text(
                  "${DateFormat('h:mm a').format(widget.startTime)} - ${DateFormat('h:mm a').format(widget.endTime)}",
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    widget.selectTime(widget.date, widget.startTime,
                        widget.endTime, widget.invitees);
                  },
                  splashRadius: 20,
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.green),
                ),
              ],
            ),
            collapsed: const Text(""),
            expanded: Column(
              children: generateInviteeTiles(),
            ),
          )),
    );
  }
}
