import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raincheck/widgets/plan_invitee_tile.dart';

class PlannedDayAvailabilityTile extends StatefulWidget {
  final DateTime day;
  final List<Map<String, dynamic>> invitees;
  final Function(DateTime) selectDate;

  const PlannedDayAvailabilityTile(
      {super.key,
      required this.day,
      required this.invitees,
      required this.selectDate});

  @override
  State<PlannedDayAvailabilityTile> createState() =>
      _PlannedDayAvailabilityTileState();
}

class _PlannedDayAvailabilityTileState
    extends State<PlannedDayAvailabilityTile> {
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
          displayName: getFriendDisplayName(widget.invitees[i]['id']),
          username: getFriendUsername(widget.invitees[i]['id']),
          isAvailable: widget.invitees[i]['isFree']));
    }
    return inviteeTiles;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                DateFormat('EEEE, MMMM d, y').format(widget.day),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  widget.selectDate(widget.day);
                },
                splashRadius: 20,
                icon:
                    const Icon(Icons.check_circle_outline, color: Colors.green),
              ),
            ],
          ),
          collapsed: const Text(""),
          expanded: Column(
            children: generateInviteeTiles(),
          ),
        ));
  }
}
