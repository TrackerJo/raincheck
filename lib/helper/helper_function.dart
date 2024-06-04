import 'package:shared_preferences/shared_preferences.dart';

class HelperFunctions {
  //Keys
  static String userLoggedInKey = "LOGGEDINKEY";
  static String userNameKey = "USERNAMEKEY";
  static String userDisplayNameKey = "USERDISPLAYNAMEKEY";
  static String userEmailKey = "USEREMAILKEY";
  static String userSchoolKey = "USERSCHOOLKEY";
  static String userTypeKey = "USERTYPEKEY";

  //Saving data to SF
  static Future<bool> saveUserLoggedInStatus(bool isUserLoggedIn) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setBool(userLoggedInKey, isUserLoggedIn);
  }

  static Future<bool> saveUserDisplayNameSF(String userDisplayName) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userDisplayNameKey, userDisplayName);
  }

  static Future<bool> saveUserNameSF(String userName) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userNameKey, userName);
  }

  static Future<bool> saveUserEmailSF(String userEmail) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userEmailKey, userEmail);
  }

  static Future<bool> saveUserSchoolSF(String userSchool) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userSchoolKey, userSchool);
  }

  static Future<bool> saveUserTypeSF(String userType) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userTypeKey, userType);
  }

  //Getting data from SF
  static Future<bool?> getUserLoggedInStatus() async {
    SharedPreferences sf = await SharedPreferences.getInstance();

    return sf.getBool(userLoggedInKey);
  }

  static Future<String?> getUserNameFromSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userNameKey);
  }

  static Future<String?> getUserDisplayNameFromSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userDisplayNameKey);
  }

  static Future<String?> getUserEmailFromSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userEmailKey);
  }

  static Future<String?> getUserSchoolFromSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userSchoolKey);
  }

  static Future<String?> getUserTypeFromSF() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userTypeKey);
  }
}
