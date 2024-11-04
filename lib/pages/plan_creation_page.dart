import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:raincheck/pages/planner_page.dart';
import 'package:raincheck/pages/plans_page.dart';
import 'package:raincheck/service/database_service.dart';
import 'package:raincheck/widgets/suggested_plan_date_tile.dart';
import 'package:raincheck/widgets/widgets.dart';

import '../helper/calendar_functions.dart';
import '../widgets/app_bar.dart';
import '../widgets/planned_day_availability_tile.dart';
import '../widgets/review_plan_invitee_tile.dart';

class PlanCreationPage extends StatefulWidget {
  final String displayName;
  final String email;
  final PlanType planType;
  final List<MultiSelectItem<Object?>> friends;
  final String startTime;
  final String endTime;
  final String startDate;
  final String endDate;
  final List<Map<String, dynamic>> invitees;
  final List<String> selectedFriends;
  final String date; //Format: yyyy-MM-dd
  final String planName;
  final int minAttendees;
  final String groupId;

  const PlanCreationPage(
      {super.key,
      required this.displayName,
      required this.email,
      required this.planType,
      required this.friends,
      this.startTime = "",
      this.endTime = "",
      this.startDate = "",
      this.endDate = "",
      this.invitees = const [],
      this.selectedFriends = const [],
      this.date = "",
      this.planName = "",
      this.minAttendees = 0, //Default to 0
      this.groupId = ""});

  @override
  State<PlanCreationPage> createState() => _PlanCreationPageState();
}

enum PlanCreationStep {
  selectDateRange,
  selectInvitees,
  selectDate,
  selectPlanName,
  reviewPlan,
  selectBetterTimes,
}

enum SelectBetterTimesStep {
  enterParameters,
  selectSuggestedTime,
  selectPlanTime,
}

class _PlanCreationPageState extends State<PlanCreationPage> {
  PlanCreationStep _currentStep = PlanCreationStep.selectDateRange;
  SelectBetterTimesStep _selectBetterTimesStep =
      SelectBetterTimesStep.enterParameters;

  final planNameFormKey = GlobalKey<FormState>();
  final planDateRangeFormKey = GlobalKey<FormState>();
  final suggestBetterTimesFormKey = GlobalKey<FormState>();
  final selectPlanTimeFormKey = GlobalKey<FormState>();
  final selectGroupFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSendingPlan = false;

  final Map<String, dynamic> _plan = {
    'name': '',
    'startTime': '',
    'endTime': '',
    'invitees': [],
    'description': '',
    'date': '',
  };

  List<Map<String, dynamic>> invitees = [];
  List<Map<String, dynamic>> suggestedTimes = [];

  List<dynamic> userGroups = [];
  int minAttendees = 0;
  List<DropdownMenuItem<String>> groupDropdownItems = [];
  String selectedGroup = "";

  List<String> selectedFriends = [];

  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController planDateStartController = TextEditingController();
  final TextEditingController planDateEndController = TextEditingController();
  final TextEditingController planNameController = TextEditingController();
  final TextEditingController planDescriptionController =
      TextEditingController();

  final TextEditingController minPlanLengthController = TextEditingController();
  final TextEditingController minInviteesController = TextEditingController();

  String startTime = "";
  String endTime = "";

  DateTime startDateRange = DateTime.now();
  DateTime endDateRange = DateTime.now();

  DateTime startTimeRange = DateTime.now();
  DateTime endTimeRange = DateTime.now();

  bool isEditingDate = false;

  Map<String, dynamic> selectedGroupData = {};

  getSelectedGroupData(String groupId) async {
    print(groupId);
    Map<String, dynamic> groupData =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            .getGroupData(groupId.split("_")[0]);
    setState(() {
      selectedGroupData = groupData;
      selectedGroup = groupId.split("_")[0];
    });
  }

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  loadPresets() {
    if (widget.startTime != "") {
      startTimeController.text = widget.startTime;
      endTimeController.text = widget.endTime;
      planDateStartController.text = widget.startDate;
      planDateEndController.text = widget.endDate;
      startTime = widget.startTime;
      endTime = widget.endTime;
      _plan['startTime'] = startTimeController.text;
      _plan['endTime'] = endTimeController.text;

      _currentStep = PlanCreationStep.selectInvitees;
    }

    if (widget.invitees.isNotEmpty) {
      invitees = widget.invitees;

      _currentStep = PlanCreationStep.selectDate;
    }

    if (widget.selectedFriends.isNotEmpty) {
      selectedFriends = widget.selectedFriends;
    }

    if (widget.date.isNotEmpty) {
      _plan['invitees'] = widget.invitees;
      _plan['date'] = DateFormat('yyyy-MM-dd').parse(widget.date);
      _currentStep = PlanCreationStep.selectPlanName;
    }

    if (widget.planName.isNotEmpty) {
      planNameController.text = widget.planName;
      _plan['name'] = widget.planName;
      _currentStep = PlanCreationStep.selectPlanName;
    }
  }

  getUserGroups() async {
    List<dynamic> groupsList =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
            .getUserGroups(FirebaseAuth.instance.currentUser!.uid);
    setState(() {
      userGroups = groupsList;
    });
    generateGroupDropdownItems();
  }

  generateGroupDropdownItems() {
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (var i = 0; i < userGroups.length; i++) {
      dropdownItems.add(DropdownMenuItem(
        child: Text(userGroups[i].split("_")[1]),
        value: userGroups[i],
      ));
    }
    setState(() {
      groupDropdownItems = dropdownItems;
    });
  }

  sendPlan() async {
    print(_plan["startTime"]);
    bool startAM = _plan["startTime"].toString().contains("AM");
    bool endAM = _plan["endTime"].toString().contains("AM");
    DateTime startTime = DateFormat("hh:mm a").parse(_plan["startTime"]);
    String startTime24 = DateFormat("HH:mm").format(startTime);
    DateTime endTime = DateFormat("hh:mm a").parse(_plan["endTime"]);
    String endTime24 = DateFormat("HH:mm").format(endTime);
    List<String> months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    DateTime date = _plan["date"];
    print(date.day);
    startTime = DateFormat("MMMM dd, yyyy hh:mm").parse(
        "${months[date.month - 1]} ${date.day}, ${date.year} ${startTime24}");
    endTime = DateFormat("MMMM dd, yyyy hh:mm").parse(
        "${months[date.month - 1]} ${date.day}, ${date.year} ${endTime24}");
    print("START AND END TIME");
    print(startTime);
    print(endTime);
    CalendarFunctions().addCalendarEvent(_plan["name"], _plan["description"],
        startTime, endTime, FirebaseAuth.instance.currentUser!.uid);
    await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
        .sendPlan(_plan);
    Navigator.pop(context);
    nextScreen(
        context,
        const PlansPage(
          currentPlanView: PlanView.myPlans,
        ));
  }

  selectDate(DateTime date) {
    //print(invitees);
    setState(() {
      _plan['date'] = date;
      //Get List element with date = date
      Map<String, dynamic> dateMap = invitees.firstWhere((element) =>
          DateFormat('MM/dd/yyyy').format(element['date']) ==
          DateFormat('MM/dd/yyyy').format(date));
      List<Map<String, dynamic>> users = dateMap['users'].where((element) {
        return element['isFree'] == true;
      }).toList();
      _plan['invitees'] = [];
      for (var i = 0; i < users.length; i++) {
        Map<String, dynamic> user = {
          'id': getFriendId(users[i]['id']),
          'displayName': getFriendDisplayName(users[i]['id']),
          'username': getFriendUsername(users[i]['id']),
          'canAttend': "pending"
        };

        _plan['invitees'].add(user);
      }
      print(_plan['invitees']);
      _currentStep = isEditingDate
          ? PlanCreationStep.reviewPlan
          : PlanCreationStep.selectPlanName;
      setState(() {
        isEditingDate = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    loadPresets();
    getUserGroups();
  }

  String getFriendId(String res) {
    return res.split("_")[0];
  }

  String getFriendUsername(String res) {
    return res.split("_")[1];
  }

  String getFriendDisplayName(String res) {
    return res.split("_")[2];
  }

  removeInvitee(String id) {
    setState(() {
      _plan['invitees'].remove(id);
    });
  }

  generateInviteeTiles() {
    List<Widget> inviteeTiles = [];
    for (var i = 0; i < _plan['invitees'].length; i++) {
      inviteeTiles.add(ReviewPlanInviteeTile(
        displayName: _plan['invitees'][i]['displayName'],
        username: _plan['invitees'][i]['username'],
        id: _plan['invitees'][i]['id'],
        deleteInvitee: removeInvitee,
      ));
    }
    return inviteeTiles;
  }

  selectTime(DateTime day, DateTime startTimeRange, DateTime endTimeRange,
      List<String> invitees) {
    setState(() {
      startTimeController.text = DateFormat("hh:mm a").format(startTimeRange);
      endTimeController.text = DateFormat("hh:mm a").format(endTimeRange);
      this.startTimeRange = startTimeRange;
      this.endTimeRange = endTimeRange;
      _plan['date'] = day;
      _selectBetterTimesStep = SelectBetterTimesStep.selectPlanTime;
      for (var i = 0; i < invitees.length; i++) {
        Map<String, dynamic> user = {
          'id': getFriendId(invitees[i]),
          'displayName': getFriendDisplayName(invitees[i]),
          'username': getFriendUsername(invitees[i]),
          'canAttend': "pending"
        };

        _plan['invitees'].add(user);
      }
    });
  }

  formatDate(String date) {
    //Split by space
    List<String> dateList = date.split(" ");
    //Split by dash
    List<String> dateList2 = dateList[0].split("-");
    List<String> newDate = [];

    newDate.add(months[int.parse(dateList2[1]) - 1]);
    newDate.add(dateList2[2]);
    newDate.add(dateList2[0]);
    return newDate;
  }

  generatePlannedDaysTiles() {
    List<Widget> plannedDays = [];
    for (var i = 0; i < invitees.length; i++) {
      plannedDays.add(
        PlannedDayAvailabilityTile(
          day: invitees[i]['date'],
          invitees: invitees[i]['users'],
          selectDate: selectDate,
        ),
      );
    }
    return plannedDays;
  }

  generateSuggestedDaysTiles() {
    List<Widget> suggestedDays = [];
    for (var i = 0; i < suggestedTimes.length; i++) {
      suggestedDays.add(SuggestedPlanDateTile(
          day: invitees[i]['date'],
          dayData: suggestedTimes[i],
          selectTime: selectTime));
    }
    return suggestedDays;
  }

  @override
  Widget build(BuildContext context) {
    print("START TIME: ${_plan['startTime']} END TIME: ${_plan['endTime']}" );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: MainAppBar(
          pageTitle: "Plan Creator",
          displayName: widget.displayName,
          email: widget.email,
        ),
      ),
      body: _currentStep == PlanCreationStep.selectDateRange
          ? selectPlanDateRange()
          : _currentStep == PlanCreationStep.selectInvitees &&
                  widget.planType == PlanType.friends
              ? selectFriends()
              : _currentStep == PlanCreationStep.selectInvitees &&
                      widget.planType == PlanType.group
                  ? selectGroup()
                  : _currentStep == PlanCreationStep.selectDate
                      ? selectDateForPlan()
                      : _currentStep == PlanCreationStep.selectBetterTimes
                          ? selectBetterTimes()
                          : _currentStep == PlanCreationStep.selectPlanName
                              ? selectPlanName()
                              : _currentStep == PlanCreationStep.reviewPlan
                                  ? reviewPlan()
                                  : Container(),
    );
  }

  selectPlanDateRange() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Form(
            key: planDateRangeFormKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(
                height: 20,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "Select Time Frame and Date Range",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 300,
                child: TextFormField(
                  autocorrect: false,
                  readOnly: true,
                  controller: startTimeController,
                  onTap: () async {
                    DateTime date = DateTime.now();
                    if (startTimeController.text.isNotEmpty) {
                      date =
                          DateFormat("hh:mm a").parse(startTimeController.text);
                    }
                    var time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(date));

                    if (time != null) {
                      startTimeController.text = time.format(context);
                    }
                  },
                  style: const TextStyle(color: Colors.black),
                  decoration: textInputDecoration.copyWith(
                    labelText: "Event Start Time",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a start time';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                width: 300,
                child: TextFormField(
                  autocorrect: false,
                  readOnly: true,
                  controller: endTimeController,
                  onTap: () async {
                    DateTime dateS = DateTime.now();
                    if (startTimeController.text.isNotEmpty) {
                      dateS =
                          DateFormat("hh:mm a").parse(startTimeController.text);
                    }
                    DateTime dateE = DateTime.now();
                    if (endTimeController.text.isNotEmpty) {
                      dateE =
                          DateFormat("hh:mm a").parse(endTimeController.text);
                    }
                    TimeOfDay initTime = startTimeController.text.isEmpty
                        ? TimeOfDay.fromDateTime(dateS)
                        : endTimeController.text.isEmpty
                            ? TimeOfDay.fromDateTime(
                                dateS.add(const Duration(hours: 1)))
                            : TimeOfDay.fromDateTime(dateE);
                    //
                    var time = await showTimePicker(
                        context: context,
                        //Make sure that initial time is in 12 hour format
                        initialTime: initTime);

                    if (time != null) {
                      endTimeController.text = time.format(context);
                    }
                  },
                  style: const TextStyle(color: Colors.black),
                  decoration: textInputDecoration.copyWith(
                    labelText: "Event End Time",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an end time';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                width: 300,
                child: TextFormField(
                  autocorrect: false,
                  readOnly: true,
                  controller: planDateStartController,
                  onTap: () async {
                    DateTime initDate = DateTime.now();
                    if (planDateStartController.text.isNotEmpty) {
                      initDate = DateFormat("MMMM dd, yyyy")
                          .parse(planDateStartController.text);
                    }
                    var date = await showDatePicker(
                      context: context,
                      initialDate: initDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );

                    if (date != null) {
                      List<String> dateList = formatDate(date.toString());

                      planDateStartController.text =
                          "${dateList[0]} ${dateList[1]}, ${dateList[2]}";
                    }
                  },
                  style: const TextStyle(color: Colors.black),
                  decoration: textInputDecoration.copyWith(
                    labelText: "Event Date Range Start",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a start date';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                width: 300,
                child: TextFormField(
                  autocorrect: false,
                  readOnly: true,
                  controller: planDateEndController,
                  onTap: () async {
                    DateTime initDate = DateTime.now();

                    if (planDateStartController.text.isNotEmpty) {
                      initDate = DateFormat("MMMM dd, yyyy")
                          .parse(planDateStartController.text);
                    }
                    if (planDateEndController.text.isNotEmpty) {
                      initDate = DateFormat("MMMM dd, yyyy")
                          .parse(planDateEndController.text);
                    }
                    var date = await showDatePicker(
                      context: context,
                      initialDate: initDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );

                    if (date != null) {
                      List<String> dateList = formatDate(date.toString());

                      planDateEndController.text =
                          "${dateList[0]} ${dateList[1]}, ${dateList[2]}";
                    }
                  },
                  style: const TextStyle(color: Colors.black),
                  decoration: textInputDecoration.copyWith(
                    labelText: "Event Date Range End",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an end date';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: 300,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (widget.planType == PlanType.friends) {
                            if (planDateRangeFormKey.currentState!.validate()) {
                              if (selectedFriends.isEmpty) {
                                setState(() {
                                  _plan['startTime'] = startTimeController.text;
                                  _plan['endTime'] = endTimeController.text;
                                  startTime = startTimeController.text;
                                  endTime = endTimeController.text;
                                  _currentStep =
                                      PlanCreationStep.selectInvitees;
                                  startDateRange = DateFormat("MMMM dd, yyyy")
                                      .parse(planDateStartController.text);
                                  endDateRange = DateFormat("MMMM dd, yyyy")
                                      .parse(planDateEndController.text);
                                });
                              } else {
                                setState(() {
                                  _isLoading = true;
                                  startTime = startTimeController.text;
                                  endTime = endTimeController.text;
                                });
                                List<Map<String, dynamic>> freeList =
                                    await CalendarFunctions()
                                        .checkWhosFreeBetweenRange(
                                            planDateStartController.text,
                                            planDateEndController.text,
                                            startTimeController.text,
                                            endTimeController.text,
                                            selectedFriends);
                                setState(() {
                                  invitees = freeList;
                                  _isLoading = false;
                                  _currentStep = PlanCreationStep.selectDate;
                                });
                              }
                            }
                          } else {
                            if (widget.minAttendees != 0) {
                              setState(() {
                                _isLoading = true;
                                startTime = startTimeController.text;
                                endTime = endTimeController.text;
                                _plan['startTime'] = startTimeController.text;
                                _plan['endTime'] = endTimeController.text;
                                
                                
                              });
                              print(_plan['startTime']);
                              print(_plan['endTime']);
                              List<Map<String, dynamic>> freeList =
                                  await CalendarFunctions()
                                      .checkWhosFreeInGroup(
                                          planDateStartController.text,
                                          planDateEndController.text,
                                          startTimeController.text,
                                          endTimeController.text,
                                          widget.minAttendees,
                                          widget.groupId);
                              setState(() {
                                invitees = freeList;
                                _isLoading = false;
                                _currentStep = PlanCreationStep.selectDate;
                              });
                            } else {
                              setState(() {
                                _plan['startTime'] = startTimeController.text;
                                _plan['endTime'] = endTimeController.text;
                                startTime = startTimeController.text;
                                endTime = endTimeController.text;
                                _currentStep = PlanCreationStep.selectInvitees;
                                startDateRange = DateFormat("MMMM dd, yyyy")
                                    .parse(planDateStartController.text);
                                endDateRange = DateFormat("MMMM dd, yyyy")
                                    .parse(planDateEndController.text);
                              });
                            }
                          }
                        },
                        child: const Text("Submit"),
                      ),
                    ),
            ]),
          ),
        ],
      ),
    );
  }

  selectFriends() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Form(
            key: planDateRangeFormKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(
                height: 20,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "Select the Invitees",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 300,
                child: MultiSelectDialogField(
                  items: widget.friends,
                  searchable: true,
                  title: const Text("Friends"),
                  dialogHeight:
                      (widget.friends.length * 50).toDouble(), //To Double,

                  onConfirm: (vals) {
                    selectedFriends = vals.map((e) => e.toString()).toList();
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: 300,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedFriends.isNotEmpty) {
                            setState(() {
                              _isLoading = true;
                            });
                            List<Map<String, dynamic>> freeList =
                                await CalendarFunctions()
                                    .checkWhosFreeBetweenRange(
                                        planDateStartController.text,
                                        planDateEndController.text,
                                        startTimeController.text,
                                        endTimeController.text,
                                        selectedFriends);
                            setState(() {
                              invitees = freeList;
                              _isLoading = false;
                              _currentStep = PlanCreationStep.selectDate;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Please select at least one friend"),
                              ),
                            );
                          }
                        },
                        child: const Text("Submit"),
                      ),
                    ),
            ]),
          ),
        ],
      ),
    );
  }

  selectGroup() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Form(
            key: selectGroupFormKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(
                height: 20,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "Select a group",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 300,
                child: DropdownButtonFormField(
                  decoration: textInputDecoration.copyWith(
                    labelText: "Groups",
                  ),
                  items: groupDropdownItems,
                  onChanged: (value) async {
                    await getSelectedGroupData(value.toString());
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a group';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              selectedGroupData["members"] != null
                  ? SizedBox(
                      width: 300,
                      child: TextFormField(
                        decoration: textInputDecoration.copyWith(
                          labelText: "Minimum attendees",
                        ),
                        keyboardType: TextInputType.number,
                        initialValue:
                            selectedGroupData["members"].length.toString(),
                        onChanged: (val) {
                          setState(() {
                            if (val == null || val.isEmpty) {
                              minAttendees = 0;
                            } else {
                              minAttendees = int.parse(val);
                            }
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Please enter a number";
                          } else if (int.parse(val) >
                              selectedGroupData["members"].length) {
                            return "Please enter a number less than the number of group members";
                          } else if (int.parse(val) < 1) {
                            return "Please enter a number greater than 0";
                          }
                          return null;
                        },
                      ),
                    )
                  : Container(),
              const SizedBox(
                height: 20,
              ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: 300,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectGroupFormKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            List<Map<String, dynamic>> freeList =
                                await CalendarFunctions().checkWhosFreeInGroup(
                                    planDateStartController.text,
                                    planDateEndController.text,
                                    startTimeController.text,
                                    endTimeController.text,
                                    minAttendees,
                                    selectedGroup);
                            setState(() {
                              invitees = freeList;
                              _isLoading = false;
                              _currentStep = PlanCreationStep.selectDate;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Please select at least one friend"),
                              ),
                            );
                          }
                        },
                        child: const Text("Submit"),
                      ),
                    ),
            ]),
          ),
        ],
      ),
    );
  }

  selectDateForPlan() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 300,
                child: Text(
                  "Possible dates for time frame of $startTime to $endTime",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "Expand a date to see who is available, click on checkmark circle to select date",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = PlanCreationStep.selectBetterTimes;
                    });
                  },
                  child: const Text("Suggest better times"),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height - 400,
                width: 300,
                child: ListView(
                  //  shrinkWrap: true,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    ...generatePlannedDaysTiles(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  selectBetterTimes() {
    switch (_selectBetterTimesStep) {
      case SelectBetterTimesStep.enterParameters:
        return enterParameters();

      case SelectBetterTimesStep.selectSuggestedTime:
        return selectSuggestedTime();

      case SelectBetterTimesStep.selectPlanTime:
        return selectPlanTime();
      default:
    }
  }

  enterParameters() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Form(
            key: suggestBetterTimesFormKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(
                height: 20,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "Select Plan Parameters",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "This will be used to suggest better times for the plan",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 300,
                child: TextFormField(
                  autocorrect: false,
                  keyboardType: TextInputType.number,
                  controller: minPlanLengthController,
                  decoration: textInputDecoration.copyWith(
                    labelText: "Minimum Plan Length (minutes)",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a minimum plan length';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 300,
                child: TextFormField(
                  autocorrect: false,
                  keyboardType: TextInputType.number,
                  controller: minInviteesController,
                  decoration: textInputDecoration.copyWith(
                    labelText: "Minimum Invitees",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter minimum invitees';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: 300,
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _isLoading = true;
                          });
                          print(selectedFriends);
                          List<Map<String, dynamic>> freeList =
                              await CalendarFunctions().suggestBetterTimes(
                                  startDateRange,
                                  endDateRange,
                                  int.parse(minPlanLengthController.text),
                                  int.parse(minInviteesController.text),
                                  selectedFriends);
                          setState(() {
                            suggestedTimes = freeList;

                            print(freeList);
                            _isLoading = false;
                            _selectBetterTimesStep =
                                SelectBetterTimesStep.selectSuggestedTime;
                          });
                        },
                        child: const Text("View Suggested Times"),
                      ),
                    ),
            ]),
          ),
        ],
      ),
    );
  }

  selectSuggestedTime() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 20,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "Suggested times for the plan",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "Expand a date to see who is available during certain time frames, click on checkmark circle to select time frame",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height - 400,
                width: 300,
                child: ListView(
                  //  shrinkWrap: true,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    ...generateSuggestedDaysTiles(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  selectPlanTime() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Form(
            key: selectPlanTimeFormKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(
                height: 20,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "Select the Time Frame",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              a
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                width: 300,
                child: TextFormField(
                  autocorrect: false,
                  readOnly: true,
                  controller: endTimeController,
                  onTap: () async {
                    DateTime dateS = DateTime.now();
                    if (startTimeController.text.isNotEmpty) {
                      dateS =
                          DateFormat("hh:mm a").parse(startTimeController.text);
                    }
                    DateTime dateE = DateTime.now();
                    if (endTimeController.text.isNotEmpty) {
                      dateE =
                          DateFormat("hh:mm a").parse(endTimeController.text);
                    }
                    TimeOfDay initTime = startTimeController.text.isEmpty
                        ? TimeOfDay.fromDateTime(dateS)
                        : endTimeController.text.isEmpty
                            ? TimeOfDay.fromDateTime(
                                dateS.add(const Duration(hours: 1)))
                            : TimeOfDay.fromDateTime(dateE);
                    //
                    var time = await showTimePicker(
                        context: context,
                        //Make sure that initial time is in 12 hour format
                        initialTime: initTime);

                    if (time != null) {
                      endTimeController.text = time.format(context);
                    }
                  },
                  style: const TextStyle(color: Colors.black),
                  decoration: textInputDecoration.copyWith(
                    labelText: "Event End Time",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an end time';
                    }
                    //Check if end time is after end time range
                    DateTime endTime =
                        DateFormat("hh:mm a").parse(endTimeController.text);
                    DateTime startTimeRange = DateFormat("hh:mm a").parse(
                        DateFormat("hh:mm a").format(this.startTimeRange));
                    DateTime endTimeRange = DateFormat("hh:mm a")
                        .parse(DateFormat("hh:mm a").format(this.endTimeRange));
                    if (endTime.isAfter(endTimeRange) &&
                        endTime != endTimeRange) {
                      return 'Please enter an end time before ${DateFormat("hh:mm a").format(endTimeRange)}';
                    }
                    if (endTime.isBefore(startTimeRange)) {
                      return 'Please enter an end time after ${DateFormat("hh:mm a").format(startTimeRange)}';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: 300,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectPlanTimeFormKey.currentState!.validate()) {
                            setState(() {
                              _plan['startTime'] = startTimeController.text;
                              _plan['endTime'] = endTimeController.text;
                              startTime = startTimeController.text;
                              endTime = endTimeController.text;
                              _currentStep = PlanCreationStep.selectPlanName;
                            });
                          }
                        },
                        child: const Text("Submit"),
                      ),
                    ),
            ]),
          ),
        ],
      ),
    );
  }

  selectPlanName() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Form(
            key: planNameFormKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(
                height: 20,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "Select Name and Descrition",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "This will be the name of the plan that your friends will see and the description will be sent to them in the invite",
                  style: TextStyle(
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 300,
                child: TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a plan name';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Plan Name',
                  ),
                  controller: planNameController,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 300,
                child: TextField(
                  controller: planDescriptionController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Plan Description (optional)',
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  onPressed: () {
                    if (planNameFormKey.currentState!.validate()) {
                      print("Ghell");
                      print("START TIME: ${_plan['startTime']} END TIME: ${_plan['endTime']}" );
                      setState(() {
                        _plan['name'] = planNameController.text;
                        _plan['description'] = planDescriptionController.text;
                        
                        _currentStep = PlanCreationStep.reviewPlan;
                      });
                    }
                  },
                  child: const Text("Review Plan"),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  reviewPlan() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 20,
                ),
                const SizedBox(
                  width: 300,
                  child: Text(
                    "Review your plan",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                const SizedBox(
                  width: 300,
                  child: Text(
                    "Make sure everything looks good before you send it to your friends!",
                    style: TextStyle(
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: 300,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          "Plan Name",
                          style: const TextStyle(
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _currentStep = PlanCreationStep.selectPlanName;
                          });
                        },
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  width: 300,
                  height: 40,
                  child: Text(
                    "${_plan['name']}",
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_plan['description'] != null && _plan['description'] != "")
                  const SizedBox(
                    height: 20,
                  ),
                if (_plan['description'] != null && _plan['description'] != "")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        child: Text(
                          "Plan Description",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(
                        width: 0,
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _currentStep = PlanCreationStep.selectPlanName;
                          });
                        },
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                if (_plan['description'] != null && _plan['description'] != "")
                  const SizedBox(
                    height: 10,
                  ),
                if (_plan['description'] != null && _plan['description'] != "")
                  SizedBox(
                    width: 300,
                    height: 40,
                    child: Text(
                      "${_plan['description']}",
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(
                  height: 5,
                ),
                SizedBox(
                  width: 300,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Plan Date: ${DateFormat('MM/dd/yyyy').format(_plan['date'])}",
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            isEditingDate = true;
                            _currentStep = PlanCreationStep.selectDate;
                          });
                        },
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  width: 300,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Plan Time: ${_plan['startTime']} to ${_plan['endTime']}",
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _currentStep = PlanCreationStep.selectDateRange;
                          });
                        },
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const SizedBox(
                  width: 300,
                  child: Text(
                    "Invitees:",
                    style: TextStyle(
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: _plan['invitees'].length > 3
                      ? 250
                      : _plan['invitees'].length * 70.0,
                  width: 300,
                  child: ListView(
                    //  shrinkWrap: true,
                    clipBehavior: Clip.hardEdge,
                    children: [
                      ...generateInviteeTiles(),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                _isSendingPlan
                    ? CircularProgressIndicator()
                    : SizedBox(
                        width: 300,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isSendingPlan = true;
                            });
                            sendPlan();
                          },
                          child: const Text("Send Plan"),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
