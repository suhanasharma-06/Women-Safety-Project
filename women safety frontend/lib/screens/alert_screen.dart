import 'package:flutter/material.dart';
import '../api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertScreen extends StatefulWidget {
  @override
  _AlertScreenState createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  final msg = TextEditingController();
  bool sending = false;

  sendAlert() async {
    setState(() => sending = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    await Geolocator.requestPermission();
    final p = await Geolocator.getCurrentPosition();

    final res = await ApiService.sendAlert(token!,
        latitude: p.latitude, longitude: p.longitude, message: msg.text);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Alert sent")));
    Navigator.pop(context);
  }

  @override
  Widget build(context) {
    return Scaffold(
        appBar: AppBar(title: Text("Emergency Alert"), backgroundColor: Colors.red),
        body: Padding(
            padding: EdgeInsets.all(16),
            child: Column(children: [
              TextField(controller: msg, decoration: InputDecoration(labelText: "Message (optional)")),
              SizedBox(height: 16),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: sending ? null : sendAlert,
                  child: sending ? CircularProgressIndicator(color: Colors.white) : Text("SEND ALERT"))
            ])));
  }
}
