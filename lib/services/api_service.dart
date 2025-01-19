import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // static const String baseUrl = 'http://10.0.2.2:8000'; // Use this for Android emulator
  static const String baseUrl = 'http://localhost:8080'; // Use this for iOS simulator

  static Future<String> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return 'Registration successful';
    } else {
      throw Exception('Failed to register X ${response.reasonPhrase}  ${response.statusCode}' );
    }
  }

  static Future<String> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final token = jsonDecode(response.body)['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      return token;
    } else {
      throw Exception('Failed to login');
    }
  }

  static Future<List<dynamic>> getWords() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/words'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load words');
    }
  }

  static Future<void> addWord(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/words'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': word}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add word');
    }
  }
}

