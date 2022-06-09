import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxeeze_passenger/global/app_info.dart';
import 'package:taxeeze_passenger/global/global.dart';
import 'package:taxeeze_passenger/helpers/request_methods.dart';
import 'package:taxeeze_passenger/models/predicted_places.dart';
import 'package:taxeeze_passenger/widgets/progress_dialog.dart';

import '../models/directions.dart';

class PlacePredictionTileDesign extends StatelessWidget
{
  final PredictedPlaces? predictedPlaces;

  PlacePredictionTileDesign({this.predictedPlaces});

  getPlaceDirectionDetails(String? placeID, context) async {
    showDialog(context: context, builder: (BuildContext context) => ProgressDialog(
      message: "Setting drop off location",
    ));

    String placeDirectionDetails = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeID&key=$mapKey";
    var apiResponse = await RequestMethods.receiveRequest(placeDirectionDetails);

    Navigator.pop(context);

    if(apiResponse  == "Error Occurred, Failed. No Response.")
    {
      return;
    }
    if(apiResponse["status"] == "OK") {
      Directions directions = Directions();
      directions.locationID = placeID;
      directions.locationName = apiResponse["result"]["name"];
      directions.locationLat = apiResponse["result"]["geometry"]["location"]["lat"];
      directions.locationLng = apiResponse["result"]["geometry"]["location"]["lng"];
      Provider.of<AppInfo>(context, listen: false).updateDropOffLocation(directions);
      Navigator.pop(context, "obtainedDropoff");
    }
  }
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: (){
          getPlaceDirectionDetails(predictedPlaces!.place_id, context);
    },
        style: ElevatedButton.styleFrom(primary: Colors.white12),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
      children: [
          Icon(Icons.add_location, color: Colors.grey,),
          const SizedBox(width: 14.0,),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8.0,),
              Text(predictedPlaces!.main_text!,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white54
              ),),
              const SizedBox(height: 2,),
              Text(predictedPlaces!.secondary_text!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54
                ),),
              const SizedBox(height: 8.0,),
            ],
          ))
      ],
    ),
        ));
  }
}
