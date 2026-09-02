import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserService {
  static const _userKey = 'user';
  static const _tokenKey = 'accessToken';

  Future<User> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception('Invalid username or password');
    }

    return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_tokenKey, user.accessToken);
  }

  Future<User?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedUser = prefs.getString(_userKey);
    if (encodedUser == null || encodedUser.isEmpty) return null;

    try {
      return User.fromJson(jsonDecode(encodedUser) as Map<String, dynamic>);
    } on FormatException {
      await logout();
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_tokenKey) ?? '').isNotEmpty &&
        (prefs.getString(_userKey) ?? '').isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }
}
