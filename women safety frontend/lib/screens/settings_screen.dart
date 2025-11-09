import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool voiceCommand = true;
  bool autoRecord = false;
  bool liveTracking = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SwitchListTile(
              title: Text("Voice Command SOS"),
              value: voiceCommand,
              onChanged: (v) => setState(() => voiceCommand = v),
            ),
            SwitchListTile(
              title: Text("Auto Recording"),
              value: autoRecord,
              onChanged: (v) => setState(() => autoRecord = v),
            ),
            SwitchListTile(
              title: Text("Live Tracking"),
              value: liveTracking,
              onChanged: (v) => setState(() => liveTracking = v),
            ),
            SizedBox(height: 20),
            Text("More advanced controls coming soon...",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
