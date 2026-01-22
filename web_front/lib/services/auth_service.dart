import 'package:get_storage/get_storage.dart';

class AuthService {
  static final _box = GetStorage();

  // حفظ البيانات عند تسجيل الدخول
  static void saveUserData(Map<String, dynamic> userData, String token) {
    _box.write('user', userData);
    _box.write('token', token);
  }

  // استرجاع التوكن لاستخدامه في الطلبات اللاحقة
  static String? getToken() => _box.read('token');

  // استرجاع بيانات المستخدم
  static Map<String, dynamic>? getUser() => _box.read('user');

  // مسح البيانات عند تسجيل الخروج
  static void logout() {
    _box.erase();
  }
}