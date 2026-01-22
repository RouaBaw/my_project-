import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '../models/path_model.dart';

class PathsController extends GetxController {
  // قائمة المسارات التي سيتم عرضها في الواجهة
  var learningPaths = <LearningPath>[].obs;
  // حالة التحميل لإظهار مؤشر انتظار (Loading)
  var isLoading = false.obs;

  final box = GetStorage();
  final String baseUrl = 'http://127.0.0.1:8000/api';

  @override
  void onInit() {
    super.onInit();
    // جلب البيانات من السيرفر فور تشغيل الـ Controller
    fetchPaths();
  }

  // دالة لجلب جميع المسارات من الباك إيند
  Future<void> fetchPaths() async {
    try {
      isLoading(true);
      String? token = box.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/get-my-paths'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        // تحويل البيانات القادمة من JSON إلى قائمة من كائنات LearningPath
        learningPaths.assignAll(
            jsonResponse.map((data) => LearningPath.fromJson(data)).toList()
        );
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في جلب المسارات: $e');
    } finally {
      isLoading(false);
    }
  }

  // الدالة التي طلبتها لإرسال المسار الجديد وحفظه
  Future<int?> uploadPath({
    required String title,
    required String description,
    // في الويب نستخدم bytes بدلاً من path للصورة
    dynamic imageFile,
    String? fileName,
  }) async {
    try {
      isLoading(true);
      String? token = box.read('token');

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/educational-paths'));

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // إضافة الحقول النصية (تأكد أنها تطابق أسماء الـ Request في Laravel)
      request.fields['title'] = title;
      request.fields['description'] = description;

      // إضافة الصورة إذا وجدت (دعم الويب والموبايل)
      if (imageFile != null) {
        if (imageFile is String) {
          // للموبايل
          request.files.add(await http.MultipartFile.fromPath('photo', imageFile));
        } else {
          // للويب (bytes)
          request.files.add(http.MultipartFile.fromBytes('photo', imageFile, filename: fileName));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        var data = json.decode(response.body);

        // جلب البيانات المحدثة لتظهر في القائمة فوراً
        fetchPaths();

        // إرجاع الـ ID الجديد الذي تم إنشاؤه في قاعدة البيانات
        return data['data']['id'];
      } else {
        Get.snackbar('خطأ', 'فشل الحفظ: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء الاتصال: $e');
      return null;
    } finally {
      isLoading(false);
    }
  }

  LearningPath? getPathById(int pathId) {
    return learningPaths.firstWhereOrNull((path) => path.id == pathId);
  }
}