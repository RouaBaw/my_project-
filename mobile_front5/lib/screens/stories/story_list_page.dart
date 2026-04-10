import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:untitled1/core/api_config.dart';
import 'package:untitled1/screens/stories/story_player_page.dart';

class StoryListPage extends StatefulWidget {
  final int contentId;
  final String contentTitle;

  const StoryListPage({
    super.key,
    required this.contentId,
    required this.contentTitle,
  });

  @override
  State<StoryListPage> createState() => _StoryListPageState();
}

class _StoryListPageState extends State<StoryListPage> {
  final box = GetStorage();
  List<dynamic> stories = [];
  bool isLoading = true;
  String? loadError;

  Future<void> _fetchStories() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/play/content/${widget.contentId}/stories'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          stories = (decoded['data'] as List?) ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          loadError = 'تعذر تحميل القصص';
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        loadError = 'فشل الاتصال بالسيرفر';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'قصص المحتوى',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                widget.contentTitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchStories,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'استمتع بتجربة القصص التعليمية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'اختر القصة التي تريد قراءتها، ثم انتقل إلى أسئلتها التفاعلية في النهاية.',
                      style: TextStyle(
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (loadError != null)
                _buildStateCard(
                  icon: Icons.error_outline,
                  title: 'حدث خطأ',
                  subtitle: loadError!,
                  buttonLabel: 'إعادة المحاولة',
                  onPressed: _fetchStories,
                )
              else if (stories.isEmpty)
                _buildStateCard(
                  icon: Icons.auto_stories_outlined,
                  title: 'لا توجد قصص منشورة بعد',
                  subtitle: 'ستظهر القصص هنا فور نشرها لهذا المحتوى.',
                  buttonLabel: 'تحديث',
                  onPressed: _fetchStories,
                )
              else
                ...stories.map((story) => _buildStoryCard(story)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCard(dynamic story) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Get.to(
            () => StoryPlayerPage(
              storyId: story['id'],
              contentTitle: widget.contentTitle,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (story['title'] ?? 'بدون عنوان').toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (story['description'] ?? 'قصة تعليمية تفاعلية').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip(Icons.view_agenda_outlined, '${story['contents_count'] ?? 0} مشاهد'),
                          _chip(Icons.quiz_outlined, '${story['questions_count'] ?? 0} أسئلة'),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left_rounded, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF334155)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
