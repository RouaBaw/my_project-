import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

// تأكد من استيراد GetStorage إذا كنت تخزن التوكن فيه
// import 'package:get_storage/get_storage.dart';

class PathReviewPage extends StatefulWidget {
  final Map<String, dynamic> path;

  const PathReviewPage({super.key, required this.path});

  @override
  _PathReviewPageState createState() => _PathReviewPageState();
}

class _PathReviewPageState extends State<PathReviewPage> {
  int _currentStep = 0; // 0: المحتوى (فيديوهات), 1: الاختبارات
  final String baseImageUrl = 'http://127.0.0.1:8000/';

  // جلب الفيديوهات من كل الـ contents المتاحة (Packages)
  List<dynamic> get allVideos {
    List<dynamic> videos = [];
    List<dynamic> contents = widget.path['contents'] ?? [];
    for (var item in contents) {
      if (item['packages'] != null) {
        videos.addAll(item['packages']);
      }
    }
    return videos;
  }

  // جلب الأسئلة من كل الـ contents المتاحة
  List<dynamic> get allQuestions {
    List<dynamic> questions = [];
    List<dynamic> contents = widget.path['contents'] ?? [];
    for (var item in contents) {
      if (item['questions'] != null) {
        questions.addAll(item['questions']);
      }
    }
    return questions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _currentStep == 0 ? 'مراجعة محتوى المسار' : 'مراجعة الأسئلة',
          style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal'
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          _buildPathHeader(), // عرض معلومات المسار الأساسية
          Expanded(
            child: _currentStep == 0 ? _buildVideosList() : _buildQuestionsList(),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("التقدم في المراجعة", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text("${(_currentStep + 1)} / 2", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentStep + 1) / 2,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildPathHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              "$baseImageUrl${widget.path['photo']}",
              width: 60, height: 60, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300], width: 60, height: 60, child: const Icon(Icons.image)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.path['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("بواسطة: ${widget.path['creator']['first_name']} ${widget.path['creator']['last_name']}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosList() {
    var videos = allVideos;
    if (videos.isEmpty) return const Center(child: Text("لا توجد فيديوهات مضافة في هذا المسار"));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: Color(0xFF4299E1)),
            ),
            title: Text(video['title'] ?? 'فيديو بدون عنوان', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(video['content'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // يمكن فتح URL الفيديو هنا
            },
          ),
        );
      },
    );
  }

  Widget _buildQuestionsList() {
    var questions = allQuestions;
    if (questions.isEmpty) return const Center(child: Text("لا توجد أسئلة مضافة في هذا المسار"));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final q = questions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("س ${index + 1}: ${q['question_text']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              if (q['answers'] != null)
                ...((q['answers'] as List).map((ans) => _buildAnswerItem(ans))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnswerItem(Map<String, dynamic> ans) {
    bool isCorrect = ans['is_correct'] == 1;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isCorrect ? Colors.green.withOpacity(0.5) : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
              isCorrect ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: isCorrect ? Colors.green : Colors.grey
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(ans['answer_text'] ?? '', style: TextStyle(color: isCorrect ? Colors.green[700] : Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: _currentStep == 0
          ? ElevatedButton(
        onPressed: () => setState(() => _currentStep = 1),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4299E1),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text("مراجعة الأسئلة", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      )
          : Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep = 0),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 54),
                side: const BorderSide(color: Color(0xFF4299E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("رجوع"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _submitDecision('accepted'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(0, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("قبول", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _submitDecision('rejected'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(0, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("رفض", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // الدالة الفعلية لإرسال القرار للسيرفر
// 1. تأكد من إضافة هذه المكتبة في أعلى الصفحة

// 2. تحديث الدالة لتجلب التوكن من الذاكرة
  Future<void> _submitDecision(String decision) async {
    final storage = GetStorage();
    // جلب التوكن المخزن مسبقاً (تأكد أن الاسم 'token' يطابق ما استخدمته عند تسجيل الدخول)
    String? token = storage.read('token');

    if (token == null) {
      Get.snackbar("خطأ", "لم يتم العثور على رمز التوثيق، يرجى تسجيل الدخول مجدداً",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    Get.showOverlay(
      asyncFunction: () async {
        try {
          String status = decision == 'accepted' ? 'published' : 'rejected';

          final response = await http.post(
            Uri.parse('http://127.0.0.1:8000/api/educational-paths/${widget.path['id']}/review'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'status': status}),
          );

          if (response.statusCode == 200) {
            Get.back(); // الخروج من صفحة المراجعة
            Get.snackbar("تم بنجاح", "تم تحديث حالة المسار إلى $status",
                backgroundColor: Colors.green, colorText: Colors.white);
          } else {
            throw Exception("فشل التحديث");
          }
        } catch (e) {
          Get.snackbar("خطأ", "حدث خطأ أثناء تحديث الحالة",
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
      loadingWidget: const Center(child: CircularProgressIndicator()),
    );
  }}