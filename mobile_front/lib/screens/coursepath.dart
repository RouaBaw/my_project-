import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:untitled1/screens/playlist.dart';
import '../core/api_config.dart';

class Coursepath extends StatefulWidget {
  const Coursepath({super.key});

  @override
  State<Coursepath> createState() => _CoursepathState();
}

class _CoursepathState extends State<Coursepath> {
  String? baseImageUrl;
  List courses = [];
  bool isLoading = true;
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    _fetchEducationalPaths();
  }

  Future<void> _fetchEducationalPaths() async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      setState(() {
        baseImageUrl = baseUrl.replaceAll('/api', '');
      });

      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/educational-paths1'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          courses = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'المسارات التعليمية',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchEducationalPaths,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final imageUrl = (course['photo'] != null && baseImageUrl != null)
                ? '$baseImageUrl/${course['photo']}'
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => Get.to(() => const Playlist(), arguments: {
                  'path_id': course['id'],
                  'path_title': course['title'],
                }),
                borderRadius: BorderRadius.circular(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // صورة المسار مع الشارات
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          child: imageUrl != null
                              ? Image.network(
                            imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                              : Image.asset(
                            'assets/images/path.jpeg',
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // شارة عدد المحتويات
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.video_library, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  '${course['contents_count']} كورسات',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // أيقونة التشغيل في المنتصف
                        const Positioned.fill(
                          child: Center(
                            child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 50),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['title'] ?? '',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            course['description'] ?? '',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildTag(course['status'] == 'published' ? 'منشور' : 'مسودة', Colors.blue),
                              const SizedBox(width: 8),
                              const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'بواسطة: ${course['creator']['first_name']}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.blueAccent),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}