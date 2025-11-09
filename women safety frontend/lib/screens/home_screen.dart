import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:women_safety_app/api_service.dart';
import 'package:women_safety_app/models/contact.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import 'contacts_screen.dart';
import 'fake_call_screen.dart';
import 'safezone_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Contact> contacts = [];
  bool loading = false;
  String? token;
  bool isOffline = false;
  bool isDarkMode = false;
  StreamSubscription<Position>? liveStream;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadContacts();
    _checkInternetStatus();
  }

  @override
  void dispose() {
    liveStream?.cancel();
    super.dispose();
  }

  // 🌙 Load and toggle dark mode
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isDarkMode = prefs.getBool("darkMode") ?? false);
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("darkMode", value);
    setState(() => isDarkMode = value);
  }

  // 🌐 Check Internet status
  Future<void> _checkInternetStatus() async {
    final result = await Connectivity().checkConnectivity();
    setState(() => isOffline = result == ConnectivityResult.none);
  }

  // 📞 Load saved emergency contacts
  Future<void> _loadContacts() async {
    setState(() => loading = true);
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");

    if (token != null) {
      try {
        contacts = await ApiService.getContacts(token!);
      } catch (e) {
        debugPrint("Error loading contacts: $e");
      }
    }

    setState(() => loading = false);
  }

  // 🌍 Get accurate GPS location
  Future<Position> _getAccurateLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied.");
    }

    // 🔥 Request a precise GPS fix
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    // Optional: wait a few seconds to let GPS stabilize
    await Future.delayed(const Duration(seconds: 2));

    return position;
  }

  // 🚨 SOS ALERT (Improved Accuracy)
  Future<void> _sendAlert() async {
    await _checkInternetStatus();

    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ No internet connection. SOS not sent.")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("📡 Getting precise location...")),
    );

    try {
      Position position = await _getAccurateLocation();
      double lat = position.latitude;
      double lon = position.longitude;

      String sosMessage =
          "🚨 SOS ALERT from SafeTrack! I need help.\nMy location: https://www.google.com/maps?q=$lat,$lon";

      if (token != null) {
        await ApiService.sendAlert(
          token!,
          latitude: lat,
          longitude: lon,
          message: sosMessage,
          contactIds: contacts.map((c) => c.id).toList(),
        );

        debugPrint("✅ SOS alert sent successfully to server");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚨 SOS sent successfully!")),
        );
      }
    } catch (e) {
      debugPrint("⚠ Error sending SOS: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to send SOS: $e")),
      );
    }
  }

  // ⚙ Settings Modal
  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 200,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text("Dark Mode"),
              value: isDarkMode,
              onChanged: (val) {
                _toggleTheme(val);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove("token");
                if (mounted) {
                  Navigator.pushReplacementNamed(context, "/login");
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🧭 UI
  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("SafeTrack"),
        centerTitle: true,
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _sendAlert,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade200,
                      blurRadius: 25,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "SOS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.group),
                  label: const Text("Contacts"),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactsScreen()),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.phone),
                  label: const Text("Fake Call"),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FakeCallScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text("Safe Zones"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SafeZoneScreen()),
              ),
            ),
            const SizedBox(height: 20),
            if (isOffline)
              Text(
                "⚠ Offline Mode: Internet not available",
                style: TextStyle(color: Colors.red.shade400, fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
