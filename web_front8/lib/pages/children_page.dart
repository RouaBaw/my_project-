import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class ChildrenPage extends StatefulWidget {
  @override
  _ChildrenPageState createState() => _ChildrenPageState();
}

class _ChildrenPageState extends State<ChildrenPage> {
  final String apiUrl = 'http://127.0.0.1:8000/api/users/childs';
  final _storage = GetStorage();
  List<dynamic> children = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChildren();
  }
  Future<void> fetchChildren() async {
    try {
      String? token = _storage.read('token');
      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        // فك تشفير النص أولاً
        final Map<String, dynamic> responseData = json.decode(response.body);

        setState(() {
          // الوصول إلى القائمة الموجودة داخل المفتاح data
          children = responseData['data'];
          isLoading = false;
        });
      } else {
        // التعامل مع حالات الخطأ (مثلاً 401 أو 404)
        setState(() => isLoading = false);
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Exception: $e");
    }
  }

  void _showDetailsModal(Map<String, dynamic> user) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Container(
          width: 700.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header المودال بلون مختلف لتمييز الأطفال
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFF6AD55), Color(0xFFED64A6)]),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35.r,
                      backgroundColor: Colors.white,
                      backgroundImage: user['image_url'] != null ? NetworkImage(user['image_url']) : null,
                      child: user['image_url'] == null ? const Icon(Icons.child_care, size: 30, color: Colors.pink) : null,
                    ),
                    SizedBox(width: 15.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${user['first_name']} ${user['last_name']}",
                            style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
                        const Text("حساب طفل", style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Get.back()),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(30.w),
                child: Wrap(
                  spacing: 30.w,
                  runSpacing: 20.h,
                  children: [
                    _buildDetailBox('اسم الطفل', '${user['first_name']} ${user['last_name']}', Icons.face),
                    _buildDetailBox('العمر', '${user['age'] ?? '---'} سنوات', Icons.cake),
                    _buildDetailBox('رمز PIN', user['pin'] ?? 'غير محدد', Icons.lock_person),
                    _buildDetailBox('المستوى التعليمي', user['education_level'] ?? '---', Icons.school),
                    _buildDetailBox('مرتبط بولي أمر رقم', user['parent_id']?.toString() ?? '---', Icons.family_restroom),
                    _buildDetailBox('تاريخ التسجيل', user['created_at'].toString().split('T')[0], Icons.watch_later_outlined),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailBox(String label, String value, IconData icon) {
    return SizedBox(
      width: 300.w,
      child: Row(
        children: [
          Icon(icon, size: 22.w, color: Colors.pink[300]),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
              Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: EdgeInsets.all(30.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إدارة حسابات الأطفال', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold)),
            Text('متابعة بيانات الأطفال المسجلين تحت إشراف أولياء الأمور', style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
            SizedBox(height: 30.h),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: children.length,
                itemBuilder: (context, index) {
                  final user = children[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 15.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.pink[50],
                        backgroundImage: user['image_url'] != null ? NetworkImage(user['image_url']) : null,
                        child: user['image_url'] == null ? const Icon(Icons.child_care, color: Colors.pink) : null,
                      ),
                      title: Text("${user['first_name']} ${user['last_name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("عمر الطفل: ${user['age'] ?? '---'}"),
                      trailing: ElevatedButton(
                        onPressed: () => _showDetailsModal(user),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink[50], foregroundColor: Colors.pink[700]),
                        child: const Text('عرض التفاصيل'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}