
import 'package:flutter/material.dart';

class CustomPageRoute extends MaterialPageRoute {
  CustomPageRoute({builder}) : super(builder: builder);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 0);
  //Override route to be false
  @override
  bool get maintainState => false;
}