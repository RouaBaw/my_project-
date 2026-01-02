import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:untitled1/screens/course_videos_page.dart';
import '../core/api_config.dart';

class Playlist extends StatefulWidget {
  const Playlist({super.key});

  @override
  State<Playlist> createState() => _PlaylistState();
}

class _PlaylistState extends State<Playlist> {
  Map<String, dynamic>? pathData;
  List contents = [];
  bool isLoading = true;
  String? baseImageUrl;
  final box = GetStorage();

  // متغير لتخزين نوع المستخدم
  String? userType;

  // لتتبع أي الكورسات تم فتح تعليقاتها
  Set<int> expandedComments = {};

  @override
  void initState() {
    super.initState();
    // جلب بيانات المستخدم من التخزين المحلي
    _loadUserRole();
    _fetchPathDetails();
  }

  void _loadUserRole() {
    final userData = box.read('user_data');
    if (userData != null) {
      setState(() {
        userType = userData['user_type']; // سيحتوي على 'child' أو 'parent' إلخ
      });
    }
  }

  // --- 1. جلب البيانات من السيرفر ---
  Future<void> _fetchPathDetails() async {
    try {
      final pathId = Get.arguments['path_id'];
      final baseUrl = await ApiConfig.getBaseUrl();
      setState(() {
        baseImageUrl = baseUrl.replaceAll('/api', '');
      });

      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/educational-paths/$pathId/all-contents'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          pathData = decoded['data'];
          contents = decoded['data']['contents'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        Get.snackbar("خطأ", "فشل جلب المحتويات");
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // --- 2. ميثود إرسال التقييم ---
  Future<void> _submitRating(int contentId, double stars, String comment) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = box.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/rate-content'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'learning_content_id': contentId,
          'stars': stars.toInt(),
          'comment': comment,
        }),
      );

      Get.back();
      if (response.statusCode == 200) {
        Get.snackbar("شكراً لك", "تم حفظ تقييمك بنجاح", backgroundColor: Colors.green, colorText: Colors.white);
        _fetchPathDetails();
      }
    } catch (e) {
      Get.back();
      Get.snackbar("خطأ", "فشل الاتصال بالسيرفر");
    }
  }

  // --- 3. نافذة التقييم المنبثقة ---
  void _showRatingDialog(int contentId) {
    double tempStars = 5;
    final commentController = TextEditingController();

    Get.defaultDialog(
      title: "ما رأيك في هذا الدرس؟",
      content: Column(
        children: [
          StatefulBuilder(builder: (context, setDialogState) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => IconButton(
                icon: Icon(index < tempStars ? Icons.star : Icons.star_border, color: Colors.amber, size: 35),
                onPressed: () => setDialogState(() => tempStars = index + 1.0),
              )),
            );
          }),
          const SizedBox(height: 10),
          TextField(
            controller: commentController,
            decoration: InputDecoration(
              hintText: "أضف تعليقك هنا...",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            maxLines: 2,
          ),
        ],
      ),
      textConfirm: "إرسال التقييم",
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _submitRating(contentId, tempStars, commentController.text);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(pathData?['title'] ?? 'محتويات المسار', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Get.back()),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: contents.length,
        itemBuilder: (context, index) {
          final content = contents[index];
          final int videoCount = (content['packages'] as List).length;
          final List ratings = content['ratings'] ?? [];
          final bool isExpanded = expandedComments.contains(content['id']);

          return Container(
            margin: const EdgeInsets.only(bottom: 25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: (pathData?['photo'] != null)
                          ? Image.network('$baseImageUrl/${pathData!['photo']}', height: 180, width: double.infinity, fit: BoxFit.fill)
                          : Image.asset('assets/images/path.jpeg', height: 180, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(height: 50, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.6), Colors.transparent]))),
                    ),
                    const Positioned.fill(child: Center(child: CircleAvatar(backgroundColor: Colors.white70, child: Icon(Icons.play_arrow, color: Colors.blue, size: 30)))),
                    Positioned(
                      bottom: 10, right: 10,
                      child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.9), borderRadius: BorderRadius.circular(5)), child: Text('$videoCount فيديوهات', style: const TextStyle(color: Colors.white, fontSize: 11))),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(content['title'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          _buildStarRow(double.parse(content['rating'].toString()), content['id']),
                          const SizedBox(width: 8),
                          Text("${content['rating']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          const Spacer(),
                          if (ratings.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => setState(() => isExpanded ? expandedComments.remove(content['id']) : expandedComments.add(content['id'])),
                              icon: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.comment_outlined, size: 16),
                              label: Text(isExpanded ? "إخفاء" : "التعليقات"),
                            ),
                        ],
                      ),

                      if (isExpanded) _buildCommentsList(ratings),

                      const Divider(height: 25),
                      _buildFooter(content),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStarRow(double rating, int contentId) {
    return InkWell(
      onTap: () {
        // التحقق: إذا كان المستخدم طفلاً، نمنعه من فتح نافذة التقييم
        if (userType == 'child') {
          Get.snackbar(
            "تنبيه",
            "عذراً، ميزة التقييم متاحة فقط لأولياء الأمور",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blueAccent.withOpacity(0.8),
            colorText: Colors.white,
          );
        } else {
          _showRatingDialog(contentId);
        }
      },
      child: Row(
        children: List.generate(5, (index) => Icon(
          index < rating.floor() ? Icons.star : (index < rating ? Icons.star_half : Icons.star_border),
          color: Colors.amber, size: 20,
        )),
      ),
    );
  }

  Widget _buildCommentsList(List ratings) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: ratings.map((r) => ListTile(
          dense: true,
          leading: const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 12)),
          title: const Text("تقييم مستخدم", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          subtitle: Text(r['comment'] ?? 'بدون تعليق', style: const TextStyle(fontSize: 12)),
          trailing: Text("${r['stars']} ⭐", style: const TextStyle(fontWeight: FontWeight.bold)),
        )).toList(),
      ),
    );
  }

  Widget _buildFooter(dynamic content) {
    return Row(
      children: [
        _buildTag(Icons.help_outline, "${(content['questions'] as List).length} أسئلة", Colors.green),
        const Spacer(),
        TextButton(
          onPressed: () => Get.to(() => CourseVideosPage(courseTitle: content['title'], packages: content['packages'], questions: content['questions'] ?? [])),
          child: Row(children: const [Text("ابدأ التعلم", style: TextStyle(fontWeight: FontWeight.bold)), Icon(Icons.chevron_right)]),
        ),
      ],
    );
  }

  Widget _buildTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold))]),
    );
  }
}