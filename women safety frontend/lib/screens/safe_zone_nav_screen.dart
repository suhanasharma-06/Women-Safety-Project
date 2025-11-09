import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class SafeZoneNavScreen extends StatefulWidget {
  const SafeZoneNavScreen({super.key});

  @override
  State<SafeZoneNavScreen> createState() => _SafeZoneNavScreenState();
}

class _SafeZoneNavScreenState extends State<SafeZoneNavScreen> {
  GoogleMapController? mapController;
  LatLng? currentLocation;
  Set<Marker> markers = {};
  Set<Polyline> routeLines = {};
  bool loading = true;

  final String googleApiKey = "YOUR_GOOGLE_API_KEY_HERE";

  @override
  void initState() {
    super.initState();
    _loadLocationAndPlaces();
  }

  Future<void> _loadLocationAndPlaces() async {
    // Ask for location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    currentLocation = LatLng(position.latitude, position.longitude);

    // Add your current location marker
    markers.add(Marker(
      markerId: const MarkerId("current_location"),
      position: currentLocation!,
      infoWindow: const InfoWindow(title: "You are here"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    ));

    // Fetch nearby safe zones (police, hospitals, public places)
    await _fetchNearbyPlaces();

    setState(() => loading = false);
  }

  Future<void> _fetchNearbyPlaces() async {
    final types = ["police", "hospital", "park"];
    for (String type in types) {
      final url =
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${currentLocation!.latitude},${currentLocation!.longitude}&radius=3000&type=$type&key=$googleApiKey";

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data["results"] != null) {
        for (var place in data["results"]) {
          final lat = place["geometry"]["location"]["lat"];
          final lng = place["geometry"]["location"]["lng"];
          final name = place["name"];

          markers.add(Marker(
            markerId: MarkerId(name),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              type == "hospital"
                  ? BitmapDescriptor.hueRed
                  : (type == "police"
                      ? BitmapDescriptor.hueBlue
                      : BitmapDescriptor.hueGreen),
            ),
            onTap: () {
              _drawRoute(LatLng(lat, lng));
            },
          ));
        }
      }
    }
    setState(() {});
  }

  Future<void> _drawRoute(LatLng destination) async {
    if (currentLocation == null) return;

    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${currentLocation!.latitude},${currentLocation!.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleApiKey";

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data["routes"].isNotEmpty) {
      final points = _decodePolyline(
          data["routes"][0]["overview_polyline"]["points"]);

      setState(() {
        routeLines.clear();
        routeLines.add(Polyline(
          polylineId: const PolylineId("route"),
          color: Colors.pink,
          width: 6,
          points: points,
        ));
      });

      mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsFromPoints(points), 100),
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  LatLngBounds _boundsFromPoints(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Safe Zones & Navigation"),
        backgroundColor: Colors.pink,
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentLocation!,
                zoom: 14,
              ),
              onMapCreated: (controller) {
                mapController = controller;
              },
              markers: markers,
              polylines: routeLines,
              myLocationEnabled: true,
              zoomControlsEnabled: true,
            ),
    );
  }
}