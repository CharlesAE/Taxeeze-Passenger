import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxeeze_passenger/authentication/login_screen.dart';
import 'package:taxeeze_passenger/global/app_info.dart';
import 'package:taxeeze_passenger/global/global.dart';
import 'package:taxeeze_passenger/helpers/auth_methods.dart';
import 'package:taxeeze_passenger/helpers/location_methods.dart';
import 'package:taxeeze_passenger/screens/search_screen.dart';
import 'package:taxeeze_passenger/screens/select_driver_screen.dart';
import 'package:taxeeze_passenger/widgets/my_drawer.dart';
import 'package:taxeeze_passenger/widgets/progress_dialog.dart';

import '../helpers/geofire_helper.dart';
import '../models/active_drivers.dart';
import '../models/directions.dart';
import '../widgets/fare_dialog.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
{


  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? newGoogleMapController;
  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(17.1136445, -61.8458701),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);
  final _formKeyScreen1 = GlobalKey<FormState>();
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  double searchLocationContainerHeight  = 200.0;
  double waitingResponseFromDriverContainerHeight = 0;
  double assignedDriverInfoContainerHeight = 0;

  String tripStatus = "";
  double bottomPaddingOfMap = 0;
  String driverRideStatus = "Your driver is on the way!";
  Position? userCurrentPosition;
  var geoLocation = Geolocator();
  bool requestPositionInfo = true;
  LocationPermission? _locationPermission;

  List<LatLng> pLineCoOrdinatesList = [];
  Set<Polyline> polyLineSet = {};
  BitmapDescriptor? iconAnimatedMarker;
  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};


  List<LatLng> pLineTripCoOrdinatesList = [];
  Set<Polyline> polyLineTripSet = {};
  Set<Marker> markersTripSet = {};
  Set<Circle> circlesTripSet = {};

  bool activeNearbyDriverKeysLoaded = false;
  bool navDrawerOpen = true;
  BitmapDescriptor? activeNearbyIcon;

  DocumentReference? tripRequestRef;

  List<ActiveDrivers> nearbyActiveDrivers = [];

  checkLocationPermission() async
  {
    _locationPermission = await Geolocator.requestPermission();

    if(_locationPermission == LocationPermission.denied)
    {
      _locationPermission = await Geolocator.requestPermission();
    }
  }


  locateUserPosition() async {
    //gives the position of current user
    Position cPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPosition;


    LatLng latLgPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition = CameraPosition(target: latLgPosition, zoom: 14);
    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String readable = await LocationMethods.searchAddressForPosition(userCurrentPosition!, context);

    initializeGeofire();
  }



  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    //cleanUp();
    checkLocationPermission();
  }

  cleanUp(){
    setState(() {
      polyLineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoOrdinatesList.clear();
      dList.clear();
    });

    //print(dList);
    if(userCurrentPosition != null) {
      LatLng latLgPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
      CameraPosition cameraPosition = CameraPosition(target: latLgPosition, zoom: 14);
      newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    }
  }

  saveRideRequest() {
   nearbyActiveDrivers = GeoFireHelper.activeDrivers;
   searchNearbyDrivers();
   //createTripRequest();
}


  void createTripRequest() async {

    tripRequestRef = await FirebaseFirestore.instance.collection("trip_requests")
        .add({});
    var pickup = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var dropoff = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    Map<String,dynamic> pickupLocation = {
      'latitude': pickup!.locationLat.toString(),
      'longitude': pickup!.locationLng.toString(),
    };
    Map<String,dynamic> dropOffLocation = {
      'latitude': dropoff!.locationLat.toString(),
      'longitude': dropoff!.locationLng.toString(),

    };
    Map<String,dynamic> tripRequest = {
      'created_at': DateTime.now().toString(),
      'rider_name': currentUser!.name,
      'rider_phone': currentUser!.phone,
      'rider_id' : currentUser!.uid,
      'pickup_address': pickup.locationName,
      'dropoff_address': dropoff.locationName,
      'pickup': pickupLocation,
      'dropoff': dropOffLocation,
      'payment_method': 'card',
      'status': 'requested',
      'driver_id': null,
    };

    //print(tripRequestRef?.id);
    tripRequestRef?.set(tripRequest);
    var response = await Navigator.push(context, MaterialPageRoute(builder: (c)=> SelectDriverScreen(tripRequestRef: tripRequestRef)));

    print(response);
    if(response == "driverChosen")
    {
      print(response);
      //send Notification to selected Driver;


      //Wait for driver's response
      getDriverResponse(tripRequestRef!.id);




      //Accepted


      //Cancelled


    }
  }

  showUIForAssignedDriverInfo()
  {
    print("showUIForAssignedDriverInfo Trip Status ${tripStatus}");
    setState(() {
      waitingResponseFromDriverContainerHeight = 0;
      searchLocationContainerHeight = 0;
      assignedDriverInfoContainerHeight = 200;
    });
  }

  showWaitingResponseFromDriverUI()
  {
    print("showWaitingResponseFromDriverUI Trip Status ${tripStatus}");
    setState(() {
      searchLocationContainerHeight = 0;
      waitingResponseFromDriverContainerHeight = 200;
    });
  }

  cancelTrip(){
    navDrawerOpen = true;
    cleanUp();
    setState(() {
      assignedDriverInfoContainerHeight = 0;
      waitingResponseFromDriverContainerHeight = 0;
      searchLocationContainerHeight = 200;
    });
  }

  displayResponse(){

  }
  getDriverResponse(String id) async {

    print(id);
    var driverInfo;
    var  tripData = FirebaseFirestore.instance.collection('trip_requests');
    showWaitingResponseFromDriverUI();

    var userLocation = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    drawTripPolyLine(driverPosition, userLocation);


   await tripData.doc(id).snapshots().listen((event) async {
     driverInfo = event.data();
     setState(() {
       tripStatus = driverInfo["status"];
       driverName = driverInfo["driver_name"];
     });


     if(tripStatus == "accepted") {
       showUIForAssignedDriverInfo();
       print("Trip Info ${driverInfo}");
       if(driverInfo["driverLiveLocation"] != null) {

         double driverLivePositionLat = double.parse(driverInfo["driverLiveLocation"]["latitude"].toString());
         double driverLivePositionLng = double.parse(driverInfo["driverLiveLocation"]["longitude"].toString());

         LatLng driverLivePositionLatLng = LatLng(driverLivePositionLat, driverLivePositionLng);

         print(driverLivePositionLatLng);

         getRealTimeDriversLocation(driverLivePositionLatLng);
         updateArrivalTimeToUserPickupLocation(driverLivePositionLatLng);
       }


     }

     if(tripStatus == "arrived") {
       setState(() {
         driverRideStatus = "Driver has Arrived";
       });


     }

     if(tripStatus == "enroute") {
       setState(() {
         driverRideStatus = "Trip Started";
        // updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng);
       });

       if(driverInfo["driverLiveLocation"] != null) {

         double driverLivePositionLat = double.parse(driverInfo["driverLiveLocation"]["latitude"].toString());
         double driverLivePositionLng = double.parse(driverInfo["driverLiveLocation"]["longitude"].toString());

         LatLng driverLivePositionLatLng = LatLng(driverLivePositionLat, driverLivePositionLng);

         print(driverLivePositionLatLng);

         getRealTimeDriversLocation(driverLivePositionLatLng);
         updateReachingTimeToUserDropOffLocation(driverLivePositionLatLng);
       }
     }

     if(tripStatus == "complete") {
       setState(() {
         driverRideStatus = "Trip Complete";
         rideFare = driverInfo["fare"];
       });
       streamSubscriptionDriverLivePosition!.cancel();
       Navigator.pop(context);


       var response = await showDialog(
         context: context,
         barrierDismissible: false,
         builder: (BuildContext c) => FareDialog(
           totalFareAmount: rideFare,
         ),
       );

     }
   });


  }

  updateArrivalTimeToUserPickupLocation(driverLivePositionLatLng) async
  {
    if(requestPositionInfo == true)
    {
      requestPositionInfo = false;

      LatLng userPickUpPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

      var directionDetailsInfo = await LocationMethods.getDirectionDetails(
        driverLivePositionLatLng,
        userPickUpPosition,
      );

      if(directionDetailsInfo == null)
      {
        return;
      }

      setState(() {
        driverRideStatus =  "Driver arriving in: " + directionDetailsInfo.duration_text.toString();
      });

      requestPositionInfo = true;
    }
  }


  updateReachingTimeToUserDropOffLocation(driverLivePositionLatLng) async
  {
    if(requestPositionInfo == true)
    {
      requestPositionInfo = false;

      var dropOffLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

      LatLng userDestinationPosition = LatLng(
          dropOffLocation!.locationLat!,
          dropOffLocation!.locationLng!
      );

      var directionDetailsInfo = await LocationMethods.getDirectionDetails(
        driverLivePositionLatLng,
        userDestinationPosition,
      );

      if(directionDetailsInfo == null)
      {
        return;
      }

      setState(() {
        driverRideStatus =  "Time To Destination: " + directionDetailsInfo.duration_text.toString();
      });

      requestPositionInfo = true;
    }
  }
  getRealTimeDriversLocation(driverCurrentPositionLatLng)  async
  {
    LatLng oldLatLng = LatLng(0, 0);
    streamSubscriptionDriverLivePosition = Geolocator.getPositionStream()
        .listen((Position position)
    {


      LatLng latLngLiveDriverPosition = LatLng(
        driverCurrentPositionLatLng.latitude,
        driverCurrentPositionLatLng.longitude,
      );
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: const Size(2, 2));
      Marker animatingMarker = Marker(
        markerId: const MarkerId("AnimatedMarker"),
        position: latLngLiveDriverPosition,
        icon: activeNearbyIcon!,
        infoWindow: const InfoWindow(title: "This is your Position"),
      );

      setState(() {
        CameraPosition cameraPosition = CameraPosition(target: latLngLiveDriverPosition, zoom: 16);
        newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        markersSet.removeWhere((element) => element.markerId.value == "AnimatedMarker");
        markersSet.add(animatingMarker);
      });
      oldLatLng = latLngLiveDriverPosition;




    });
  }


  searchNearbyDrivers() async {
    if(nearbyActiveDrivers.length == 0) {

      cleanUp();
      tripRequestRef?.update({
        "status": "cancelled"
      });
      Provider.of<AppInfo>(context, listen: false).cancelRide();
      Fluttertoast.showToast(msg: "No driver available");
      return;
    }

    //get nearby drivers
    await retrieveNearbyDrivers(nearbyActiveDrivers);
    //Navigator.push(context, MaterialPageRoute(builder: (c)=> SelectDriverScreen()));
  }

  retrieveNearbyDrivers(List driversList) async {
    //print("Drivers length ${driversList.length}");
    var data = FirebaseFirestore.instance.collection("drivers");

    /*
    await data.get().then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        print(doc['name']);
      });
    });
     */

    for(int i = 0; i < driversList.length; i++) {
      dList.clear();
      await data.doc(driversList[i].driverId).get().then((DocumentSnapshot snapshot) {
        //print(snapshot.data());
        var driverInfo = snapshot.data();
        dList.add(driverInfo);
      });
    }
    //print(dList);
    createTripRequest();



  }



  @override
  Widget build(BuildContext context) {
    createActiveNearByDriverIconMarker();
    return Scaffold(
      key: sKey,
      drawer: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.black
        ),
        child: MyDrawer(
          name: currentUser!.name,
          email: currentUser!.email,
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            initialCameraPosition: _kLake,
            polylines: polyLineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController  controller)
            {

              _controller.complete(controller);
              newGoogleMapController = controller;

              newGoogleMapController!.setMapStyle(darkMap());
              setState(() {
                bottomPaddingOfMap = 210;
              });
              locateUserPosition();
            },
          ),


          //custom menu button
          Positioned(
              top:36,
              left: 22,
              child: GestureDetector(
                onTap: (){
                  if(navDrawerOpen) {
                    sKey.currentState!.openDrawer();
                  }
                  else {
                    //Cancel Ride
                    cancelTrip();
                    //SystemNavigator.pop();
                  }

                },
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(
                    navDrawerOpen
                        ? Icons.menu
                        : Icons.close,
                    color: Colors.black54,),),
              )),

          //Request Ride  UI
          Positioned(bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedSize(
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 120),
            child: Container(
              height: searchLocationContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20)
                )
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16.0),
                child: Column(
                  children: [

                    //from (User's current location
                    Row(

                      children: [
                        const Icon(Icons.home_outlined,  color: Colors.grey,),
                        const SizedBox(width: 12.0,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("From",
                              style: TextStyle(color: Colors.grey, fontSize: 12),),
                            Text(
                              Provider.of<AppInfo>(context).userPickUpLocation !=null
                              ? (Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0,24) + "..."
                              : "Location Not Available",
                              style: const TextStyle(color: Colors.grey, fontSize: 12),)
                          ],
                        )

                      ],
                    ),
                    const SizedBox(height: 10,),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16,),


                    //To
                    GestureDetector(
                      onTap: () async
                      {
                        //go to search places screen
                        var responseFromSearchScreen = await Navigator.push(context, MaterialPageRoute(builder: (c)=> SearchScreen()));

                        if(responseFromSearchScreen == "obtainedDropoff")
                        {
                          setState(() {
                            navDrawerOpen = false;
                          });

                          await drawPolyLine();
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.add_location_alt_outlined,  color: Colors.grey,),
                          const SizedBox(width: 12.0,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:  [
                              const Text("To",
                                style: TextStyle(color: Colors.grey, fontSize: 12),),
                              Text(
                                Provider.of<AppInfo>(context).userDropOffLocation !=  null
                                    ? (Provider.of<AppInfo>(context).userDropOffLocation!.locationName!)
                                    : "Your Drop Off Location",
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),)
                            ],
                          )

                        ],
                      ),
                    ),
                    const SizedBox(height: 10,),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16,),

                    ElevatedButton(
                        onPressed: (){
                          if(Provider.of<AppInfo>(context, listen: false).userDropOffLocation !=null)
                          {
                            saveRideRequest();
                          }
                          else
                            {
                              Fluttertoast.showToast(msg: "Please choose a drop off location");
                            }
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                        child: Text("Request A Ride"))
                  ],
                ),
              ),
            ),
          ),),

          //UI For Driver Response
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: waitingResponseFromDriverContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: AnimatedTextKit(
                    animatedTexts: [
                      FadeAnimatedText(
                        'Waiting for Response\nfrom Driver',
                        duration: const Duration(seconds: 6),
                        textAlign: TextAlign.center,
                        textStyle: const TextStyle(fontSize: 30.0, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      ScaleAnimatedText(
                        'Please wait...',
                        duration: const Duration(seconds: 10),
                        textAlign: TextAlign.center,
                        textStyle: const TextStyle(fontSize: 32.0, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //ui for displaying assigned driver information
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: assignedDriverInfoContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //status of ride
                    Center(
                      child: Text(
                        driverRideStatus,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20.0,
                    ),

                    const Divider(
                      height: 2,
                      thickness: 2,
                      color: Colors.white54,
                    ),


                    //driver vehicle details


                    const SizedBox(
                      height: 2.0,
                    ),

                    //driver name
                    Text(
                      driverName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(
                      height: 20.0,
                    ),

                    const Divider(
                      height: 2,
                      thickness: 2,
                      color: Colors.white54,
                    ),

                    const SizedBox(
                      height: 20.0,
                    ),

                    //call driver button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: ()
                        {

                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green,
                        ),
                        icon: const Icon(
                          Icons.phone_android,
                          color: Colors.black54,
                          size: 22,
                        ),
                        label: const Text(
                          "Call Driver",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),


        ],
      ),
    );
  }

  Future<void> drawPolyLine() async {
    var origin = Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destination = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    var originLatLng = LatLng(origin!.locationLat!, origin!.locationLng!);
    var destinationLatLng = LatLng(destination!.locationLat!, destination!.locationLng!);

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(message: "Please Wait...",)
    );
    var directionDetails = await LocationMethods.getDirectionDetails(originLatLng, destinationLatLng);

    setState(() {
      tripDirectionDetailsInfo = directionDetails;
    });

    Navigator.pop(context);
    //print("Points");
    //print(directionDetails!.e_points);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResultList = pPoints.decodePolyline(directionDetails!.e_points!);

    pLineCoOrdinatesList.clear();

    if(decodedPolyLinePointsResultList.isNotEmpty)
    {
      for (var pointLatLng in decodedPolyLinePointsResultList) {
        pLineCoOrdinatesList.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }

    polyLineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.red,
        polylineId: const PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoOrdinatesList,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polyLineSet.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if(originLatLng.latitude > destinationLatLng.latitude && originLatLng.longitude > destinationLatLng.longitude)
    {
      boundsLatLng = LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    }
    else if(originLatLng.longitude > destinationLatLng.longitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    }
    else if(originLatLng.latitude > destinationLatLng.latitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    }
    else
    {
      boundsLatLng = LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }

    newGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));


    Marker originMarker = Marker(
      markerId: const MarkerId("originID"),
      infoWindow: InfoWindow(title: origin.locationName, snippet: "Origin"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId("destinationID"),
      infoWindow: InfoWindow(title: destination.locationName, snippet: "Destination"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    setState(() {
      markersSet.add(originMarker);
      markersSet.add(destinationMarker);
    });

    Circle originCircle = Circle(
      circleId: const CircleId("originID"),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId("destinationID"),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setState(() {
      circlesSet.add(originCircle);
      circlesSet.add(destinationCircle);
    });

  }



  Future<void> drawTripPolyLine(LatLng pickup, LatLng destination) async {

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => ProgressDialog(message: "Please Wait...",)
    );
    var directionDetails = await LocationMethods.getDirectionDetails(pickup, destination);



    Navigator.pop(context);


    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResultList = pPoints.decodePolyline(directionDetails!.e_points!);

    pLineTripCoOrdinatesList.clear();
    //pLineCoOrdinatesList.clear();

    if(decodedPolyLinePointsResultList.isNotEmpty)
    {
      for (var pointLatLng in decodedPolyLinePointsResultList) {
        pLineTripCoOrdinatesList.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }

    //polyLineSet.clear();
    polyLineTripSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.yellowAccent,
        polylineId: const PolylineId("PolylineTripID"),
        jointType: JointType.round,
        points: pLineTripCoOrdinatesList,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polyLineTripSet.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if(pickup.latitude > destination.latitude && pickup.longitude > destination.longitude)
    {
      boundsLatLng = LatLngBounds(southwest: destination, northeast: pickup);
    }
    else if(pickup.longitude > destination.longitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(pickup.latitude, destination.longitude),
        northeast: LatLng(destination.latitude, pickup.longitude),
      );
    }
    else if(pickup.latitude > destination.latitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destination.latitude, pickup.longitude),
        northeast: LatLng(pickup.latitude, destination.longitude),
      );
    }
    else
    {
      boundsLatLng = LatLngBounds(southwest: pickup, northeast: destination);
    }

    newGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));


    Marker originMarker = Marker(
      markerId: const MarkerId("originTripID"),
      //infoWindow: InfoWindow(title: origin.locationName, snippet: "Origin"),
      position: pickup,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId("destinationTripID"),
      //infoWindow: InfoWindow(title: tripDetails!.destinationAddress!, snippet: "Destination"),
      position: destination,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    setState(() {
      markersTripSet.add(originMarker);
      markersTripSet.add(destinationMarker);
    });

    Circle originCircle = Circle(
      circleId: const CircleId("originTripID"),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: pickup,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId("destinationTripID"),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destination,
    );

    setState(() {
      circlesTripSet.add(originCircle);
      circlesTripSet.add(destinationCircle);
    });

  }
  //display active drivers
  initializeGeofire(){
    Geofire.initialize("activeDrivers");
    print("Geofire initialized");
    Geofire.queryAtLocation(
        userCurrentPosition!.latitude, userCurrentPosition!.longitude, 10)!
        .listen((map) {
      print("Geofire ${map} Map");
      if (map != null) {
        var callBack = map['callBack'];


        switch (callBack)
            {
        //called when a driver comes online
          case Geofire.onKeyEntered:
            ActiveDrivers activeDriver = ActiveDrivers();
            activeDriver.latitude = map['latitude'];
            activeDriver.longitude = map['longitude'];
            activeDriver.driverId = map['key'];
            GeoFireHelper.activeDrivers.add(activeDriver);
            //displayActiveDrivers();
            if(activeNearbyDriverKeysLoaded == true)
            {
              displayActiveDrivers();
            }
            break;

        //called when a goes offline
          case Geofire.onKeyExited:
            GeoFireHelper.removeOfflineDriver(map['key']);
            //displayActiveDrivers();
            break;

        //called when a driver's location changes
          case Geofire.onKeyMoved:
            ActiveDrivers activeDriver = ActiveDrivers();
            activeDriver.latitude = map['latitude'];
            activeDriver.longitude = map['longitude'];
            activeDriver.driverId = map['key'];
            GeoFireHelper.updateDriverLocation(activeDriver);
            displayActiveDrivers();
            break;

        //display active drivers
          case Geofire.onGeoQueryReady:
            activeNearbyDriverKeysLoaded = true;
            displayActiveDrivers();
            break;
        }
      }

      setState(() {});
    });
  }

  displayActiveDrivers()
  {
    print("displayActiveDrivers called");
    setState(() {
      markersSet.clear();
      circlesSet.clear();
    });
      Set<Marker> driversMarkerSet = Set<Marker>();

      for(ActiveDrivers driver in GeoFireHelper.activeDrivers)
      {
        LatLng eachDriverActivePosition = LatLng(driver.latitude!, driver.longitude!);

        Marker marker = Marker(
          markerId: MarkerId("driver"+driver.driverId!),
          position: eachDriverActivePosition,
          icon: activeNearbyIcon!,
          rotation: 360,
        );

        driversMarkerSet.add(marker);
      }

      setState(() {
        markersSet = driversMarkerSet;
      });

  }

  createActiveNearByDriverIconMarker()
  {
    if(activeNearbyIcon == null)
    {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: const Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "assets/images/car.png").then((value)
      {
        activeNearbyIcon = value;
      });
    }
  }
}
