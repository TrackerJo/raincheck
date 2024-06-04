import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raincheck/widgets/suggested_plan_time_tile.dart';

class SuggestedPlanDateTile extends StatefulWidget {
  final DateTime day;
  final Map<String, dynamic> dayData;
  final Function(DateTime, DateTime, DateTime, List<String>) selectTime;

  const SuggestedPlanDateTile(
      {super.key,
      required this.day,
      required this.dayData,
      required this.selectTime});

  @override
  State<SuggestedPlanDateTile> createState() => _SuggestedPlanDateTileState();
}

class _SuggestedPlanDateTileState extends State<SuggestedPlanDateTile> {
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

  generateTimeTiles() {
    List<Widget> inviteeTiles = [];
    for (var i = 0; i < widget.dayData["times"].length; i++) {
      inviteeTiles.add(
        SuggestedPlanTimeTile(
          startTime: widget.dayData["times"][i]["startTime"],
          endTime: widget.dayData["times"][i]["endTime"],
          invitees: widget.dayData["times"][i]["invitees"],
          selectTime: widget.selectTime,
          date: widget.day,
        ),
      );
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          collapsed: const Text(""),
          expanded: Column(
            children: generateTimeTiles(),
          ),
        ));
  }
}
