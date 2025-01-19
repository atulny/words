import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  bool get isAuthenticated => _token != null;
  static const String baseUrl = 'http://localhost:8080'; // Use this for iOS simulator

  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['access_token'];
      print('token $_token');
      await _saveToken();
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    return response.statusCode == 201;
  }

  Future<void> logout() async {
    _token = null;
    await _removeToken();
    notifyListeners();
  }

  Future<void> _saveToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    notifyListeners();
  }

  String? get token => _token;
}


