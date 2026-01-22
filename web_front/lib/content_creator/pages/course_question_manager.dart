import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CourseQuestionsManager extends StatefulWidget {
  final int learningContentId;
  final String contentTitle;

  const CourseQuestionsManager({
    super.key,
    required this.learningContentId,
    required this.contentTitle,
  });

  @override
  State<CourseQuestionsManager> createState() => _CourseQuestionsManagerState();
}

class _CourseQuestionsManagerState extends State<CourseQuestionsManager> {
  List<dynamic> questionsList = [];
  bool isLoading = true;

  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(3, (i) => TextEditingController());
  int _correctOptionIndex = 0;
  bool isSaving = false;

  // الرابط الأساسي للسيرفر
  final String baseUrl = 'http://127.0.0.1:8000/api';

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  // 1. جلب الأسئلة
  Future<void> _fetchQuestions() async {
    setState(() => isLoading = true);
    try {
      final token = GetStorage().read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/courses_questions/${widget.learningContentId}'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          questionsList = json.decode(response.body)['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar("خطأ", "فشل جلب الأسئلة");
    }
  }

  // 2. دالة حفظ سؤال واحد (تحديث المسار وفق الروابط الجديدة)
  Future<void> _saveNewQuestion() async {
    if (_questionController.text.isEmpty) {
      Get.snackbar("تنبيه", "يرجى كتابة نص السؤال");
      return;
    }

    setState(() => isSaving = true);
    try {
      final token = GetStorage().read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/courses_questions'), // تم تعديل الرابط هنا
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'learning_content_id': widget.learningContentId,
          'question_text': _questionController.text,
          'answers': List.generate(3, (i) => {
            'answer_text': _optionControllers[i].text,
            'is_correct': _correctOptionIndex == i ? 1 : 0,
          }),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _questionController.clear();
        for (var c in _optionControllers) {c.clear();}
        _correctOptionIndex = 0;
        Get.snackbar("نجاح", "تمت إضافة السؤال بنجاح", backgroundColor: Colors.green, colorText: Colors.white);
        _fetchQuestions();
      } else {
        Get.snackbar("خطأ", "فشل الحفظ: ${response.body}");
      }
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء الحفظ");
    } finally {
      setState(() => isSaving = false);
    }
  }

  // 3. دالة الحذف (تحديث المسار وفق الروابط الجديدة)
  Future<void> _deleteQuestion(int id) async {
    try {
      final token = GetStorage().read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/courses_questions/$id'), // تم تعديل الرابط هنا
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() => questionsList.removeWhere((q) => q['id'] == id));
        Get.snackbar("نجاح", "تم حذف السؤال");
      } else {
        Get.snackbar("خطأ", "لم يتم الحذف من السيرفر");
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل الاتصال بالسيرفر");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text("إدارة أسئلة: ${widget.contentTitle}", style: TextStyle(fontFamily: 'Tajawal', fontSize: 18.sp)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : questionsList.isEmpty
                ? const Center(child: Text("لا توجد أسئلة مضافة حالياً"))
                : ListView.builder(
              padding: EdgeInsets.all(20.w),
              itemCount: questionsList.length,
              itemBuilder: (context, index) => MultipleQuestionWidget(
                index: index,
                question: questionsList[index],
                onDeleteConfirmed: _deleteQuestion,
              ),
            ),
          ),

          Container(
            width: 400.w,
            color: Colors.white,
            padding: EdgeInsets.all(20.w),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("إضافة سؤال جديد", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                  const Divider(),
                  SizedBox(height: 20.h),
                  _buildNewQuestionForm(),
                  SizedBox(height: 30.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveNewQuestion,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("حفظ السؤال", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewQuestionForm() {
    return Column(
      children: [
        TextField(
          controller: _questionController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: "نص السؤال", border: OutlineInputBorder()),
        ),
        SizedBox(height: 20.h),
        const Text("الخيارات (حدد الإجابة الصحيحة)"),
        ...List.generate(3, (index) => Padding(
          padding: EdgeInsets.only(top: 10.h),
          child: Row(
            children: [
              Radio(
                value: index,
                groupValue: _correctOptionIndex,
                onChanged: (val) => setState(() => _correctOptionIndex = val as int),
              ),
              Expanded(
                child: TextField(
                  controller: _optionControllers[index],
                  decoration: InputDecoration(hintText: "الخيار ${index + 1}"),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class MultipleQuestionWidget extends StatefulWidget {
  final dynamic question;
  final int index;
  final Function(int) onDeleteConfirmed;

  const MultipleQuestionWidget({super.key, required this.question, required this.index, required this.onDeleteConfirmed});

  @override
  State<MultipleQuestionWidget> createState() => _MultipleQuestionWidgetState();
}

class _MultipleQuestionWidgetState extends State<MultipleQuestionWidget> {
  bool isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final List answers = widget.question['answers'] ?? [];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 15.h),
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: isConfirming ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: isConfirming ? Colors.red : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: isConfirming ? Colors.red : Colors.blue, radius: 12.r, child: Text("${widget.index + 1}", style: const TextStyle(color: Colors.white, fontSize: 12))),
              SizedBox(width: 10.w),
              Expanded(child: Text(isConfirming ? "تأكيد الحذف؟" : widget.question['question_text'], style: const TextStyle(fontWeight: FontWeight.bold))),
              if (!isConfirming)
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => isConfirming = true))
              else
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => widget.onDeleteConfirmed(widget.question['id'])),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() => isConfirming = false)),
                  ],
                )
            ],
          ),
          if (!isConfirming) ...[
            SizedBox(height: 10.h),
            ...answers.map((a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(a['is_correct'] == 1 ? Icons.check_circle : Icons.circle_outlined, size: 16, color: a['is_correct'] == 1 ? Colors.green : Colors.grey),
                  SizedBox(width: 8.w),
                  Text(a['answer_text']),
                ],
              ),
            )).toList(),
          ]
        ],
      ),
    );
  }
}