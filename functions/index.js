"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");

var serviceAccount = require("./serviceAccount.json");

admin.initializeApp();
  

exports.createTrip = functions.firestore
    .document("/trip_requests/{tripId}")
    .onCreate(
       async (snapshot) => {
        console.log("this is the document id: ", snapshot.id);
        
        console.log(snapshot.ref.path.segments);
        
        if (snapshot.exists) {
          console.log(`Data: ${JSON.stringify(snapshot.data())}`);
        }

      return;
    });