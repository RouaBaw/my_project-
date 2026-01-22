import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart'; // ستحتاج لإضافة حزمة intl في pubspec.yaml
import '../models/dashboard_model.dart';
import '../models/path_model.dart';

class DashboardController extends GetxController {
  var isLoading = false.obs;
  final String baseUrl = 'http://127.0.0.1:8000';

  // الحالة الابتدائية فارغة وسيتم تحديثها من السيرفر
  var dashboardData = DashboardData(
    totalPaths: 0,
    activePaths: 0,
    weeklyStats: [],
    recentPaths: [],
  ).obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardStats();
  }

  Future<void> fetchDashboardStats() async {
    try {
      isLoading(true);
      final token = GetStorage().read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/get-my-paths'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> rawData = jsonResponse['data'];

        // 1. معالجة المسارات الأخيرة وتحويلها للموديل
        List<LearningPath> fetchedPaths = rawData.map((path) => LearningPath(
          id: path['id'],
          name: path['title'],
          status: path['status'], // سيكون غالباً pending بناءً على بياناتك
          imageUrl: '$baseUrl/${path['photo']}', // دمج رابط السيرفر مع المسار
          category: 'عام',
          studentCount: path['dynamic_number_of_courses'], // استخدام هذا الحقل كمؤشر مؤقت
          createdAt: DateTime.parse(path['created_at']),
          description: path['description'],
        )).toList();

        // 2. حساب الإحصائيات العامة
        int total = fetchedPaths.length;
        int active = fetchedPaths.where((p) => p.status == 'active').length;

        // 3. توليد بيانات الرسم البياني (Weekly Stats) بناءً على تاريخ الإنشاء
        List<WeeklyStats> weekly = _generateWeeklyStats(fetchedPaths);

        // 4. تحديث الواجهة
        dashboardData.value = DashboardData(
          totalPaths: total,
          activePaths: active,
          weeklyStats: weekly,
          recentPaths: fetchedPaths.take(5).toList(), // عرض آخر 5 مسارات
        );
      }
    } catch (e) {
      print("Error fetching dashboard: $e");
    } finally {
      isLoading(false);
    }
  }

  // دالة ذكية لتوزيع المسارات على أيام الأسبوع
  List<WeeklyStats> _generateWeeklyStats(List<LearningPath> paths) {
    Map<String, int> daysMap = {
      'السبت': 0, 'الأحد': 0, 'الإثنين': 0, 'الثلاثاء': 0,
      'الأربعاء': 0, 'الخميس': 0, 'الجمعة': 0
    };

    for (var path in paths) {
      // الحصول على اسم اليوم باللغة العربية
      String dayName = DateFormat('EEEE', 'ar').format(path.createdAt);
      if (daysMap.containsKey(dayName)) {
        daysMap[dayName] = daysMap[dayName]! + 1;
      }
    }

    return daysMap.entries.map((e) => WeeklyStats(day: e.key, courses: e.value)).toList();
  }
}