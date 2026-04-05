import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:web_front1/content_creator/pages/course_games_manager.dart';
import 'package:web_front1/pages/course_games_manager1.dart';
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
        surfaceTintColor: Colors.white,
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
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: _pathStatusChip()),
          ),
        ],
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
        int gamesCount = (course['games'] as List?)?.length ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() {
              _selectedCourseIndex = index;
              _currentStep = 0;
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF4299E1).withOpacity(0.1),
                    child: Text("${index + 1}", style: const TextStyle(color: Color(0xFF4299E1), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['course_name'] ?? 'بدون عنوان',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _miniStatChip("فيديوهات", videoCount, const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
                            _miniStatChip("أسئلة", questionCount, const Color(0xFFEDE9FE), const Color(0xFF7C3AED)),
                            _miniStatChip("ألعاب", gamesCount, const Color(0xFFECFDF3), const Color(0xFF059669)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
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

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_circle_fill, color: Colors.red, size: 24),
            ),
            title: Text(
              video['title'] ?? 'فيديو بدون عنوان',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
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
      final currentStatus =
          (widget.path['status'] ?? 'draft').toString().toLowerCase().trim();
      final canPublish = currentStatus != 'published';
      final canReject = currentStatus != 'rejected';

      return SafeArea(
        top: false,
        child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canPublish || canReject)
              Row(
                children: [
                  if (canPublish)
                    Expanded(
                      child: _buildDecisionButton(
                        currentStatus == 'rejected'
                            ? "إعادة نشر المسار"
                            : "قبول المسار بالكامل",
                        Colors.green,
                        'published',
                      ),
                    ),
                  if (canPublish && canReject) const SizedBox(width: 12),
                  if (canReject)
                    Expanded(
                      child: _buildDecisionButton(
                        "رفض المسار",
                        Colors.red,
                        'rejected',
                      ),
                    ),
                ],
              ),
            if (!canPublish && !canReject)
              const Text(
                "حالة المسار محدثة بالفعل.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedCourseIndex != null) _buildManageGamesButton(),
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
    ));
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
    minHeight: 5,
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
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              "$baseImageUrl${widget.path['photo']}",
              width: 56, height: 56, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], width: 56, height: 56, child: const Icon(Icons.image)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.path['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _miniStatChip("الكورسات", contents.length, const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageGamesButton() {
    final course = contents[_selectedCourseIndex!];
    final dynamic rawId = course['id'] ?? course['learning_content_id'];
    final int? learningContentId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    final String courseTitle = (course['course_name'] ?? 'كورس').toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            if (learningContentId == null) {
              Get.snackbar(
                "تنبيه",
                "لا يمكن فتح إدارة الألعاب: معرف الكورس غير متوفر",
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
              return;
            }
            Get.to(() => course_games_manager1(
                  learningContentId: learningContentId,
                  contentTitle: courseTitle,
                ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff0EBB00),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.sports_esports_outlined),
          label: const Text(
            "إدارة ألعاب هذا الكورس",
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
          ),
        ),
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
          final currentStatus =
              (widget.path['status'] ?? 'draft').toString().toLowerCase().trim();

          if (currentStatus == decision) {
            Get.snackbar(
              "تنبيه",
              "المسار بهذه الحالة بالفعل",
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
            return;
          }

          String status = decision;
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
            widget.path['status'] = status;
            if (mounted) setState(() {});
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

  Widget _pathStatusChip() {
    final status = (widget.path['status'] ?? 'draft').toString().toLowerCase().trim();

    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'published':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'منشور';
        icon = Icons.verified_rounded;
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'مرفوض';
        icon = Icons.block_rounded;
        break;
      case 'pending':
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFC2410C);
        label = 'قيد المراجعة';
        icon = Icons.hourglass_top_rounded;
        break;
      case 'draft':
      default:
        bg = const Color(0xFFE5E7EB);
        fg = const Color(0xFF374151);
        label = 'مسودة';
        icon = Icons.edit_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatChip(String label, int value, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        "$label: $value",
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }
}