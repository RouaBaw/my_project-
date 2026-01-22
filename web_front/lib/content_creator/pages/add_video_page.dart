import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/course_controller.dart';

class AddVideoPage extends StatefulWidget {
  final int courseId;

  const AddVideoPage({super.key, required this.courseId});

  @override
  State<AddVideoPage> createState() => _AddVideoPageState();
}

class _AddVideoPageState extends State<AddVideoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final CourseController controller = Get.find<CourseController>();

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: const Text("إضافة فيديو جديد للمسار",
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // لضمان استجابة المحتوى عند ظهور لوحة المفاتيح
            padding: EdgeInsets.symmetric(
                vertical: isMobile ? 10 : 30,
                horizontal: isMobile ? 10 : 20
            ),
            child: Center(
              child: ConstrainedBox(
                // تحديد أقصى عرض للويب مع السماح بالتصغير للجوال
                constraints: BoxConstraints(
                  maxWidth: 650,
                  minWidth: isMobile ? size.width : 500,
                ),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 20 : 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10)
                      )
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.video_library, color: Colors.blueAccent, size: 28),
                            const SizedBox(width: 10),
                            const Text("تفاصيل الفيديو",
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text("سيتم إضافة هذا الفيديو إلى الكورس رقم: #${widget.courseId}",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        const Divider(height: 40, thickness: 1),

                        _buildTextField(
                          label: "عنوان الفيديو",
                          controller: _titleController,
                          icon: Icons.title,
                          hint: "مثال: مقدمة في لغة Dart",
                          validator: (v) => v!.isEmpty ? "يرجى إدخال العنوان" : null,
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          label: "رابط اليوتيوب (URL)",
                          controller: _urlController,
                          icon: Icons.link,
                          hint: "https://www.youtube.com/watch?v=...",
                          validator: (v) => v!.isEmpty || !v.contains("http") ? "يرجى إدخال رابط صالح" : null,
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          label: "وصف الفيديو (اختياري)",
                          controller: _descController,
                          icon: Icons.description,
                          hint: "اكتب شرحاً قصيراً عما يتضمنه الفيديو...",
                          maxLines: 3,
                        ),
                        const SizedBox(height: 40),

                        Obx(() => SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value ? null : _submitData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: controller.isLoading.value
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("إضافة الفيديو للمسار",
                                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // نفس الدالة السابقة مع تحسين بسيط في التنسيق
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal', fontSize: 15)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.blueAccent, size: 22),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
          ),
        ),
      ],
    );
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      bool success = await controller.addVideoPackage(
        learningContentId: widget.courseId,
        title: _titleController.text,
        url: _urlController.text,
        description: _descController.text,
      );

      if (success) {
        Get.back();
      }
    }
  }
}