import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsService {
  static const String _keyProtocol = 'server_protocol';
  static const String _keyHost = 'server_host';
  static const String _keyPort = 'server_port';

  // 默认值
  static const String defaultProtocol = 'http';
  static const String defaultHost = '192.168.1.1';
  static const String defaultPort = '5000';

  /// 获取协议 (http 或 https)
  static Future<String> getProtocol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProtocol) ?? defaultProtocol;
  }

  /// 获取主机地址
  static Future<String> getHost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHost) ?? defaultHost;
  }

  /// 获取端口号
  static Future<String> getPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPort) ?? defaultPort;
  }

  /// 保存服务器配置
  static Future<void> saveSettings({
    required String protocol,
    required String host,
    required String port,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProtocol, protocol);
    await prefs.setString(_keyHost, host);
    await prefs.setString(_keyPort, port);
  }

  /// 检查是否已配置服务器设置
  static Future<bool> hasSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyProtocol) &&
        prefs.containsKey(_keyHost) &&
        prefs.containsKey(_keyPort);
  }

  /// 获取完整的 API Base URL
  static Future<String> getBaseUrl() async {
    final protocol = await getProtocol();
    final host = await getHost();
    final port = await getPort();
    return '$protocol://$host:$port';
  }

  /// 测试服务器连接
  /// 返回 (成功, 错误消息)
  static Future<(bool, String)> testConnection({
    required String protocol,
    required String host,
    required String port,
  }) async {
    final baseUrl = '$protocol://$host:$port';

    try {

      // 尝试访问 /api/list 端点
      final uri = Uri.parse('$baseUrl/api/list');

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // 尝试解析 JSON 以确保是有效的 API 响应
        try {
          json.decode(utf8.decode(response.bodyBytes));
          return (true, '连接成功！');
        } catch (e) {
          return (false, '服务器响应格式错误');
        }
      } else {
        return (false, '服务器返回错误: ${response.statusCode}');
      }
    } catch (e) {
      String errorMsg = '连接失败';

      if (e.toString().contains('SocketException')) {
        errorMsg = '无法连接到服务器，请检查IP地址和端口';
      } else if (e.toString().contains('TimeoutException')) {
        errorMsg = '连接超时，请检查网络';
      } else if (e.toString().contains('FormatException')) {
        errorMsg = '地址格式错误';
      }

      return (false, errorMsg);
    }
  }

  /// 清除所有设置（用于测试）
  static Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProtocol);
    await prefs.remove(_keyHost);
    await prefs.remove(_keyPort);
  }
}
