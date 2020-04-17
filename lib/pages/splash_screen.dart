import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

import 'ErrorPage.dart';
import 'map_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    initApp();
  }

  void initApp() {
    Location _location = Location.instance;

    _location.hasPermission().then((value) {
      if (value == PermissionStatus.granted) {
        //our app already has location permission
        haveLocationPermission(_location);
      } else {
        //doesn't have the permission
        //ask user the location permissions
        _location.requestPermission().then((value) {
          if (value == PermissionStatus.granted) {
            //now we have location permission
            haveLocationPermission(_location);
          } else {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => ErrorPage(
                        "This App Won't work with location permissions")));
          }
        });
      }
    }).catchError((e) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
    });
  }

  void haveLocationPermission(Location _location) {
    _location.serviceEnabled().then((value) {
      if (value) {
        //service is enable, continue using it
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MapPage()));
      } else {
        //ask for turning on the location
        _location.requestService().then((value) => {
              if (value)
                {
                  //service is turned on now can continue using the map or location
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => MapPage()))
                }
              else
                {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ErrorPage(
                              "This app requires location sharing on")))
                }
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Colors.white,
                width: 124,
                height: 124,
                child: Image.asset('assets/images/location_sharing_off.png'),
              ),
              RichText(
                text: TextSpan(
                  text: 'L',
                  style: TextStyle(
                      color: Colors.black54,
                      fontSize: 48,
                      fontWeight: FontWeight.w300),
                  children: <TextSpan>[
                    TextSpan(
                        text: 'o',
                        style: TextStyle(
//                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor)),
                    TextSpan(text: 'cat'),
                    TextSpan(
                        text: 'o',
                        style: TextStyle(
//                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor)),
                    TextSpan(text: 'r'),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
