import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart'; // المكتبة الأفضل للويب
import '../controllers/paths_controller.dart';
import '../pages/add_course_page.dart';

class AddPathDialog extends StatefulWidget {
  @override
  _AddPathDialogState createState() => _AddPathDialogState();
}

class _AddPathDialogState extends State<AddPathDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // بيانات الصورة للويب
  Uint8List? _webImage;
  String? _fileName;

  String _selectedCategory = 'Preparatory';
  final List<String> _categories = ['Preparatory', 'Beginner', 'Intermediate'];

  // دالة اختيار الصورة المخصصة للويب
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true, // ضروري جداً لجلب محتوى الصورة في الويب
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() {
          _webImage = result.files.first.bytes;
          _fileName = result.files.first.name;
        });
      }
    } catch (e) {
      print("Error picking file: $e");
      Get.snackbar('خطأ', 'فشل فتح نافذة اختيار الصور');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pathsController = Get.find<PathsController>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: Colors.white,
      child: Container(
        width: 600.w,
        padding: EdgeInsets.all(32.w),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView( // لتجنب مشاكل المساحة في الشاشات الصغيرة
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 24.h),

                _buildLabel('Path Name'),
                _buildTextField(_nameController, 'Enter path name'),
                SizedBox(height: 16.h),

                _buildLabel('Path Description'),
                _buildTextField(_descriptionController, 'Enter description', maxLines: 3),
                SizedBox(height: 16.h),

                _buildLabel('Target Group'),
                _buildCategoryDropdown(),
                SizedBox(height: 16.h),

                _buildLabel('Track Image'),
                _buildImagePickerArea(),
                SizedBox(height: 32.h),

                Row(
                  children: [
                    _buildCloseButton(),
                    SizedBox(width: 16.w),
                    _buildSubmitButton(pathsController),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // منطقة اختيار الصورة مع المعاينة
  Widget _buildImagePickerArea() {
    return GestureDetector(
      onTap: _pickImage,
      behavior: HitTestBehavior.opaque, // يضمن استجابة الضغط في الويب
      child: Container(
        width: double.infinity,
        height: 150.h,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.grey[50],
          image: _webImage != null
              ? DecorationImage(image: MemoryImage(_webImage!), fit: BoxFit.cover)
              : null,
        ),
        child: _webImage == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload, size: 32.w, color: Colors.blue[400]),
            SizedBox(height: 8.h),
            Text('Click to upload image',
                style: TextStyle(color: Colors.grey[600], fontFamily: 'Tajawal')),
          ],
        )
            : Container(
          alignment: Alignment.bottomRight,
          padding: EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.edit, color: Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(PathsController pathsController) {
    return Expanded(
      child: Container(
        height: 50.h,
        child: Obx(() => ElevatedButton(
          onPressed: pathsController.isLoading.value ? null : () async {
            if (_formKey.currentState!.validate()) {
              if (_webImage == null) {
                Get.snackbar('تنبيه', 'يرجى اختيار صورة للمسار');
                return;
              }

              // إرسال البيانات للباك إيند
              final int? newPathId = await pathsController.uploadPath(
                title: _nameController.text,
                description: _descriptionController.text,
                imageFile: _webImage, // إرسال الـ Bytes
                fileName: _fileName ?? "path.jpg",
              );

              if (newPathId != null) {
                Get.back(); // إغلاق النافذة
                Get.to(() => AddCoursePage(pathId: newPathId));
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2196F3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
          child: pathsController.isLoading.value
              ? CircularProgressIndicator(color: Colors.white)
              : Text('Create & Add Courses',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        )),
      ),
    );
  }

  // --- دوال مساعدة للواجهة ---
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.add_circle, color: Color(0xFF2196F3), size: 30.w),
        SizedBox(width: 12.w),
        Text('New Educational Path',
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
        Spacer(),
        IconButton(icon: Icon(Icons.close), onPressed: () => Get.back()),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(fontFamily: 'Tajawal'),
      validator: (value) => value == null || value.isEmpty ? 'Required field' : null,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Color(0xFF2196F3)),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(text, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontFamily: 'Tajawal')))).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => Get.back(),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[400]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        child: Text('Close', style: TextStyle(color: Colors.grey[700], fontFamily: 'Tajawal')),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}