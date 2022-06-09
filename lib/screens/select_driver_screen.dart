import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxeeze_passenger/screens/main_screen.dart';

import '../global/app_info.dart';
import '../global/global.dart';
import '../helpers/location_methods.dart';
import '../models/direction_details.dart';
import '../models/directions.dart';

class SelectDriverScreen extends StatefulWidget {
  DocumentReference? tripRequestRef;

  SelectDriverScreen({this.tripRequestRef});

  @override
  State<SelectDriverScreen> createState() => _SelectDriverScreenState();
}

class _SelectDriverScreenState extends State<SelectDriverScreen> {
  String fareAmount = "";
  String driver = "";

  getFareAmount()
  {
    fareAmount = (LocationMethods.estimateFare(tripDirectionDetailsInfo!) / 2).toStringAsFixed(1);

    return fareAmount;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white54,
        title: const Text(
          "Nearest Online Drivers",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
              Icons.close, color: Colors.white
          ),
          onPressed: ()
          {
            widget.tripRequestRef?.update({
              "status": "cancelled"
            });
            setState(() {
              dList.clear();
              //print(dList);
            });

            Provider.of<AppInfo>(context, listen: false).cancelRide();
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (BuildContext context) {
              return MainScreen();
            }), (route) => false);


            //SystemNavigator.pop();

          },
        ),
      ),
      body: ListView.builder(
        itemCount: dList.length,
        itemBuilder: (BuildContext context, int index)
        {
          return GestureDetector(
            onTap: () {
              //print(dList[index].toString());
              double driverLivePositionLat = double.parse(dList[index]["driverLocation"]["latitude"].toString());
              double driverLivePositionLng = double.parse(dList[index]["driverLocation"]["longitude"].toString());
              setState(() {
                driverId = dList[index]["uid"].toString();
                driver = dList[index]["name"].toString();

                driverPosition = LatLng(driverLivePositionLat, driverLivePositionLng);


              });
              widget.tripRequestRef?.update({
                "driver_id": driverId,
                "driver_name": driver
              });
              Navigator.pop(context, "driverChosen");
            },
            child: Card(
              color: Colors.grey,
              elevation: 3,
              shadowColor: Colors.green,
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Image.asset(
                    "assets/images/uber-x.png",
                    width: 70,
                  ),
                ),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      dList[index]["name"],
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                    //SizedBox(height: 8,),
                    Text(
                      "Toyota Vitz",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),

                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                "\$ ${LocationMethods.estimateFare(tripDirectionDetailsInfo)}"
                      ,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 2,),
                    Text(
                      tripDirectionDetailsInfo != null ? tripDirectionDetailsInfo!.distance_text! : "",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          fontSize: 12
                      ),
                    ),
                    const SizedBox(height: 2,),
                    Text(
                      tripDirectionDetailsInfo != null ? tripDirectionDetailsInfo!.duration_text! : "",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          fontSize: 12
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

            /*Column(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    color: Colors.amber,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: <Widget>[
                          Image.asset("assets/images/uber-x.png", height: 70, width: 70,),
                          SizedBox(width: 16,),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(dList[index]["name"], style: TextStyle(fontSize: 18, fontFamily: "Brand-Bold"),),
                              Text("13 km", style: TextStyle(fontSize: 16, color: Colors.black),)
                            ],
                          ),
                          Expanded(child: Container()),
                          Text("\$ 12", style: TextStyle(fontSize: 18, fontFamily: "Brand-Bold"),)
                        ],
                      ),
                    ),
                  )

                ]

            );*/
        },
      ),
    );
  }
}
