import '../pages/ContentCreatorLoginPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ContentCreatorRegisterPage extends StatelessWidget {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController fatherNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Gradient
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade800,
                    Colors.blue.shade600,
                    Colors.blue.shade400,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 60.w,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Join as Content Creator',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    'Start your journey as a content creator',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // Form Container
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(20.w),
              padding: EdgeInsets.all(30.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Personal Information Section
                  _buildSectionHeader('Personal Information'),
                  SizedBox(height: 20.h),
                  
                  // First Name & Last Name
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'First Name',
                          controller: firstNameController,
                          icon: Icons.person_outline,
                        ),
                      ),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: _buildTextField(
                          label: 'Last Name',
                          controller: lastNameController,
                          icon: Icons.person_outline,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  
                  // Father's Name
                  _buildTextField(
                    label: 'Father\'s Name',
                    controller: fatherNameController,
                    icon: Icons.family_restroom_outlined,
                  ),
                  SizedBox(height: 20.h),
                  
                  // Age & City
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Age',
                          controller: ageController,
                          icon: Icons.cake_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: _buildTextField(
                          label: 'City',
                          controller: cityController,
                          icon: Icons.location_city_outlined,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  
                  // Account Information Section
                  _buildSectionHeader('Account Information'),
                  SizedBox(height: 20.h),
                  
                  // Email & Password
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Email Address',
                          controller: emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: _buildTextField(
                          label: 'Password',
                          controller: passwordController,
                          icon: Icons.lock_outlined,
                          isPassword: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  
                  // Mobile
                  _buildTextField(
                    label: 'Mobile Number',
                    controller: mobileController,
                    icon: Icons.phone_android_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 20.h),
                  
                  // Profile Picture Upload
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Picture',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        height: 120.h,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.blue.shade50,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 40.w,
                              color: Colors.blue.shade400,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Upload Profile Picture',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '(Optional)',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.blue.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  
                  // Terms and Conditions
                  Row(
                    children: [
                      Checkbox(
                        value: false,
                        onChanged: (value) {},
                        activeColor: Colors.blue.shade600,
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                            children: [
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  
                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.offAll(ContentCreatorLoginPage());
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blue.shade600),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue.shade600),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  void _handleRegister() {
    // Handle registration logic here
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all required fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    Get.snackbar(
      'Success',
      'Account created successfully!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    
    Get.offAll(ContentCreatorLoginPage());
  }
}