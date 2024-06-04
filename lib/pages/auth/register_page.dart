import 'package:device_calendar/device_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:raincheck/pages/planner_page.dart';
import 'package:raincheck/pages/plans_page.dart';

import '../../../helper/helper_function.dart';
import '../../../service/auth_service.dart';
import '../../../service/database_service.dart';
import '../../helper/calendar_functions.dart';
import '../../widgets/widgets.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isLoading = false;
  final formKey = GlobalKey<FormState>();
  String fullName = "";
  String email = "";
  String password = "";
  String username = "";
  AuthService authService = AuthService();
  List<Calendar> userCalendars = [];
  final List<MultiSelectItem<Object?>> calendars = [];
  List<String> selectedCalendars = [];
  List<DropdownMenuItem> calendarDropdownItems = [];
  String defaultCalendarId = "";

  Future<void> getUserCalendars() async {
    List<Calendar> calendars = await CalendarFunctions().getCalendars();
    setState(() {
      userCalendars = calendars;
    });
    generateCalendarMultiSelectItems();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserCalendars();
  }

  generateCalendarMultiSelectItems() {
    for (var element in userCalendars) {
      setState(() {
        calendars.add(MultiSelectItem(
          "${element.id}_${element.name}",
          element.name!,
        ));
      });
    }
  }

  generateCalendarDropdownItems() {
    for (var element in selectedCalendars) {
      String calendarId = element.split("_")[0];
      String calendarName = element.split("_")[1];
      print("Calendar ID: $calendarId Calendar Name: $calendarName");
      setState(() {
        calendarDropdownItems.add(DropdownMenuItem(
          child: Text(calendarName),
          value: element,
        ));
      });
    }
  }

  changeSelectedCalendar(context) async {
    await DatabaseService(uid: FirebaseAuth.instance.currentUser!.uid)
        .updateUserData(FirebaseAuth.instance.currentUser!.uid, {
      "defaultCalendar": defaultCalendarId,
      "calendars": selectedCalendars
    });
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PlannerPage()),
        (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor))
          : SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 80),
                  child: Form(
                    key: formKey,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Text(
                            "Raincheck",
                            style: TextStyle(
                              fontSize: 45,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Image.asset("assets/register.png",
                              height: 300, width: 300),
                          TextFormField(
                            decoration: textInputDecoration.copyWith(
                                labelText: "Full Name",
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: Theme.of(context).primaryColor,
                                )),
                            onChanged: (val) {
                              setState(() {
                                fullName = val;
                              });
                            },
                            validator: (val) {
                              if (val!.isEmpty) {
                                return "Name cannot be empty";
                              } else {
                                return null;
                              }
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            autocorrect: false,
                            decoration: textInputDecoration.copyWith(
                                labelText: "Username",
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: Theme.of(context).primaryColor,
                                )),
                            onChanged: (val) {
                              setState(() {
                                username = val;
                              });
                            },
                            validator: (val) {
                              if (val!.isEmpty) {
                                return "Username cannot be empty";
                              } else {
                                return null;
                              }
                            },
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            decoration: textInputDecoration.copyWith(
                                labelText: "Email",
                                prefixIcon: Icon(
                                  Icons.email,
                                  color: Theme.of(context).primaryColor,
                                )),
                            onChanged: (val) {
                              setState(() {
                                email = val;
                              });
                            },

                            //Check email validation
                            validator: (val) {
                              return RegExp(
                                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                      .hasMatch(val!)
                                  ? null
                                  : "Please enter a valid email";
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            obscureText: true,
                            decoration: textInputDecoration.copyWith(
                                labelText: "Password",
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: Theme.of(context).primaryColor,
                                )),
                            validator: (val) {
                              if (val!.length < 6) {
                                return "Password must be at least 6 characters";
                              } else {
                                return null;
                              }
                            },
                            onChanged: (val) {
                              setState(() {
                                password = val;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(30))),
                                child: const Text(
                                  "Register",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                                onPressed: () {
                                  register();
                                },
                              )),
                          const SizedBox(height: 10),
                          Text.rich(TextSpan(
                              text: "Already have an account? ",
                              children: [
                                TextSpan(
                                    text: "Login now",
                                    style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        nextScreenReplace(
                                            context, const LoginPage());
                                      })
                              ]))
                        ]),
                  ))),
    );
  }

  void register() async {
    if (formKey.currentState!.validate()) {
      bool isUsernameTaken =
          await DatabaseService().checkIfUsernameExists(username);
      if (isUsernameTaken) {
        showSnackBar(context, Colors.red, "Username is already taken");
        return;
      }
      setState(() {
        _isLoading = true;
      });
      await authService
          .registerUserWithEmailandPassword(fullName, email, password, username)
          .then((value) async {
        if (value == true) {
          await HelperFunctions.saveUserLoggedInStatus(true);
          await HelperFunctions.saveUserDisplayNameSF(fullName);
          await HelperFunctions.saveUserNameSF(username);
          await HelperFunctions.saveUserEmailSF(email);

          selectCalendar(context);
        } else {
          showSnackBar(context, Colors.red, value);
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  selectCalendar(context) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                "Select calendars to connect to",
                textAlign: TextAlign.left,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 250,
                    child: MultiSelectDialogField(
                      items: calendars,
                      searchable: true,
                      title: const Text("Calendars"),
                      dialogHeight:
                          (calendars.length * 50).toDouble(), //To Double,

                      onConfirm: (vals) {
                        setState(() {
                          selectedCalendars =
                              vals.map((e) => e.toString()).toList();
                          print(selectedCalendars);
                        });
                        generateCalendarDropdownItems();
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  if (selectedCalendars.isNotEmpty)
                    SizedBox(
                      width: 250,
                      child: DropdownButtonFormField(
                        isExpanded: true,
                        decoration: textInputDecoration.copyWith(
                            labelText: "Default Calendar",
                            prefixIcon: Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).primaryColor,
                            )),
                        onChanged: (val) {
                          setState(() {
                            defaultCalendarId = val.toString();
                          });
                        },
                        items: calendarDropdownItems,
                      ),
                    ),
                  const SizedBox(
                    height: 5,
                  ),
                  if (selectedCalendars.isNotEmpty)
                    SizedBox(
                      width: 250,
                      child: TextButton(
                        onPressed: () {
                          showDefaultCalenderInfoDialog();
                        },
                        child: const Text(
                          "What is a default calendar?",
                          style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.none),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    if (selectedCalendars.length > 0) {
                      if (defaultCalendarId != "") {
                        changeSelectedCalendar(context);
                      } else {
                        showSnackBar(context, Colors.red,
                            "Please select a default calendar");
                      }
                    } else {
                      showSnackBar(context, Colors.red,
                          "Please select at least one calendar");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text("Submit"),
                ),
              ],
            );
          });
        });
  }

  showDefaultCalenderInfoDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Default Calendar"),
            content: const Text(
                "The default calendar is the calendar that will be used to create plans and events. You can change this later in the settings page."),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Ok"))
            ],
          );
        });
  }
}
