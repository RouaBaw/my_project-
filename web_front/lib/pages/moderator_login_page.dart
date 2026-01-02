import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:web_front1/pages/moderator_register_page.dart';
import '../controllers/auth_controller.dart';
// تأكد من استيراد صفحة إنشاء الحساب هنا
// import 'package:web_front1/pages/RegisterPage.dart';

class ModeratorLoginPage extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  final TextEditingController emailController = TextEditingController(text: 'creator3@example.com');
  final TextEditingController passwordController = TextEditingController(text: '123123123');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildLeftSection(),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 80.w),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 450.w),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const CircleAvatar(
                        radius: 35,
                        backgroundColor: Color(0x229C27B0),
                        child: Icon(Icons.lock_person, color: Colors.purple, size: 40),
                      ),
                      SizedBox(height: 24.h),
                      Text('Welcome Back',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 48.h),

                      _buildTextField('Email Address', emailController, Icons.email_outlined),
                      SizedBox(height: 20.h),
                      _buildTextField('Password', passwordController, Icons.lock_outline, isPassword: true),

                      SizedBox(height: 40.h),

                      Obx(() => SizedBox(
                        width: double.infinity,
                        height: 55.h,
                        child: ElevatedButton(
                          onPressed: authController.isLoading.value
                              ? null
                              : () => authController.login(emailController.text, passwordController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                          ),
                          child: authController.isLoading.value
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('Log In', style: TextStyle(fontSize: 18.sp, color: Colors.white)),
                        ),
                      )),

                      SizedBox(height: 24.h),

                      // --- القسم المضاف: زر الانتقال لصفحة إنشاء الحساب ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: () {
                              // استبدل RegisterPage باسم الكلاس الخاص بصفحة التسجيل لديك
                               Get.to(() =>  ModeratorRegisterPage());
                              Get.snackbar("Navigation", "Moving to Registration Page");
                            },
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // ---------------------------------------------
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.purple[300]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
            focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.purple),
                borderRadius: BorderRadius.circular(10.r)),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftSection() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.purple, Color(0xFF4A148C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_stories, size: 80.w, color: Colors.white),
              SizedBox(height: 20.h),
              Text('Smart Learning Platform',
                  style: TextStyle(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 10.h),
              Text('Management Dashboard',
                  style: TextStyle(color: Colors.white70, fontSize: 16.sp)),
            ],
          ),
        ),
      ),
    );
  }
}