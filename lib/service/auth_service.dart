import 'package:firebase_auth/firebase_auth.dart';

import '../helper/helper_function.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  //Login
  Future loginWithEmailandPassword(String email, String password) async {
    try {
      User user = (await firebaseAuth.signInWithEmailAndPassword(
              email: email, password: password))
          .user!;

      var userInfoMap =
          await DatabaseService(uid: user.uid).getUserData(user.uid);
      await HelperFunctions.saveUserNameSF(userInfoMap["username"]);
      return true;
    } on FirebaseAuthException catch (e) {
      print(e.code);
      switch (e.code) {
        case "user-not-found":
          return "No user found with that email.";

        case "wrong-password":
          return "Incorrect password.";

        default:
          return e.message;
      }
    }
  }

  //Register
  Future registerUserWithEmailandPassword(
      String fullName, String email, String password, String username) async {
    try {
      User user = (await firebaseAuth.createUserWithEmailAndPassword(
              email: email, password: password))
          .user!;

      await DatabaseService(uid: user.uid)
          .savingUserData(fullName, email, username);

      return true;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  //Signout
  Future signOut() async {
    try {
      await HelperFunctions.saveUserLoggedInStatus(false);
      await HelperFunctions.saveUserDisplayNameSF("");
      await HelperFunctions.saveUserEmailSF("");
      await firebaseAuth.signOut();
    } catch (e) {
      return null;
    }
  }
}
