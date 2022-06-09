import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taxeeze_passenger/helpers/auth_methods.dart';

import '../authentication/login_screen.dart';
import '../global/global.dart';
import 'main_screen.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  final AuthMethods _authMethods = AuthMethods();
  //Timer for splash screen
  startTimer() {


    Timer(const Duration(seconds: 3), () async {
      currentUser = await _authMethods.getUserDetails();
      //Send user  to main screen
      if(await fAuth.currentUser != null)
      {
        print(currentUser?.name);
        currentFirebaseUser = fAuth.currentUser;
        Navigator.push(context, MaterialPageRoute(builder: (c)=> MainScreen()));
      }
      else
      {
        Navigator.push(context, MaterialPageRoute(builder: (c)=> LoginScreen()));
      }

    });
  }

  //Called
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    startTimer();
  }

  @override
  Widget build(BuildContext context)
  {
    return Material(
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/logo.jpg"),
              const SizedBox(height: 10,),
              const Text(
                "Taxeeze",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
