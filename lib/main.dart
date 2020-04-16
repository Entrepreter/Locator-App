import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:locator/pages/splash_screen.dart';

void main() {
  runApp(LocatorApp());
}

class LocatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mySystemTheme = SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark);
    SystemChrome.setSystemUIOverlayStyle(mySystemTheme);
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: SplashScreen(),
    );
  }
}
