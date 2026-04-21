import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:web_front1/pages/PathReviewPage.dart';

class LearningPathsContent extends StatefulWidget {
  @override
  State<LearningPathsContent> createState() => _LearningPathsContentState();
}

class _LearningPathsContentState extends State<LearningPathsContent> {
  final String apiUrl = 'http://127.0.0.1:8000/api/educational-paths';
  final _storage = GetStorage();

  String selectedFilter = 'all';

  // دالة جلب البيانات
  Future<List<dynamic>> fetchPaths() async {
    try {
      String? token = _storage.read('token');
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('فشل تحميل البيانات');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // --- دالة الحذف الجديدة ---
  Future<void> _deletePath(int pathId) async {
    try {
      String? token = _storage.read('token');
      final response = await http.delete(
        Uri.parse('$apiUrl/$pathId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        Get.snackbar('نجاح', 'تم حذف المسار بنجاح',
            backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
        setState(() {}); // تحديث الواجهة بعد الحذف
      } else {
        Get.snackbar('خطأ', 'فشل الحذف من السيرفر',
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء محاولة الحذف',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // دالة لإظهار تنبيه التأكيد قبل الحذف
  void _confirmDelete(int pathId, String title) {
    Get.defaultDialog(
      title: "تأكيد الحذف",
      middleText: "هل أنت متأكد من رغبتك في حذف مسار '$title'؟ لا يمكن التراجع عن هذا الإجراء.",
      textConfirm: "حذف",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back(); // إغلاق الدايلوج
        _deletePath(pathId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFFF7FAFC),
      child: FutureBuilder<List<dynamic>>(
        future: fetchPaths(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF4299E1)));
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          List<dynamic> allPaths = snapshot.data ?? [];

          int pendingCount = allPaths.where((p) => p['status'] == 'pending').length;
          int publishedCount = allPaths.where((p) => p['status'] == 'published').length;
          int rejectedCount = allPaths.where((p) => p['status'] == 'rejected').length;

          List<dynamic> filteredPaths = selectedFilter == 'all'
              ? allPaths
              : allPaths.where((p) => p['status'] == selectedFilter).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(allPaths.length),
              const SizedBox(height: 20),
              _buildFilterSection(allPaths.length, pendingCount, publishedCount, rejectedCount),
              const SizedBox(height: 24),
              Expanded(
                child: filteredPaths.isEmpty
                    ? const Center(child: Text('لا توجد مسارات في هذا القسم'))
                    : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 25,
                    mainAxisSpacing: 25,
                    mainAxisExtent: 460,
                  ),
                  itemCount: filteredPaths.length,
                  itemBuilder: (context, index) => _buildPathCard(filteredPaths[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(int all, int pending, int published, int rejected) {
    return Row(
      children: [
        _filterButton('الكل', 'all', all, Colors.blue),
        const SizedBox(width: 12),
        _filterButton('بانتظار المراجعة', 'pending', pending, Colors.orange),
        const SizedBox(width: 12),
        _filterButton('تم النشر', 'published', published, Colors.green),
        const SizedBox(width: 12),
        _filterButton('مرفوضة', 'rejected', rejected, Colors.red),
      ],
    );
  }

  Widget _filterButton(String label, String status, int count, Color color) {
    bool isSelected = selectedFilter == status;
    return InkWell(
      onTap: () => setState(() => selectedFilter = status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(count.toString(), style: TextStyle(color: isSelected ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathCard(Map<String, dynamic> path) {
    final String status = path['status'] ?? 'pending';
    final int pathId = path['id'];
    final String pathTitle = path['title'] ?? '';

    Color statusColor;
    String statusText;
    switch (status) {
      case 'published': statusColor = Colors.green; statusText = 'منشور'; break;
      case 'rejected': statusColor = Colors.red; statusText = 'مرفوض'; break;
      default: statusColor = Colors.orange; statusText = 'معلق';
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                "http://127.0.0.1:8000/${path['photo']}",
                height: 180, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.grey[100], child: const Icon(Icons.image)),
              ),
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              // --- زر الحذف فوق الصورة ---
              Positioned(
                top: 12, left: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(pathId, pathTitle),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pathTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1),
                  const SizedBox(height: 8),
                  Text(path['description'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF718096)), maxLines: 2),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("${path['creator']['first_name']} ${path['creator']['last_name']}", style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBadge("${path['dynamic_number_of_courses']}", "كورس"),
                      TextButton(
                        onPressed: () => Get.to(() => PathReviewPage(path: path))?.then((_) => setState(() {})),
                        child: const Text('التفاصيل ←'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('المسارات التعليمية', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() {})),
      ],
    );
  }

  Widget _buildBadge(String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
      child: Text("$count $label", style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(child: Text(error));
  }
}