import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:locator/utils/database_helper.dart';
import 'package:locator/utils/google_sign_in.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _completer = Completer();
  GoogleMapController _googleMapController;

  final Location _locationTracker = Location.instance;
  LocationData _currentUserLocationData;

  StreamSubscription _locationSubs;
  Set<Marker> _markers = {};

  FirebaseUser _user;

  LatLng _previousLatLng;

  Timer timer;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.currentUser().then((value) {
      if (value != null) {
        setState(() {
          _user = value;
        });
      }
    });
    //for looking into changes
    lookLocationChange();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => moveToMyPosition(_currentUserLocationData),
        child: Icon(
          Icons.my_location,
          color: Colors.white,
        ),
      ),
      body: Container(
        child: Stack(
          children: [
            buildGoogleMap(),
            buildLoginTile(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    if (_locationSubs != null) {
      _locationSubs.cancel();
    }

    timer?.cancel();
  }

  //widgets method
  Widget buildGoogleMap() {
    final _initialMapPosition =
        CameraPosition(target: LatLng(25.4175466, 56.9139672), zoom: 4.19);

    return GoogleMap(
      initialCameraPosition: _initialMapPosition,
      onMapCreated: onMapCreated,
      markers: _markers,
      mapToolbarEnabled: false,
    );
  }

  buildLoginTile() {
    return SafeArea(
      child: Container(
          margin: EdgeInsets.all(8.0),
          padding: EdgeInsets.all(8),
//          color: Colors.white,
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(4),
                color: Colors.white,
                child: CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.2),
                    child: _user == null
                        ? Icon(
                            Icons.person,
                            color: Colors.grey,
                          )
                        : Container(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.network(_user.photoUrl),
                            ),
                          )),
              ),
              InkWell(
                onTap: _user == null
                    ? () {
                        signAndLogInDb();
                        setState(() {});
                      }
                    : null,
                child: Container(
                  padding: EdgeInsets.all(12),
                  color: Colors.white,
                  child: Text(
                    _user == null ? "Login with google" : _user.displayName,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text("|"),
                color: Colors.white,
              ),
              InkWell(
                onTap: () {
                  SignInHelper.signOutGoogle();
                  FirebaseAuth.instance.currentUser().then((value) {
                    setState(() {
                      _user = value;
                    });
                  });
                  setState(() {});
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  color: Colors.white,
                  child: Text(
                    "Logout",
                  ),
                ),
              ),
              Spacer(),
              InkWell(
                onTap: () {
                  showOnlineUsers();
                },
                child: Container(
                    padding: EdgeInsets.all(6),
                    color: Theme.of(context).primaryColor,
                    child: Icon(
                      Icons.share,
                      color: Colors.white,
                    )),
              ),
            ],
          )),
    );
  }

  Future signAndLogInDb() async {
    FirebaseUser user = await SignInHelper.signInWithGoogle();
    _user = user;
    Firestore.instance.collection('users').document(_user.uid).setData({
      'user_name': _user.displayName,
      'photo_url': _user.photoUrl,
      'public_id': _user.uid.substring(0, 6)
    });
    setState(() {});
  }

  //utility functions
  onMapCreated(GoogleMapController googleMapController) {
    _completer.complete(googleMapController);
    _googleMapController = googleMapController;
    getInitialPosition();
  }

  moveToMyPosition(posi) {
    if (_googleMapController != null) {
      _googleMapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(posi.latitude, posi.longitude), zoom: 16.24)));
    }
  }

  getInitialPosition() async {
    _currentUserLocationData = await _locationTracker.getLocation();

    writeDataToDb(_currentUserLocationData);

    _previousLatLng = LatLng(
        double.parse(
            _currentUserLocationData.latitude.toStringAsExponential(2)),
        double.parse(
            _currentUserLocationData.longitude.toStringAsExponential(2)));
    moveToMyPosition(_currentUserLocationData);
    addMarkerToMyLocation(_currentUserLocationData);
    addMarkerToMyLocation(_currentUserLocationData);
  }

  void lookLocationChange() {
    //for looking into changes
    if (_locationSubs != null) {
      _locationSubs.cancel();
    }
    _locationSubs =
        _locationTracker.onLocationChanged.listen((newLocationData) {
      if (_user != null) {
        timer = new Timer.periodic(const Duration(minutes: 1), (t) {
          //changed 6 digit after decimal of  double to String, then again double
          LatLng currentLatLng = LatLng(
            double.parse(newLocationData.latitude.toStringAsExponential(2)),
            double.parse(newLocationData.longitude.toStringAsExponential(2)),
          );
          if (currentLatLng != _previousLatLng) {
            writeDataToDb(newLocationData);
            _previousLatLng = currentLatLng;
          }
        });
      }
      setState(() {
        _currentUserLocationData = newLocationData;
        addMarkerToMyLocation(_currentUserLocationData);
      });
    });
  }

  addMarkerToMyLocation(LocationData data) async {
    Uint8List imageData = await getMarker(true);
    LatLng posi = LatLng(data.latitude, data.longitude);
    setState(() {
      _markers.add(Marker(
          position: posi,
          markerId: MarkerId("user_current_uid"),
          infoWindow: InfoWindow(title: "user name", snippet: "a time ago"),
          icon: BitmapDescriptor.fromBytes(imageData)));
    });
  }

  Future<Uint8List> getMarker(bool isCurrentUser) async {
    ByteData byteData = await DefaultAssetBundle.of(context).load(isCurrentUser
        ? "assets/my_location.png"
        : "assets/others_location.png");
    return byteData.buffer.asUint8List();
  }

  writeDataToDb(LocationData data) {
    Firestore.instance
        .collection('users')
        .document(_user.uid)
        .collection('location_paths')
        .add(DatabaseHelper.locationDataToMap(data));
  }

  showOnlineUsers() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.30,
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    "Online Users",
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                  trailing: InkWell(
                    child: Icon(
                      Icons.close,
//                      color: Colors.white,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                StreamBuilder(
                  stream: Firestore.instance.collection('users').snapshots(),
                  builder: (context, snap) {
                    if (snap.hasData) {
                      var docs = snap.data.documents;
                      if (docs.length > 1) {
                        return ListView.builder(
                            shrinkWrap: true,
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              DocumentSnapshot ref = docs[index];
                              if (ref.documentID == _user.uid)
                                return Container();
                              else
                                return ListTile(
                                  title: Text(docs[index]['user_name']),
                                  leading: Container(
                                    child: CircleAvatar(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Image.network(
                                            docs[index]['photo_url']),
                                      ),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        child: Container(
                                          child: Text("Ask"),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 16,
                                      ),
                                      InkWell(
                                        child: Container(
                                          child: Text(
                                            "Share",
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColor),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                            });
                      } else {
                        return Center(
                          child: Text("No user online"),
                        );
                      }
                    } else {
                      Future.delayed(Duration(seconds: 30)).then((value) {
                        return Center(child: Text("Something went wrong"));
                      });
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                )
              ],
            ),
          );
        });
  }
}
