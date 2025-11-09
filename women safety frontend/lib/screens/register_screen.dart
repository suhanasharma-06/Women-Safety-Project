import 'package:flutter/material.dart';
import '../api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _phone = TextEditingController();
  bool loading = false;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isDarkMode = prefs.getBool("darkMode") ?? false);
  }

  Future<void> _register() async {
    if (_name.text.isEmpty ||
        _email.text.isEmpty ||
        _pass.text.isEmpty ||
        _phone.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final res = await ApiService.register(
        _name.text.trim(),
        _email.text.trim(),
        _pass.text.trim(),
        _phone.text.trim(),
      );

      if (res['token'] != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? "Registration failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("SafeTrack"),
        centerTitle: true,
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _name,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Full Name",
                labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.pink.shade300),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.pink, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.pink.shade300),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.pink, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pass,
              obscureText: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.pink.shade300),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.pink, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phone,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: "Phone",
                labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.pink.shade300),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.pink, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Register"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text(
                "Already have an account? Login",
                style: TextStyle(color: Colors.pink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
