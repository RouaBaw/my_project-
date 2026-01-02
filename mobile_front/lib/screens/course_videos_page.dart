import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'tests_page.dart'; // تأكد من مطابقة اسم الملف لديك

class CourseVideosPage extends StatefulWidget {
  final String courseTitle;
  final List packages;
  final List questions; // إضافة استقبال الأسئلة هنا

  const CourseVideosPage({
    super.key,
    required this.courseTitle,
    required this.packages,
    required this.questions, // إضافة هنا
  });

  @override
  State<CourseVideosPage> createState() => _CourseVideosPageState();
}

class _CourseVideosPageState extends State<CourseVideosPage> {
  late YoutubePlayerController _controller;
  Map<String, dynamic>? currentVideo;

  @override
  void initState() {
    super.initState();
    if (widget.packages.isNotEmpty) {
      currentVideo = widget.packages[0];
      _initializeController(currentVideo!['url']);
    }
  }

  void _initializeController(String url) {
    String videoId = YoutubePlayer.convertUrlToId(url) ?? "";
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
      ),
    )..addListener(_videoPlayerListener);
  }

  void _videoPlayerListener() {
    if (_controller.value.playerState == PlayerState.ended) {
      _playNextVideo();
    }
  }

  void _changeVideo(Map<String, dynamic> video) {
    setState(() {
      currentVideo = video;
    });
    String videoId = YoutubePlayer.convertUrlToId(video['url']) ?? "";
    _controller.load(videoId);
  }

  void _playNextVideo() {
    int currentIndex = widget.packages.indexOf(currentVideo);
    if (currentIndex < widget.packages.length - 1) {
      _changeVideo(widget.packages[currentIndex + 1]);
    }
  }

  void _playPreviousVideo() {
    int currentIndex = widget.packages.indexOf(currentVideo);
    if (currentIndex > 0) {
      _changeVideo(widget.packages[currentIndex - 1]);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoPlayerListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Get.back(),
            ),
            title: Text(widget.courseTitle, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          body: Column(
            children: [
              player,
              _buildControlBar(),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(currentVideo?['title'] ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(currentVideo?['content'] ?? "لا يوجد وصف متوفر.", style: TextStyle(color: Colors.grey[700], fontSize: 14)),

                            const SizedBox(height: 24),

                            // تعديل الشرط: يظهر الزر إذا كانت قائمة الأسئلة العامة للكورس غير فارغة
                            if (widget.questions.isNotEmpty)
                              _buildQuizButton(),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text("قائمة الدروس", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.packages.length,
                        itemBuilder: (context, index) {
                          final video = widget.packages[index];
                          bool isSelected = currentVideo?['id'] == video['id'];
                          return ListTile(
                            leading: Icon(isSelected ? Icons.play_circle_fill : Icons.play_circle_outline, color: isSelected ? Colors.red : Colors.grey),
                            title: Text(video['title'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.red : Colors.black87)),
                            onTap: () => _changeVideo(video),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuizButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Get.to(() => TestsPage(
              contentId: currentVideo!['learning_content_id'],
              questionsData: widget.questions, // نمرر الأسئلة القادمة من الكورس
            ));
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz, color: Colors.white),
                SizedBox(width: 10),
                Text("ابدأ اختبار هذا الكورس", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    int currentIndex = widget.packages.indexOf(currentVideo);
    bool hasNext = currentIndex < widget.packages.length - 1;
    bool hasPrev = currentIndex > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(onPressed: hasPrev ? _playPreviousVideo : null, icon: const Icon(Icons.skip_previous), label: const Text("السابق")),
          ElevatedButton.icon(onPressed: hasNext ? _playNextVideo : null, icon: const Text("التالي"), label: const Icon(Icons.skip_next)),
        ],
      ),
    );
  }
}