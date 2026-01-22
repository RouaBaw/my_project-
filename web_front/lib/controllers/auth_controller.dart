import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:web_front1/pages/admin_dashboard_page.dart';
import 'package:web_front1/content_creator/pages/home_page.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  final box = GetStorage();

  Future<void> login(String email, String password) async {
    try {
      isLoading(true);

      final url = Uri.parse('http://127.0.0.1:8000/api/login');
      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
        body: {'email': email, 'password': password},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        String token = data['token'];
        var user = data['user'];
        String userType = user['user_type'];

        // حفظ البيانات في المتصفح
        await box.write('token', token);
        await box.write('user_type', userType);
        await box.write('user_data', json.encode(user));

        // منطق التوجيه حسب الطلب
        if (userType == 'system_administrator' || userType == 'content_auditor') {
          Get.offAll(() => AdminDashboardPage());
        } else if (userType == 'content_creator') {
          Get.offAll(() => HomePage());
        }

        Get.snackbar('نجاح', 'أهلاً بك مجدداً', snackPosition: SnackPosition.TOP);
      } else {
        Get.snackbar('خطأ', data['message'] ?? 'بيانات الدخول غير صحيحة');
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل الاتصال بالسيرفر');
    } finally {
      isLoading(false);
    }
  }

  void logout() async {
    await box.erase();
    Get.offAllNamed('/'); // التوجه لصفحة البداية
  }
}