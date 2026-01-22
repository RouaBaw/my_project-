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

  Future<void> fetchVideosFromServer() async {
    setState(() => isLoading = true);
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
          errorMessage = "حدث خطأ في جلب البيانات";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "تعذر الاتصال بالسيرفر";
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
      params: const YoutubePlayerParams(showFullscreenButton: true, showControls: true),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("إدارة: ${widget.courseTitle}", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Get.to(() => AddVideoPage(courseId: widget.courseId));
                fetchVideosFromServer();
              },
              icon: const Icon(Icons.add),
              label: const Text("إضافة فيديو"),
            ),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: _buildMainPreview(),
            ),
          ),
          _buildSidebar(),
        ],
      ),
    );
  }

  Widget _buildMainPreview() {
    if (videos.isEmpty) return const Center(child: Text("لا توجد فيديوهات"));
    final current = videos[currentVideoIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_ytController != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: YoutubePlayer(controller: _ytController!),
          ),
        const SizedBox(height: 20),
        Text(current['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(current['content'] ?? "لا يوجد وصف لهذه الحلقة.", style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 380,
      color: Colors.white,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("قائمة الحلقات", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isConfirmingDelete ? Colors.red.shade50 : (isSelected ? Colors.blue.shade50 : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isConfirmingDelete ? Colors.red : (isSelected ? Colors.blue : Colors.grey.shade200)),
                  ),
                  child: isConfirmingDelete
                      ? _buildDeleteConfirmationRow(video)
                      : _buildVideoListTile(video, index, isSelected),
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
          const Expanded(child: Text("حذف نهائي؟", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
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

  Widget _buildVideoListTile(dynamic video, int index, bool isSelected) {
    return ListTile(
      onTap: () => _changeVideo(index),
      leading: CircleAvatar(
        backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
        child: Text("${index + 1}", style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
      ),
      title: Text(video['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        onPressed: () => setState(() => videoIdToDelete = video['id']),
      ),
    );
  }
}