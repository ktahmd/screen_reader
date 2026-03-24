import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiClient {
  static Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      return response;
    } catch (e) {
      debugPrint("API GET Error [$url]: $e");
      rethrow;
    }
  }

  static Future<http.Response> post(String url, {Map<String, String>? headers, required Map<String, dynamic> body}) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', ...?headers},
        body: json.encode(body),
      );
      return response;
    } catch (e) {
      debugPrint("API POST Error [$url]: $e");
      rethrow;
    }
  }
}