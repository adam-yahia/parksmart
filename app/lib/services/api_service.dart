import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/parking_spot.dart';

class ApiService {
  static const String baseUrl = 'http://172.20.10.7:5000';

  static Future<String> login(String username, String password) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 8));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data['access_token'] as String;
    }
    throw Exception(data['error'] ?? 'Login failed');
  }

  static Future<List<ParkingSpot>> getSpots() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/spots'))
        .timeout(const Duration(seconds: 6));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((j) => ParkingSpot.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load spots');
  }
}
