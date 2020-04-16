import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:locator/pages/home_page.dart';
import 'package:locator/pages/main_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Location location = Location.instance;
    location.hasPermission().then((status) {
      if (status == PermissionStatus.granted) {
        location.serviceEnabled().then((enabled) {
          if (enabled) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => MainPage()));
          } else {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => HomePage()));
          }
        });
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomePage()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).primaryColor,
        child: Center(
            child: Text(
          "Locator",
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 48, color: Colors.white),
        )),
      ),
    );
  }
}
