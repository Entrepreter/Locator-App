import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:locator/pages/main_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool haveLocationPermission = false;
  bool isLocationSharingOn = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    location.serviceEnabled().then((value) {
      if (value) {
        setState(() {
          isLocationSharingOn = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        //if permission is already granted then make it invisible
        body: Visibility(
          visible: !haveLocationPermission,
          child: makeFirstView(haveLocationPermission),
          replacement: Visibility(
            child: makeFirstView(true),
            visible: !isLocationSharingOn,
            replacement: MainPage(),
          ),
        ),
      ),
    );
  }

  Widget makeFirstView(bool haveLocationPermission) {
    return Container(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width * 0.80,
            child: Image.asset(haveLocationPermission
                ? 'assets/images/location_sharing_off.png'
                : 'assets/images/location_permission.png'),
          ),
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * .90),
            child: Text(
              haveLocationPermission
                  ? "Location sharing is turned off"
                  : "App needs location permission to work",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
              ),
            ),
          ),
          SizedBox(height: 16),
          InkWell(
            onTap: () {
              print("is tapping");
              haveLocationPermission
                  ? openLocationSharing()
                  : askForLocationPermission();
            },
            child: Container(
              child: Text(
                haveLocationPermission
                    ? "Open Location Sharing"
                    : "Give Permission",
                style: TextStyle(
                    fontSize: 16, color: Theme.of(context).primaryColor),
              ),
            ),
          )
        ],
      ),
    );
  }

  Location location = Location.instance;

  askForLocationPermission() {
    location.requestPermission().then((value) => {
          if (value == PermissionStatus.granted)
            {
              setState(() {
                haveLocationPermission = true;
              })
            }
        });
  }

  openLocationSharing() {
    location.requestService().then((value) {
      if (value) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MainPage()));
      } else {
        //do nothing stay here
      }
    });
  }
}
