import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PathReviewPage extends StatefulWidget {
  final Map<String, dynamic> path;

  const PathReviewPage({super.key, required this.path});

  @override
  _PathReviewPageState createState() => _PathReviewPageState();
}

class _PathReviewPageState extends State<PathReviewPage> {
  int? _selectedCourseIndex;
  int _currentStep = 0; // 0: فيديوهات الكورس، 1: أسئلة الكورس

  final String baseImageUrl = 'http://127.0.0.1:8000/';

  List<dynamic> get contents => widget.path['contents'] ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _buildAppBarTitle(),
          style: const TextStyle(
              color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_selectedCourseIndex != null) {
              setState(() => _selectedCourseIndex = null);
            } else {
              Get.back();
            }
          },
        ),
      ),
      body: Column(
        children: [
          if (_selectedCourseIndex != null) _buildProgressBar(),
          _buildPathHeader(),
          Expanded(
            child: _selectedCourseIndex == null
                ? _buildCoursesList()
                : (_currentStep == 0 ? _buildVideosList() : _buildQuestionsList()),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  String _buildAppBarTitle() {
    if (_selectedCourseIndex == null) return 'قائمة كورسات المسار';
    String courseName = contents[_selectedCourseIndex!]['course_name'] ?? 'كورس';
    return _currentStep == 0 ? 'فيديوهات: $courseName' : 'أسئلة: $courseName';
  }

  // --- قائمة الكورسات ---
  Widget _buildCoursesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contents.length,
      itemBuilder: (context, index) {
        final course = contents[index];
        int videoCount = (course['packages'] as List?)?.length ?? 0;
        int questionCount = (course['questions'] as List?)?.length ?? 0;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF4299E1).withOpacity(0.1),
              child: Text("${index + 1}", style: const TextStyle(color: Color(0xFF4299E1))),
            ),
            title: Text(course['course_name'] ?? 'بدون عنوان',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("فيديوهات: $videoCount | أسئلة: $questionCount"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => setState(() {
              _selectedCourseIndex = index;
              _currentStep = 0;
            }),
          ),
        );
      },
    );
  }

  // --- عرض الفيديوهات مع مشغل يوتيوب عند الضغط ---
  Widget _buildVideosList() {
    final course = contents[_selectedCourseIndex!];
    final List videos = course['packages'] ?? [];

    if (videos.isEmpty) return _buildEmptyState("لا توجد فيديوهات في هذا الكورس");

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        final String? videoUrl = video['url']; // الرابط من قاعدة البيانات

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.grey[100]!)),
          child: ListTile(
            leading: const Icon(Icons.play_circle_fill, color: Colors.red, size: 30),
            title: Text(video['title'] ?? 'فيديو بدون عنوان'),
            subtitle: const Text("اضغط للمشاهدة", style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.remove_red_eye_outlined),
            onTap: () {
              if (videoUrl != null && videoUrl.isNotEmpty) {
                _showYoutubePlayer(videoUrl, video['title'] ?? 'عرض الفيديو');
              } else {
                Get.snackbar("تنبيه", "رابط الفيديو غير متوفر");
              }
            },
          ),
        );
      },
    );
  }

  // --- دالة تشغيل اليوتيوب في نافذة منبثقة ---
  void _showYoutubePlayer(String url, String title) {
    String? videoId = YoutubePlayer.convertUrlToId(url);

    if (videoId == null) {
      Get.snackbar("خطأ", "رابط يوتيوب غير صالح", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    YoutubePlayerController _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );

    Get.dialog(
      Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
            YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.red,
              onReady: () => _controller.addListener(() {}),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ).then((_) => _controller.dispose()); // إغلاق المشغل عند إغلاق النافذة
  }

  // --- عرض الأسئلة ---
  Widget _buildQuestionsList() {
    final course = contents[_selectedCourseIndex!];
    final List questions = course['questions'] ?? [];

    if (questions.isEmpty) return _buildEmptyState("لا توجد أسئلة في هذا الكورس");

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
              border: Border.all(color: Colors.grey[200]!)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("س ${index + 1}: ${q['question_text']}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (q['answers'] != null)
                ...((q['answers'] as List).map((ans) => _buildAnswerItem(ans))),
            ],
          ),
        );
      },
    );
  }

  // --- الأزرار السفلية ---
  Widget _buildActionButtons() {
    if (_selectedCourseIndex == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(child: _buildDecisionButton("قبول المسار بالكامل", Colors.green, 'accepted')),
            const SizedBox(width: 12),
            Expanded(child: _buildDecisionButton("رفض المسار", Colors.red, 'rejected')),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (_currentStep == 0)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _currentStep = 1),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4299E1), minimumSize: const Size(0, 50)),
                    child: const Text("الانتقال للأسئلة", style: TextStyle(color: Colors.white)),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep = 0),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)),
                    child: const Text("العودة للفيديوهات"),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _selectedCourseIndex = null),
            child: const Text("العودة لقائمة الكورسات", style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }

  // الدالات المساعدة (UI)
  Widget _buildDecisionButton(String text, Color color, String decision) {
    return ElevatedButton(
      onPressed: () => _submitDecision(decision),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProgressBar() => LinearProgressIndicator(
    value: (_currentStep + 1) / 2,
    backgroundColor: Colors.grey[200],
    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
    minHeight: 4,
  );

  Widget _buildEmptyState(String msg) => Center(child: Text(msg, style: const TextStyle(color: Colors.grey)));

  Widget _buildAnswerItem(Map<String, dynamic> ans) {
    bool isCorrect = ans['is_correct'] == 1;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isCorrect ? Colors.green.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isCorrect ? Colors.green : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(isCorrect ? Icons.check_circle : Icons.circle_outlined, size: 18, color: isCorrect ? Colors.green : Colors.grey),
          const SizedBox(width: 10),
          Expanded(child: Text(ans['answer_text'] ?? '')),
        ],
      ),
    );
  }

  Widget _buildPathHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              "$baseImageUrl${widget.path['photo']}",
              width: 50, height: 50, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], width: 50, height: 50, child: const Icon(Icons.image)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.path['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("إجمالي الكورسات: ${contents.length}", style: const TextStyle(fontSize: 12, color: Colors.blue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitDecision(String decision) async {
    final storage = GetStorage();
    String? token = storage.read('token');

    if (token == null) {
      Get.snackbar("خطأ", "انتهت الجلسة، يرجى تسجيل الدخول", backgroundColor: Colors.red, colorText: Colors.white);
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
            Get.back();
            Get.snackbar("تم", "تم تحديث حالة المسار بنجاح", backgroundColor: Colors.green, colorText: Colors.white);
          } else {
            throw Exception();
          }
        } catch (e) {
          Get.snackbar("خطأ", "فشل الاتصال بالسيرفر", backgroundColor: Colors.red, colorText: Colors.white);
        }
      },
      loadingWidget: const Center(child: CircularProgressIndicator()),
    );
  }
}