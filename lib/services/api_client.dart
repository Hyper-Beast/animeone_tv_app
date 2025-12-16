import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _baseUrl = 'http://192.168.1.1:5000';

  static String get baseUrl => _baseUrl;

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('$_baseUrl$endpoint');

      // 添加查询参数
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        return responseData as Map<String, dynamic>;
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
