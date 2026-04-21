import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart'; // المكتبة الأفضل للويب
import '../controllers/paths_controller.dart';
import '../pages/add_course_page.dart';

class AddPathDialog extends StatefulWidget {
  const AddPathDialog({super.key});

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
  final List<String> _categories = const ['Preparatory', 'Beginner', 'Intermediate'];

  String _categoryLabel(String value) {
    switch (value) {
      case 'Preparatory':
        return 'تمهيدي';
      case 'Beginner':
        return 'مبتدئ';
      case 'Intermediate':
        return 'متوسط';
      default:
        return value;
    }
  }

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
      Get.snackbar('خطأ', 'تعذر فتح نافذة اختيار الصور');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pathsController = Get.find<PathsController>();
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        backgroundColor: Colors.white,
        child: Container(
          width: 620.w,
          padding: EdgeInsets.all(28.w),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView( // لتجنب مشاكل المساحة في الشاشات الصغيرة
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(cs),
                  SizedBox(height: 20.h),

                  _buildLabel('اسم المسار'),
                  _buildTextField(
                    _nameController,
                    'مثال: أساسيات البرمجة',
                    validatorText: 'يرجى إدخال اسم المسار',
                  ),
                  SizedBox(height: 14.h),

                  _buildLabel('وصف المسار'),
                  _buildTextField(
                    _descriptionController,
                    'اكتب وصفًا قصيرًا يساعد المستخدم على فهم محتوى المسار...',
                    maxLines: 3,
                    validatorText: 'يرجى إدخال وصف المسار',
                  ),
                  SizedBox(height: 14.h),

                  _buildLabel('الفئة المستهدفة'),
                  _buildCategoryDropdown(),
                  SizedBox(height: 14.h),

                  _buildLabel('صورة المسار'),
                  _buildImagePickerArea(cs),
                  SizedBox(height: 22.h),

                  Row(
                    children: [
                      _buildCloseButton(),
                      SizedBox(width: 12.w),
                      _buildSubmitButton(pathsController, cs),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // منطقة اختيار الصورة مع المعاينة
  Widget _buildImagePickerArea(ColorScheme cs) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(14.r),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _pickImage,
            behavior: HitTestBehavior.opaque, // يضمن استجابة الضغط في الويب
            child: Container(
              height: 160.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
                image: _webImage != null
                    ? DecorationImage(image: MemoryImage(_webImage!), fit: BoxFit.cover)
                    : null,
              ),
              child: _webImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload, size: 34.w, color: cs.primary),
                        SizedBox(height: 8.h),
                        Text(
                          'اضغط لاختيار صورة',
                          style: TextStyle(color: Colors.grey[700], fontFamily: 'Tajawal', fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'PNG / JPG',
                          style: TextStyle(color: Colors.grey[600], fontFamily: 'Tajawal', fontSize: 12.sp),
                        ),
                      ],
                    )
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.55),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(10.w),
                          child: Wrap(
                            spacing: 8.w,
                            children: [
                              _smallOverlayButton(
                                icon: Icons.edit,
                                label: 'تغيير',
                                onTap: _pickImage,
                              ),
                              _smallOverlayButton(
                                icon: Icons.delete_outline,
                                label: 'إزالة',
                                onTap: () {
                                  setState(() {
                                    _webImage = null;
                                    _fileName = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              children: [
                Icon(Icons.image_outlined, color: Colors.grey[700], size: 18.w),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _fileName == null ? 'لم يتم اختيار صورة بعد' : _fileName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontFamily: 'Tajawal',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.upload_file, size: 18.w),
                  label: const Text('اختيار'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(PathsController pathsController, ColorScheme cs) {
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
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
          child: pathsController.isLoading.value
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  'إنشاء المسار وإضافة كورسات',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
        )),
      ),
    );
  }

  // --- دوال مساعدة للواجهة ---
  Widget _buildHeader(ColorScheme cs) {
    return Row(
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(Icons.add, color: cs.primary, size: 24.w),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إضافة مسار تعليمي',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, fontFamily: 'Tajawal'),
              ),
              SizedBox(height: 2.h),
              Text(
                'املأ البيانات التالية لإنشاء مسار جديد',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[700], fontFamily: 'Tajawal'),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'إغلاق',
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    String? validatorText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: const TextStyle(fontFamily: 'Tajawal'),
      validator: (value) => value == null || value.trim().isEmpty
          ? (validatorText ?? 'هذا الحقل مطلوب')
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintTextDirection: TextDirection.rtl,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF2196F3)),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, fontFamily: 'Tajawal'),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12.r),
        color: const Color(0xFFF8FAFC),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          items: _categories
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(_categoryLabel(c), style: const TextStyle(fontFamily: 'Tajawal')),
                ),
              )
              .toList(),
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
          padding: EdgeInsets.symmetric(vertical: 12.h),
        ),
        child: Text('إلغاء', style: TextStyle(color: Colors.grey[800], fontFamily: 'Tajawal', fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _smallOverlayButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.w, color: const Color(0xFF0F172A)),
            SizedBox(width: 6.w),
            Text(label, style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800, fontSize: 12.sp)),
          ],
        ),
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