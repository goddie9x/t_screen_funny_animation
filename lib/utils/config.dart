import 'package:flutter/material.dart';

class AppConfig extends ChangeNotifier {
  static final AppConfig instance = AppConfig._internal();
  AppConfig._internal();

  int shimejiCount = 1;
  double speedMultiplier = 1.0;
  int actionFrequency = 3;
  double sizeMultiplier = 1.0;
  
  Color headColor = Colors.orange;
  Color bodyColor = Colors.blue;
  Color armColor = Colors.blueGrey;
  Color legColor = Colors.brown;
  
  IconData? headIcon, bodyIcon, armIcon, legIcon;

  void updateCount(int c) { shimejiCount = c; notifyListeners(); }
  void updateSpeed(double s) { speedMultiplier = s; notifyListeners(); }
  void updateFrequency(int f) { actionFrequency = f; notifyListeners(); }
  void updateSize(double s) { sizeMultiplier = s; notifyListeners(); }
  
  void updateStyle(Color h, Color b, Color a, Color l, {IconData? hi, IconData? bi, IconData? ai, IconData? li}) {
    headColor = h; bodyColor = b; armColor = a; legColor = l;
    headIcon = hi; bodyIcon = bi; armIcon = ai; legIcon = li;
    notifyListeners();
  }
}
