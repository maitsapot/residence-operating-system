import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = "http://20.164.20.15:8000/api/v1";

class ApiService {
  static Future<List> getResidences() async {
    final res = await http.get(Uri.parse("$baseUrl/residences/"));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load residences");
    }
  }

  static Future<List> getTenants(String residenceId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/tenants/by-residence/$residenceId"),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load tenants");
    }
  }

  static Future<Map> getUser(String userId) async {
    final res = await http.get(Uri.parse("$baseUrl/users/$userId"));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load user");
    }
  }

  static Future<List> getIssues() async {
    final res = await http.get(Uri.parse("$baseUrl/issues?limit=100"));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load issues");
    }
  }
}
