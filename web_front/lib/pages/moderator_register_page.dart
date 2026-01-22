import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // لاستخدام kIsWeb
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'moderator_login_page.dart';

class ModeratorRegisterPage extends StatefulWidget {
  @override
  State<ModeratorRegisterPage> createState() => _ModeratorRegisterPageState();
}

class _ModeratorRegisterPageState extends State<ModeratorRegisterPage> {
  // وحدات التحكم بالحقول
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController educationLevelController = TextEditingController();

  File? _imageFile;          // للموبايل
  Uint8List? _webImage;     // للويب (حل مشكلة !kIsWeb)
  bool _isLoading = false;

  // دالة اختيار الصورة المتوافقة مع الويب والموبايل
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        var f = await image.readAsBytes();
        setState(() {
          _webImage = f;
          _imageFile = File(image.path); // حفظ المسار للشكل فقط
        });
      } else {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // القسم الأيسر - تصميم ثابت
          _buildLeftSection(),

          // القسم الأيمن - نموذج الإدخال
          Expanded(
            child: Container(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 60.w, vertical: 20.h),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 800.w),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        _buildFormHeader(),
                        SizedBox(height: 30.h),

                        // الاسم الأول، الأب، الكنية
                        Row(
                          children: [
                            Expanded(child: _buildTextField('First Name', firstNameController, Icons.person_outline)),
                            SizedBox(width: 15.w),
                            Expanded(child: _buildTextField('Father Name', fatherNameController, Icons.person_outline)),
                            SizedBox(width: 15.w),
                            Expanded(child: _buildTextField('Last Name', lastNameController, Icons.person_outline)),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        // الرقم الوطني والبريد الإلكتروني
                        Row(
                          children: [
                            Expanded(child: _buildTextField('National ID', nationalIdController, Icons.badge_outlined)),
                            SizedBox(width: 15.w),
                            Expanded(child: _buildTextField('Email Address', emailController, Icons.email_outlined)),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        // كلمة المرور والهاتف
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Password', passwordController, Icons.lock_outline, isPassword: true)),
                            SizedBox(width: 15.w),
                            Expanded(child: _buildTextField('Phone Number', phoneController, Icons.phone_android_outlined)),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        // العمر والمستوى التعليمي
                        Row(
                          children: [
                            Expanded(child: _buildTextField('Age', ageController, Icons.cake_outlined, keyboardType: TextInputType.number)),
                            SizedBox(width: 15.w),
                            Expanded(child: _buildTextField('Education Level', educationLevelController, Icons.school_outlined)),
                          ],
                        ),
                        SizedBox(height: 25.h),

                        // حقل رفع الصورة (معدل للويب)
                        _buildImagePickerSection(),
                        SizedBox(height: 35.h),

                        // زر الإرسال
                        _buildSubmitButton(),
                        SizedBox(height: 20.h),

                        _buildLoginLink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // دالة الإرسال المتوافقة مع MultipartRequest
  Future<void> _handleRegister() async {
    if (firstNameController.text.isEmpty || emailController.text.isEmpty || nationalIdController.text.isEmpty) {
      Get.snackbar('خطأ', 'يرجى ملء الحقول الإجبارية', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8000/api/register'));

      // الحقول النصية الثابتة للـ Backend
      request.fields['first_name'] = firstNameController.text;
      request.fields['father_name'] = fatherNameController.text;
      request.fields['last_name'] = lastNameController.text;
      request.fields['national_id'] = nationalIdController.text;
      request.fields['email'] = emailController.text;
      request.fields['password'] = passwordController.text;
      request.fields['phone_number'] = phoneController.text;
      request.fields['age'] = ageController.text;
      request.fields['education_level'] = educationLevelController.text;
      request.fields['user_type'] = 'content_creator'; // نوع المستخدم تلقائي

      // معالجة رفع الصورة للويب والموبايل
      if (kIsWeb && _webImage != null) {
        request.files.add(http.MultipartFile.fromBytes(
            'image_file',
            _webImage!,
            filename: 'profile_img.png'
        ));
      } else if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image_file', _imageFile!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        Get.snackbar('نجاح', 'تم إنشاء الحساب، بانتظار مراجعة الإدارة', backgroundColor: Colors.green, colorText: Colors.white);
        Get.offAll(() => ModeratorLoginPage());
      } else {
        Get.snackbar('خطأ', 'فشل التسجيل: ${response.body}', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ في الاتصال بالسيرفر', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- المكونات البصرية ---

  Widget _buildLeftSection() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.purple, Color(0xFF4A148C)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 80.w, color: Colors.white),
            SizedBox(height: 20.h),
            Text('Smart Learning Platform', style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.bold)),
            Text('Content Creator Portal', style: TextStyle(color: Colors.white70, fontSize: 18.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile Picture (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
        SizedBox(height: 10.h),
        InkWell(
          onTap: _pickImage,
          child: Container(
            height: 120.h,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: _webImage != null || _imageFile != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: kIsWeb
                  ? Image.memory(_webImage!, fit: BoxFit.contain)
                  : Image.file(_imageFile!, fit: BoxFit.contain),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_outlined, color: Colors.purple[200], size: 40.sp),
                Text('Click to upload image', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20.sp, color: Colors.purple[300]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.purple), borderRadius: BorderRadius.circular(10.r)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('Create Creator Account', style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFormHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Register New Creator', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.purple[900])),
        SizedBox(height: 5.h),
        Text('Fill in the details to join as a content creator', style: TextStyle(color: Colors.grey[600], fontSize: 14.sp)),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () => Get.offAll(() => ModeratorLoginPage()),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: "Already have an account? ", style: TextStyle(color: Colors.grey[600])),
          const TextSpan(text: "Sign In", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
        ])),
      ),
    );
  }
}