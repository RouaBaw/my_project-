import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class CourseController extends GetxController {
  // حالة التحميل
  var isLoading = false.obs;

  // بيانات المسار التعليمي (العنوان، الوصف، الصورة)
  var pathData = {}.obs;

  // قائمة المحتويات (الدروس/الكورسات)
  var contents = <Map<String, dynamic>>[].obs;

  // الرابط الأساسي للسيرفر (تأكد من تغييره لعنوان IP جهازك إذا كنت تستخدم محاكي)
  final String baseUrl = 'http://127.0.0.1:8000/api';

  @override
  void onInit() {
    super.onInit();
    // يمكنك استدعاء دالة التحميل الأولية هنا إذا كان هناك ID ثابت
  }


  // أضف هذه الدالة داخل كلاس CourseController
  Future<bool> addVideoPackage({
    required int learningContentId,
    required String title,
    required String url,
    String? description,
  }) async {
    try {
      isLoading(true);
      final token = GetStorage().read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/content-packages'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'learning_content_id': learningContentId,
          'title': title,
          'url': url,
          'content': description,
        }),
      );

      if (response.statusCode == 201) {
        Get.snackbar('نجاح', 'تم إضافة الفيديو بنجاح',
            backgroundColor: Colors.green, colorText: Colors.white);
        return true;
      } else {
        Get.snackbar('خطأ', 'فشل الإرسال: ${response.body}');
        return false;
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر الاتصال بالسيرفر');
      return false;
    } finally {
      isLoading(false);
    }
  }
  /// 1. جلب كافة محتويات المسار التعليمي من السيرفر
  Future<void> loadPathContents(int pathId) async {
    try {
      isLoading(true);
      final token = GetStorage().read('token'); // جلب توكن المصادقة

      final response = await http.get(
        Uri.parse('$baseUrl/educational-paths/$pathId/all-contents'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          // تخزين بيانات المسار الرئيسي
          pathData.value = jsonResponse['data'];

          // تخزين قائمة المحتويات (Contents)
          var fetchedContents = jsonResponse['data']['contents'];
          contents.assignAll(List<Map<String, dynamic>>.from(fetchedContents));
        }
      } else {
        Get.snackbar('تنبيه', 'فشل في جلب البيانات من السيرفر: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in loadPathContents: $e");
      Get.snackbar('خطأ', 'تعذر الاتصال بالسيرفر، تأكد من اتصال الإنترنت');
    } finally {
      isLoading(false);
    }
  }

  /// 2. جلب الفيديوهات (Packages) الخاصة بمحتوى معين
  /// تستخدم هذه الدالة في صفحة الفيديوهات لعرض محتويات الـ packages
  /// التعديل: جلب الفيديوهات مباشرة من السيرفر في كل مرة يتم طلبها
  Future<List<dynamic>> getVideosForContent(int contentId) async {
    try {
      isLoading(true);
      final token = GetStorage().read('token');

      // تصحيح الرابط: حذف /api المكررة لأنها موجودة في
      final response = await http.get(
        Uri.parse('$baseUrl/courses_videos/$contentId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },

      );
print(response);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['data'] != null) {
          return jsonResponse['data']; // إرجاع القائمة مباشرة
        }
      }
      return [];
    } catch (e) {
      print("Error in getVideosForContent: $e");
      return [];
    } finally {
      isLoading(false);
    }
  }
  List<dynamic> getQuestionsForCourse(int pathId) {
    try {
      List<dynamic> allCourseQuestions = [];

      for (var content in contents) {
        if (content['questions'] != null) {
          allCourseQuestions.addAll(content['questions']);
        }
      }

      return allCourseQuestions;
    } catch (e) {
      print("Error in getQuestionsForCourse: $e");
      return [];
    }
  }
  /// 3. جلب الأسئلة (Questions) الخاصة بمحتوى معين
  List<dynamic> getQuestionsForContent(int contentId) {
    try {
      final content = contents.firstWhere(
            (element) => element['id'] == contentId,
        orElse: () => {},
      );

      return content['questions'] ?? [];
    } catch (e) {
      print("Error in getQuestionsForContent: $e");
      return [];
    }
  }

  /// 4. حساب إحصائيات المسار (إجمالي الفيديوهات في كل الـ contents)
  int calculateTotalVideosCount() {
    int total = 0;
    for (var item in contents) {
      final List packages = item['packages'] ?? [];
      total += packages.length;
    }
    return total;
  }
}