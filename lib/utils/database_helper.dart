import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';

class DatabaseHelper {
  static Map<String, dynamic> locationDataToMap(LocationData data) {
    return {
      'latitude': data.latitude,
      'longitude': data.longitude,
      'accuracy': data.accuracy,
      'altitude': data.altitude,
      'speed': data.speed,
      'speed_accuracy': data.speedAccuracy,
      'heading': data.heading,
      'time': data.time
    };
  }
}
