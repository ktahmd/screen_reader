import 'package:flutter/material.dart';

import '../helpers/theme_helper.dart';

// class ThemeProvider with ChangeNotifier {
//   ThemeData _themeData = ThemeData.light();
//   ThemeData get themeData => _themeData;

//   void toggleTheme() {
//     _themeData = _themeData.brightness == Brightness.light 
//         ? ThemeData.dark() 
//         : ThemeData.light();
//     notifyListeners();
//   }
// }
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; 
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Helper for MaterialApp
  ThemeData get themeData => appTheme(Brightness.light);
  ThemeData get darkThemeData => appTheme(Brightness.dark);
}