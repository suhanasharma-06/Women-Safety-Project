import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/contact.dart';

// Base URL of deployed backend
class ApiService {
  static const String baseUrl = "https://women-safety-project.onrender.com/api";

  static Map<String, String> authHeader(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ------------------ LOGIN ------------------
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  // ------------------ REGISTER ------------------
  static Future<Map<String, dynamic>> register(
      String name, String email, String pass, String phone) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': pass,
        'phone': phone
      }),
    );
    return jsonDecode(res.body);
  }

  // ------------------ CONTACTS ------------------
  static Future<List<Contact>> getContacts(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/contacts"),
      headers: authHeader(token),
    );

    if (res.statusCode == 200) {
      List data = jsonDecode(res.body);
      return data.map((e) => Contact.fromJson(e)).toList();
    }

    throw Exception("Failed to fetch contacts");
  }

  static Future<Contact> addContact(
      String token, String name, String phone, String relation) async {
    final res = await http.post(
      Uri.parse("$baseUrl/contacts"),
      headers: authHeader(token),
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'relation': relation
      }),
    );

    return Contact.fromJson(jsonDecode(res.body));
  }

  static Future<void> deleteContact(String token, String id) async {
    await http.delete(
      Uri.parse("$baseUrl/contacts/$id"),
      headers: authHeader(token),
    );
  }

  // ------------------ ALERTS ------------------
  static Future<Map<String, dynamic>> sendAlert(
    String token, {
    double? latitude,
    double? longitude,
    String? message,
    List<String>? contactIds,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/alerts"),
      headers: authHeader(token),
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'message': message,
        'contactIds': contactIds
      }),
    );

    return jsonDecode(res.body);
  }
}
