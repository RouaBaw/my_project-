import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '../models/course_model.dart';

class CoursesController extends GetxController {
  var courses = <Course>[].obs;
  var isLoading = false.obs;

  // الرابط الأساسي للـ API
  final String baseUrl = 'http://127.0.0.1:8000/api';

  Future<bool> saveCourseToApi({
    required int pathId,
    required String name,
    required String description,
    required List<Question> questions,
  }) async {
    try {
      isLoading(true);
      final token = GetStorage().read('token');

      // تجهيز البيانات لتطابق دالة saveQuestionsAndAnswers في Laravel
      final Map<String, dynamic> requestBody = {
        'learning_path_id': pathId,
        'course_name': name,
        'title': name,
        'description': description,
        'content_type': 'quiz',
        'order': 1,
        'questions': questions.map((q) {
          return {
            'question_text': q.questionText, // هذا هو المفتاح الذي يبحث عنه Laravel
            'type': q.type,
            'answers': q.type == 'multiple'
                ? q.options?.asMap().entries.map((entry) {
              return {
                'answer_text': entry.value, // المفتاح في موديل الأجوبة
                'is_correct': entry.key == q.correctOptionIndex ? 1 : 0
              };
            }).toList()
                : [
              {
                'answer_text': 'صح',
                'is_correct': q.correctAnswer == true ? 1 : 0
              },
              {
                'answer_text': 'خطأ',
                'is_correct': q.correctAnswer == false ? 1 : 0
              },
            ]
          };
        }).toList(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/learning-contents'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("Server Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Connection Error: $e");
      return false;
    } finally {
      isLoading(false);
    }
  }

  void addCourseLocal(Course course) => courses.add(course);
}