import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class SafeZoneScreen extends StatefulWidget {
  const SafeZoneScreen({super.key});

  @override
  State<SafeZoneScreen> createState() => _SafeZoneScreenState();
}

class _SafeZoneScreenState extends State<SafeZoneScreen> {
  LatLng? userPos;
  List<Map<String, dynamic>> safeZones = [];
  List<LatLng> routePoints = [];
  bool loading = true;
  bool navigating = false;

  final String googleApiKey = "AIzaSyCt8jw_uRbRfr9_8CBRdauiHY8rWCjV6WU"; // Replace this

  @override
  void initState() {
    super.initState();
    loadLocation();
  }

  Future<void> loadLocation() async {
    await Geolocator.requestPermission();
    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      userPos = LatLng(pos.latitude, pos.longitude);
    });
    await fetchNearbySafeZones();
  }

  Future<void> fetchNearbySafeZones() async {
    if (userPos == null) return;

    final types = ["police", "hospital", "park"];
    List<Map<String, dynamic>> allPlaces = [];

    for (var type in types) {
      final url =
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${userPos!.latitude},${userPos!.longitude}&radius=4000&type=$type&key=$googleApiKey";

      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["results"] != null && data["results"].isNotEmpty) {
        for (var place in data["results"]) {
          allPlaces.add({
            "name": place["name"],
            "lat": place["geometry"]["location"]["lat"],
            "lng": place["geometry"]["location"]["lng"],
            "type": type
          });
        }
      }
    }

    setState(() {
      safeZones = allPlaces;
      loading = false;
    });
  }

  Future<void> getDirections(LatLng destination) async {
    setState(() {
      navigating = true;
      routePoints.clear();
    });

    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${userPos!.latitude},${userPos!.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleApiKey";

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    if (data["routes"].isNotEmpty) {
      final points = data["routes"][0]["overview_polyline"]["points"];
      routePoints = decodePolyline(points);
    }

    setState(() => navigating = false);
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Safe Zones"), backgroundColor: Colors.pink),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(initialCenter: userPos!, initialZoom: 14),
              children: [
                TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),
                MarkerLayer(markers: [
                  // 🧍 Your location
                  Marker(
                    point: userPos!,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                  // 🏥 Police, Hospitals, Parks
                  ...safeZones.map((zone) {
                    IconData icon;
                    Color color;

                    switch (zone["type"]) {
                      case "police":
                        icon = Icons.local_police;
                        color = Colors.blue;
                        break;
                      case "hospital":
                        icon = Icons.local_hospital;
                        color = Colors.red;
                        break;
                      default:
                        icon = Icons.park;
                        color = Colors.green;
                    }

                    return Marker(
                      point: LatLng(zone["lat"], zone["lng"]),
                      width: 80,
                      height: 80,
                      child: GestureDetector(
                        onTap: () => getDirections(LatLng(zone["lat"], zone["lng"])),
                        child: Column(
                          children: [
                            Icon(icon, color: color, size: 35),
                            Text(
                              zone["name"],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ]),
                // 🚗 Draw route if available
                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 5.0,
                        color: Colors.pinkAccent,
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}