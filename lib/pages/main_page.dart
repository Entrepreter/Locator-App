import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:locator/demo_data.dart';
import 'package:locator/pages/online_users.dart';
import 'package:locator/pages/profile_page.dart';
import 'package:locator/utils/google_sign_in.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool mapReady = false;
  bool isUserLoggedIn = false;

  String displayName;
  String imageUrl;
  String UID;

  LatLng pinPosition;

  FirebaseUser _user;

  final CameraPosition _center =
      CameraPosition(target: LatLng(28.8190703, 78.7731869), zoom: 16.24);

  Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Stack(
          children: <Widget>[
            //map widget
            makeGoogleMap(),
            //login widget
            makeLoginWidget(),
            //other widgets may be  //like loading on top of all
            makeLoading()
          ],
        ),
      ),
    );
  }

  Widget makeLoginWidget() {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: Hero(
            tag: 'profile_url',
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => !isUserLoggedIn
                    ? null
                    : Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProfilePage(_user))),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: imageUrl == null
                      ? Icon(
                          Icons.person,
                          color: Colors.grey,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(imageUrl),
                        ),
                ),
              ),
            ),
          ),
          title: RaisedButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            color: Colors.white,
            onPressed: () => isUserLoggedIn ? null : signInUser(),
            child: Text(
              displayName == null ? "Login With Google" : displayName,
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          trailing: Material(
            elevation: 2,
            child: InkWell(
              onTap: () {
                //if logged in show the sheet
                //else show the snackbar with saying only logged in user can sharing his location
                if (isUserLoggedIn) {
                  showSharingPanel();
                } else {
                  SnackBar snackBar = SnackBar(
                    content:
                        Text("Can't share live location without loging in"),
                    action: SnackBarAction(
                      onPressed: () {},
                      label: "Login",
                    ),
                  );
                  Scaffold.of(context).showSnackBar(snackBar);
                }
              },
              child: Container(
                padding: EdgeInsets.all(5.5),
                color: Theme.of(context).primaryColor,
                child: Icon(
                  Icons.share,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> signInUser() {
    return SignInHelper.signInWithGoogle().then((value) {
      if (value != null) {
        assert(value.photoUrl != null);
        assert(value.displayName != null);
        assert(value.uid != null);

        setState(() {
          _user = value;
          displayName = value.displayName;
          UID = value.uid;
          imageUrl = value.photoUrl;
          isUserLoggedIn = true;
        });
      }
    });
  }

  Widget makeGoogleMap() {
    return GoogleMap(
      buildingsEnabled: true,
      indoorViewEnabled: true,
      initialCameraPosition: _center,
      mapType: MapType.normal,
      myLocationButtonEnabled: false,
      myLocationEnabled: true,
      onMapCreated: onMapCreated,
    );
  }

  Widget makeLoading() {
    return Visibility(
      visible: !mapReady,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              backgroundColor: Colors.white,
              child: CircularProgressIndicator(),
            ),
            Container(
              padding: EdgeInsets.all(4.0),
              margin: EdgeInsets.all(2.0),
              child: Text(
                "Loading map...",
                style: TextStyle(color: Colors.white),
              ),
              color: Colors.black.withOpacity(0.50),
            ),
          ],
        ),
      ),
    );
  }

  showSharingPanel() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return OnlineUsers();
        });
  }

  onMapCreated(GoogleMapController controller) {
    setState(() {
      mapReady = true;
    });
    _controller.complete(controller);
  }
}
