import 'package:flutter/material.dart';

import '../models/directions.dart';

class AppInfo extends ChangeNotifier
{
  Directions? userPickUpLocation, userDropOffLocation;

  void updatePickUpLocation(Directions userPickUpAddress){
    userPickUpLocation = userPickUpAddress;
    notifyListeners();
  }
  void updateDropOffLocation(Directions userDropOffAddress){
    userDropOffLocation = userDropOffAddress;
    notifyListeners();
  }

  void cancelRide(){
    userDropOffLocation = null;
    notifyListeners();
  }
}