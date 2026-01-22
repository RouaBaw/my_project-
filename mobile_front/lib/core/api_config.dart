import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _ipKey = 'server_ip';
  static const String _portKey = 'server_port';

  // حفظ الإعدادات
  static Future<void> setConnection(String ip, String port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, ip);
    await prefs.setString(_portKey, port);
  }

  // بناء الرابط الأساسي
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String ip = prefs.getString(_ipKey) ?? '127.0.0.1'; // قيمة افتراضية
    String port = prefs.getString(_portKey) ?? '8000';
    return 'http://$ip:$port/api';
  }
}