import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:get/get.dart';
import 'add_video_page.dart';

class WebCourseVideosPage extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const WebCourseVideosPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<WebCourseVideosPage> createState() => _WebCourseVideosPageState();
}

class _WebCourseVideosPageState extends State<WebCourseVideosPage> {
  List<dynamic> videos = [];
  bool isLoading = true;
  String? errorMessage;
  int currentVideoIndex = 0;
  int? videoIdToDelete; // لتتبع الفيديو الذي يراد حذفه حالياً
  YoutubePlayerController? _ytController;

  final String apiBaseUrl = 'http://127.0.0.1:8000/api';

  @override
  void initState() {
    super.initState();
    fetchVideosFromServer();
  }

  @override
  void dispose() {
    _ytController?.close();
    super.dispose();
  }

  Future<void> fetchVideosFromServer() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final token = GetStorage().read('token');
      final response = await http.get(
        Uri.parse('$apiBaseUrl/courses_videos/${widget.courseId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          videos = jsonResponse['data'] ?? [];
          isLoading = false;
          if (videos.isNotEmpty && _ytController == null) {
            _setupPlayer(videos[currentVideoIndex]['url']);
          }
        });
      } else {
        setState(() {
          errorMessage = "حدث خطأ في جلب الفيديوهات (رمز: ${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "تعذر الاتصال بالسيرفر، يرجى المحاولة لاحقًا";
        isLoading = false;
      });
    }
  }

  Future<void> deleteVideo(int videoId) async {
    try {
      final token = GetStorage().read('token');
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/content-packages/$videoId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        Get.snackbar("نجاح", "تم حذف الفيديو", backgroundColor: Colors.green, colorText: Colors.white);
        setState(() {
          videoIdToDelete = null;
          _ytController = null;
          currentVideoIndex = 0;
        });
        fetchVideosFromServer();
      }
    } catch (e) {
      Get.snackbar("خطأ", "فشل الحذف", backgroundColor: Colors.red);
    }
  }

  void _setupPlayer(String url) {
    final videoId = _extractId(url);
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        enableCaption: true,
        showVideoAnnotations: false,
      ),
    );
  }

  void _changeVideo(int index) {
    setState(() {
      currentVideoIndex = index;
      videoIdToDelete = null; // إلغاء أي حالة حذف عند تغيير الفيديو
    });
    final videoId = _extractId(videos[index]['url']);
    _ytController?.loadVideoById(videoId: videoId);
  }

  String _extractId(String url) {
    if (url.contains("youtu.be/")) return url.split("youtu.be/")[1].split("?")[0];
    if (url.contains("v=")) return url.split("v=")[1].split("&")[0];
    return url.split("/").last;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 1000;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'فيديوهات الكورس',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                widget.courseTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          leading: IconButton(
            tooltip: 'رجوع',
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Get.back(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Get.to(() => AddVideoPage(courseId: widget.courseId));
                  fetchVideosFromServer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add),
                label: const Text('إضافة فيديو', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
        body: isLoading
            ? Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(color: cs.primary),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: errorMessage != null
                    ? _buildStateCard(
                        title: 'حدث خطأ',
                        subtitle: errorMessage!,
                        buttonLabel: 'إعادة المحاولة',
                        onPressed: fetchVideosFromServer,
                        icon: Icons.error_outline,
                        iconColor: Colors.redAccent,
                      )
                    : videos.isEmpty
                        ? _buildStateCard(
                            title: 'لا توجد فيديوهات بعد',
                            subtitle: 'ابدأ بإضافة أول فيديو لهذا الكورس.',
                            buttonLabel: 'إضافة فيديو',
                            onPressed: () async {
                              await Get.to(() => AddVideoPage(courseId: widget.courseId));
                              fetchVideosFromServer();
                            },
                            icon: Icons.video_library_outlined,
                          )
                        : isNarrow
                            ? Column(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(12),
                                      child: _buildMainPreview(cs),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 320,
                                    child: _buildSidebar(cs),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(18),
                                      child: _buildMainPreview(cs),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  SizedBox(
                                    width: 360,
                                    child: _buildSidebar(cs),
                                  ),
                                ],
                              ),
              ),
      ),
    );
  }

  Widget _buildMainPreview(ColorScheme cs) {
    final current = videos[currentVideoIndex];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _ytController == null
                  ? Container(
                      color: Colors.black12,
                      child: const Center(
                        child: Text('لا يمكن تشغيل الفيديو', style: TextStyle(color: Colors.white)),
                      ),
                    )
                  : YoutubePlayer(controller: _ytController!),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            current['title'] ?? 'بدون عنوان',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            current['content'] ?? 'لا يوجد وصف لهذه الحلقة.',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.playlist_play, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "قائمة الحلقات",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'Tajawal'),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${videos.length}',
                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                bool isSelected = index == currentVideoIndex;
                bool isConfirmingDelete = videoIdToDelete == video['id'];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isConfirmingDelete
                        ? Colors.red.shade50
                        : (isSelected ? cs.primary.withOpacity(0.06) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isConfirmingDelete
                          ? Colors.redAccent
                          : (isSelected ? cs.primary : Colors.grey.shade200),
                    ),
                  ),
                  child: isConfirmingDelete
                      ? _buildDeleteConfirmationRow(video)
                      : _buildVideoListTile(video, index, isSelected, cs),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // وضع التأكيد داخل القائمة (بعيداً عن منطقة الفيديو)
  Widget _buildDeleteConfirmationRow(dynamic video) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "حذف نهائي؟",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () => deleteVideo(video['id']),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => setState(() => videoIdToDelete = null),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoListTile(dynamic video, int index, bool isSelected, ColorScheme cs) {
    return ListTile(
      onTap: () => _changeVideo(index),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: isSelected ? cs.primary : Colors.grey.shade200,
        child: Text(
          "${index + 1}",
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(
        video['title'] ?? 'بدون عنوان',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 13),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        tooltip: 'حذف الفيديو',
        onPressed: () => setState(() => videoIdToDelete = video['id']),
      ),
    );
  }

  Widget _buildStateCard({
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
    IconData icon = Icons.info_outline,
    Color iconColor = const Color(0xFF4F46E5),
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}