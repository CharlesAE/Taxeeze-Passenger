
import 'package:flutter/material.dart';

import '../global/global.dart';
import '../screens/splash_screen.dart';
class MyDrawer extends StatefulWidget
{
  String? name;
  String? email;

  MyDrawer({this.name, this.email});

  @override
  _MyDrawerState createState() => _MyDrawerState();
}



class _MyDrawerState extends State<MyDrawer>
{
  @override
  Widget build(BuildContext context)
  {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          //drawer header
          Container(
            height: 160,
            color: Colors.grey,
            child: DrawerHeader(
              decoration: const BoxDecoration(color: Colors.black),
              child: Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey,
                  ),

                  const SizedBox(width: 15,),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.name.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10,),
                      Text(
                        widget.email.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1.0, color: Color(0xFFe2e2e2), thickness: 1.0,),
          const SizedBox(height: 10.0,),

          //drawer body
          GestureDetector(
            onTap: ()
            {

            },
            child: const ListTile(
              leading: Icon(Icons.history, color: Colors.white54,),
              title: Text(
                "Ride History",
                style: TextStyle(
                    color: Colors.white54
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: ()
            {

            },
            child: const ListTile(
              leading: Icon(Icons.person, color: Colors.white54,),
              title: Text(
                "Visit Profile",
                style: TextStyle(
                    color: Colors.white54
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: ()
            {

            },
            child: const ListTile(
              leading: Icon(Icons.info, color: Colors.white54,),
              title: Text(
                "About",
                style: TextStyle(
                    color: Colors.white54
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: ()
            {
              fAuth.signOut();
              Navigator.push(context, MaterialPageRoute(builder: (c)=> const MySplashScreen()));
            },
            child: const ListTile(
              leading: Icon(Icons.logout, color: Colors.white54,),
              title: Text(
                "Sign Out",
                style: TextStyle(
                    color: Colors.white54
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}
