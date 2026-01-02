import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/creator_application_model.dart';
import '../services/auth_service.dart'; // 1. استيراد خدمة التخزين

class AdminController extends GetxController {
  var applications = <CreatorApplication>[].obs;
  var isLoading = false.obs;
  var selectedApplication = Rxn<CreatorApplication>();

  final String baseUrl = "http://127.0.0.1:8000/api";

  // 2. دالة مساعدة للحصول على التوكن المحفوظ
  String? get _savedToken => AuthService.getToken();

  @override
  void onInit() {
    super.onInit();
    fetchApplications();
  }

  void approveApplication(int applicationId) {
    updateApplicationStatus(applicationId, 'accepted');
  }

  void rejectApplication(int applicationId) {
    updateApplicationStatus(applicationId, 'rejected');
  }

  // دالة جلب البيانات من الباك إيند
  Future<void> fetchApplications() async {
    // 3. التحقق من وجود توكن قبل الإرسال
    if (_savedToken == null) {
      Get.snackbar('خطأ', 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى');
      return;
    }

    try {
      isLoading(true);
      final response = await http.get(
        Uri.parse('$baseUrl/users/creators'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_savedToken', // 4. استخدام التوكن الديناميكي
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        applications.assignAll(data.map((json) => CreatorApplication.fromMap(json)).toList());
      } else {
        Get.snackbar('خطأ', 'فشل في جلب البيانات: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تأكد من اتصالك بالإنترنت');
    } finally {
      isLoading(false);
    }
  }

  // دالة تحديث الحالة (قبول أو رفض) في السيرفر
  // دالة تحديث الحالة (قبول أو رفض) في السيرفر
  Future<void> updateApplicationStatus(int applicationId, String newStatus) async {
    if (_savedToken == null) return;

    try {
      isLoading(true);
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$applicationId/update-status'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_savedToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        // --- التعديل هنا ---
        // بدلاً من تحديث القائمة محلياً فقط، نقوم بإعادة جلب البيانات من السيرفر
        // لضمان مزامنة البيانات بنسبة 100%
        await fetchApplications();
        // -------------------

        Get.back(); // إغلاق صفحة التفاصيل أو الحوار

        Get.snackbar(
          newStatus == 'accepted' ? 'تم القبول' : 'تم الرفض',
          newStatus == 'accepted' ? 'تم تفعيل حساب صانع المحتوى' : 'تم رفض وإلغاء تفعيل الحساب',
          backgroundColor: newStatus == 'accepted' ? Colors.green[50] : Colors.red[50],
          colorText: newStatus == 'accepted' ? Colors.green : Colors.red,
        );
      } else {
        Get.snackbar('خطأ', 'حدث خطأ أثناء تحديث الحالة في السيرفر');
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل الاتصال بالسيرفر');
    } finally {
      isLoading(false);
    }
  }
  void viewApplicationDetails(CreatorApplication application) {
    selectedApplication.value = application;
  }
}

extension CreatorApplicationCopyWith on CreatorApplication {
  CreatorApplication copyWith({String? status}) {
    return CreatorApplication(
      id: id,
      nationalId: nationalId,
      firstName: firstName,
      lastName: lastName,
      fatherName: fatherName,
      motherName: motherName,
      age: age,
      educationLevel: educationLevel,
      email: email,
      phone: phone,
      imageUrl: imageUrl,
      status: status ?? this.status,
      appliedAt: appliedAt,
    );
  }
}