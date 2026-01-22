import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../core/api_config.dart';

class TestsPage extends StatefulWidget {
  final int contentId;
  final List questionsData;

  const TestsPage({super.key, required this.contentId, required this.questionsData});

  @override
  State<TestsPage> createState() => _TestsPageState();
}

class _TestsPageState extends State<TestsPage> {
  int currentQuestionIndex = 0;
  bool isLoading = false;
  final box = GetStorage();
  Map<int, int?> userAnswers = {}; // تخزين question_id -> answer_id

  Future<void> _submitQuiz() async {
    setState(() => isLoading = true);
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = box.read('token');

      List formattedAnswers = [];
      userAnswers.forEach((qId, aId) {
        formattedAnswers.add({
          "question_id": qId,
          "answer_id": aId,
        });
      });

      final response = await http.post(
        Uri.parse('$baseUrl/quiz/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "learning_content_id": widget.contentId,
          "answers": formattedAnswers
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _showSuccessDialog(result['data']['score']);
      } else {
        Get.snackbar("خطأ في السيرفر", "فشل إرسال النتيجة");
      }
    } catch (e) {
      Get.snackbar("خطأ في الاتصال", "تأكد من اتصالك بالإنترنت");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSuccessDialog(dynamic score) {
    Get.defaultDialog(
      title: "اكتمل الاختبار",
      barrierDismissible: false,
      content: Column(
        children: [
          const Icon(Icons.stars, color: Colors.orange, size: 80),
          const SizedBox(height: 10),
          Text(
            "درجتك النهائية: $score%",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(score >= 50 ? "عمل رائع! استمر في التقدم" : "حاول مرة أخرى لتحسن نتيجتك"),
        ],
      ),
      confirm: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        onPressed: () {
          Get.back(); // إغلاق الديالوج
          Get.back(); // العودة للصفحة السابقة
        },
        child: const Text("العودة للمسار", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questionsData.isEmpty) {
      return const Scaffold(body: Center(child: Text("لا توجد أسئلة لهذا الدرس")));
    }

    final currentQuestion = widget.questionsData[currentQuestionIndex];
    bool isLast = currentQuestionIndex == widget.questionsData.length - 1;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("سؤال ${currentQuestionIndex + 1} من ${widget.questionsData.length}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // شريط التقدم العلوي
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (currentQuestionIndex + 1) / widget.questionsData.length,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 30),

            // نص السؤال
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Text(
                currentQuestion['question_text'] ?? "",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 25),

            // قائمة الإجابات تتبع النص مباشرة
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentQuestion['answers'].length,
              itemBuilder: (context, index) {
                final ans = currentQuestion['answers'][index];
                bool isSelected = userAnswers[currentQuestion['id']] == ans['id'];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : Colors.white,
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: RadioListTile<int>(
                    title: Text(
                      ans['answer_text'],
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blue[800] : Colors.black87,
                      ),
                    ),
                    value: ans['id'],
                    groupValue: userAnswers[currentQuestion['id']],
                    activeColor: Colors.blue,
                    onChanged: (val) {
                      setState(() => userAnswers[currentQuestion['id']] = val);
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // زر الانتقال أو الإنهاء يتبع القائمة مباشرة
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: userAnswers[currentQuestion['id']] == null
                    ? null
                    : () {
                  if (isLast) {
                    _submitQuiz();
                  } else {
                    setState(() {
                      currentQuestionIndex++;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLast ? Colors.green : Colors.blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  isLast ? "إنهاء وإرسال النتيجة" : "السؤال التالي",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40), // مساحة أمان في نهاية الصفحة
          ],
        ),
      ),
    );
  }
} 