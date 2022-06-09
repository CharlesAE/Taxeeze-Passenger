import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveDrivers
{
  String? driverId;
  double? latitude;
  double? longitude;

  ActiveDrivers({
    this.driverId,
    this.latitude,
    this.longitude,
  });

  ActiveDrivers.fromSnapshot(DocumentSnapshot snapshot)
      : assert(snapshot != null),
        driverId = snapshot.id;

  static ActiveDrivers fromJson(Map<String, dynamic> json) => ActiveDrivers(
    driverId: json['id']);
}