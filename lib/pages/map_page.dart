import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:locator/model/users.dart';
import 'package:network_image_to_byte/network_image_to_byte.dart';

import 'package:timeago/timeago.dart' as timeAgo;

import 'package:locator/utils/database_helper.dart';
import 'package:locator/utils/google_sign_in.dart';
import 'package:locator/utils/my_behaviour.dart';

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
  User _currentUser;

  LatLng _previousLatLng;

  Timer timer;

  StreamSubscription otherUsersStreams;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.currentUser().then((value) {
      if (value != null) {
        setState(() {
          _user = value;
          _currentUser = User(_user.displayName, _user.photoUrl, _user.uid);
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
            isLoading ? buildLoadingWidget() : Container(),
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

  Widget buildLoadingWidget() {
    return Container(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              child: FloatingActionButton(
                  mini: true,
                  onPressed: () {},
                  backgroundColor: Colors.white,
                  child: CircularProgressIndicator()),
            ),
            SizedBox(
              height: 2,
            ),
            Container(
              padding: EdgeInsets.all(4),
              child: Text(
                "Getting location...",
                style: TextStyle(color: Colors.white),
              ),
              color: Colors.black.withOpacity(0.30),
            )
          ],
        ),
      ),
    );
  }

  //widgets method
  Widget buildGoogleMap() {
    final _initialMapPosition =
        CameraPosition(target: LatLng(25.4175466, 56.9139672), zoom: 4.19);

    return GoogleMap(
      initialCameraPosition: _initialMapPosition,
      onMapCreated: onMapCreated,
      markers: _markers,
      compassEnabled: false,
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
              Material(
                elevation: 1,
                child: Container(
                  padding: EdgeInsets.all(4),
                  color: Colors.white,
                  child: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.2),
                      child: _currentUser == null
                          ? Icon(
                              Icons.person,
                              color: Colors.grey,
                            )
                          : Container(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.network(_currentUser.photoUrl),
                              ),
                            )),
                ),
              ),
              InkWell(
                onTap: _currentUser == null
                    ? () {
                        signAndLogInDb();
                        setState(() {});
                      }
                    : null,
                child: Material(
                  elevation: 1,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    color: Colors.white,
                    child: Text(
                      _user == null
                          ? "Login with google"
                          : _currentUser.displayName,
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
              ),
              Material(
                elevation: 1,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text("|"),
                  color: Colors.white,
                ),
              ),
              InkWell(
                onTap: () {
                  SignInHelper.signOutGoogle();
                  FirebaseAuth.instance.currentUser().then((value) {
                    setState(() {
                      _user = value;
                      _currentUser =
                          User(_user.displayName, _user.photoUrl, _user.uid);
                    });
                  });
                  setState(() {});
                },
                child: Material(
                  elevation: 1,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    color: Colors.white,
                    child: Text(
                      "Logout",
                    ),
                  ),
                ),
              ),
              Spacer(),
              Builder(builder: (context) {
                return InkWell(
                  onTap: () {
                    _currentUser == null
                        ? showSnackBar(context)
                        : showOnlineUsers();
                  },
                  child: Material(
                    elevation: 1,
                    child: Container(
                        padding: EdgeInsets.all(6),
                        color: Theme.of(context).primaryColor,
                        child: Icon(
                          Icons.share,
                          color: Colors.white,
                        )),
                  ),
                );
              }),
            ],
          )),
    );
  }

  Future signAndLogInDb() async {
    FirebaseUser user = await SignInHelper.signInWithGoogle();
    _user = user;
    _currentUser = User(_user.displayName, _user.photoUrl, _user.uid);
    Firestore.instance.collection('users').document(_user.uid).setData({
      'user_name': _currentUser.displayName,
      'photo_url': _currentUser.photoUrl,
      'public_id': _currentUser.uid.substring(0, 6)
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

    if (_currentUser != null) {
      writeDataToDb(_currentUserLocationData);
    }
    _previousLatLng = LatLng(
        double.parse(
            _currentUserLocationData.latitude.toStringAsExponential(2)),
        double.parse(
            _currentUserLocationData.longitude.toStringAsExponential(2)));
    moveToMyPosition(_currentUserLocationData);
    addMarkerToMyLocation(_currentUserLocationData, _currentUser);
  }

  void lookLocationChange() {
    //for looking into changes
    if (_locationSubs != null) {
      _locationSubs.cancel();
    }
    _locationSubs =
        _locationTracker.onLocationChanged.listen((newLocationData) {
      if (_currentUser != null) {
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
        addMarkerToMyLocation(_currentUserLocationData, _currentUser);
      });
    });
  }

  addMarkerToMyLocation(LocationData data, User user) async {
    Uint8List imageData;
    if (user == null) {
      imageData = await getMarker(true);
    } else {
      if (user.uid == _user.uid) {
        imageData = await getMarker(true);
      } else {
        imageData = await getMarker(false);
      }
    }
    DateTime time =
        DateTime.fromMicrosecondsSinceEpoch((data.time * 1000).toInt());
    LatLng posi = LatLng(data.latitude, data.longitude);
    setState(() {
      _markers.add(Marker(
          position: posi,
          markerId: MarkerId(user == null ? "Anonymous" : user.uid),
          infoWindow: InfoWindow(
              title: user == null
                  ? "Anonymous"
                  : user.uid == _currentUser.uid ? "You" : user.displayName,
              snippet: timeAgo.format(time)),
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
        .document(_currentUser.uid)
        .collection('location_paths')
        .add(DatabaseHelper.locationDataToMap(data));
  }

  showOnlineUsers() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            color: Colors.white,
            height: MediaQuery.of(context).size.height * 0.30,
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    "All Users",
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
                        return Expanded(
                          child: ScrollConfiguration(
                            behavior: MyBehavior(),
                            child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  DocumentSnapshot ref = docs[index];
                                  if (ref.documentID == _currentUser.uid) {
                                    return Container();
                                  } else {
                                    var photoUrl = docs[index]['photo_url'];
                                    var displayName = docs[index]['user_name'];
                                    var uid = docs[index].documentID;

                                    User user =
                                        User(displayName, photoUrl, uid);
                                    return ListTile(
                                      title: Text(displayName),
                                      leading: Container(
                                        child: CircleAvatar(
                                          radius: 16,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            child: Image.network(photoUrl),
                                          ),
                                        ),
                                      ),
                                      trailing: FlatButton(
                                        padding: EdgeInsets.all(8),
                                        onPressed: () {
                                          updateOthersMarker(context, user);
                                        },
                                        child: Text(
                                          "Ask",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                      ),
                                    );
                                  }
                                }),
                          ),
                        );
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

  void updateOthersMarker(BuildContext context, User user) {
    Navigator.pop(context);
    setState(() {
      isLoading = true;
    });
    if (otherUsersStreams != null) {
      otherUsersStreams.cancel();
    }
    otherUsersStreams = Firestore.instance
        .collection('users')
        .document('edc1ohBBI1ZAVftYL4Xxjl8dlkV2')
        .collection('location_paths')
        .orderBy('time', descending: true)
        .limit(1)
        .snapshots()
        .listen((e) {
      setState(() {
        isLoading = false;
      });
      if (e.documents.length > 0) {
        LocationData locationData =
            LocationData.fromMap((e.documents[0].data).cast<String, double>());

        addMarkerToMyLocation(locationData, user);
      }
    });
  }

  showSnackBar(context) {
    SnackBar snackBar = SnackBar(
      content: Text("For sharing locations, login is required"),
      action: SnackBarAction(
        label: "Login",
        onPressed: () {
          signAndLogInDb();
        },
      ),
    );
    Scaffold.of(context).showSnackBar(snackBar);
  }
}
