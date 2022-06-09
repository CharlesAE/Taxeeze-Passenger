import 'package:flutter/material.dart';
import 'package:taxeeze_passenger/global/global.dart';
import 'package:taxeeze_passenger/helpers/auth_methods.dart';
import 'package:taxeeze_passenger/helpers/request_methods.dart';
import 'package:taxeeze_passenger/models/predicted_places.dart';
import 'package:taxeeze_passenger/widgets/place_prediction_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
{
  List<PredictedPlaces> placesPredictedList = [];

  void findPlaceAutoComplete(String inputText) async{
    if(inputText.length > 1)
      {
        //Make api call with text user typed
        String urlAutoComplete = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${inputText}&key=$mapKey&components=country:ag";
        //&location=37.76999%2C-122.44696
        //&radius=500
        //&types=establishment

        // Assign response to variable
        var responseAutoComplete = await RequestMethods.receiveRequest(urlAutoComplete);
        if(responseAutoComplete == "Error Occurred, Failed. No Response.") {
          return;
        }
        if(responseAutoComplete["status"] == "OK")
          {
            // Response is in json format
           var predictions = responseAutoComplete["predictions"];


           var predictionsList = (predictions as List).map((jsonData) => PredictedPlaces.fromJson(jsonData)).toList();
           setState(() {
             placesPredictedList = predictionsList;
           });

          }
      }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          //Search UI
          Container(
            height: 160,
            decoration: const BoxDecoration(
              color: Colors.black54,
              boxShadow: [
                BoxShadow(
                  color: Colors.white54,
                  blurRadius: 8,
                  spreadRadius: 0.5,
                  offset: Offset(
                    0.7, 0.7,
                  )
                )
              ]
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  const SizedBox(height: 25,),
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: (){
                          Navigator.pop(context);
                          },
                        child: Icon(Icons.arrow_back,  color: Colors.grey,),
                      ),
                      const Center(
                        child: Text("Search for drop off location",
                        style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),),
                      )

                    ],
                  ),
                  const SizedBox(height: 16.0,),
                  Row(
                    children: [
                      Icon(Icons.adjust_sharp, color: Colors.grey,),
                      const SizedBox(width: 18,),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: TextField(
                            onChanged: (val){
                              findPlaceAutoComplete(val);
                            },
                            decoration: const InputDecoration(
                              hintText: "Search...",
                              fillColor: Colors.white54,
                              filled: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(
                                left: 11.0,
                                top: 8.0,
                                bottom: 8.0
                              )

                            ),
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          //Display list of results
          (placesPredictedList.length > 0)
              ?
          Expanded(
            child: ListView.separated(
              itemCount: placesPredictedList.length,
              physics: ClampingScrollPhysics(),
              itemBuilder: (context, index)
              {
                return PlacePredictionTileDesign(
                  predictedPlaces: placesPredictedList[index],
                );
              },
              separatorBuilder: (BuildContext context, int index)
              {
                return const Divider(
                  height: 1,
                  color: Colors.white,
                  thickness: 1,
                );
              },
            ),
          )
          /*
          Expanded(
              child: ListView.separated(

                physics: ClampingScrollPhysics(),
                  itemBuilder: (context, index){
                  return PlacePredictionTileDesign(predictedPlaces: placesPredictedList[index]);
                  },
                  separatorBuilder: (BuildContext context, int index){
                  return const Divider(
                    height: 1,
                    color: Colors.grey,
                    thickness: 1,
                  );
              }, itemCount: placesPredictedList.length))

           */
              : Container()
        ],
      ),
    );
  }
}
