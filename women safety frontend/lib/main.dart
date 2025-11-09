import 'package:flutter/material.dart';
import 'package:women_safety_app/screens/login_screen.dart';
import 'package:women_safety_app/screens/home_screen.dart';
import 'package:women_safety_app/screens/contacts_screen.dart';
import 'package:women_safety_app/screens/fake_call_screen.dart';
import 'package:women_safety_app/screens/safezone_screen.dart';

void main() {
  runApp(SafeTrackApp());
}

class SafeTrackApp extends StatelessWidget {
  const SafeTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SafeTrack",
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),

      home: LoginScreen(),

      routes: {
        "/login": (_) => LoginScreen(),
        "/home": (_) => HomeScreen(),
        "/contacts": (_) => ContactsScreen(),
        "/fake": (_) => FakeCallScreen(),
        "/safe": (_) => SafeZoneScreen(),
        

      },
    );
  }
}
