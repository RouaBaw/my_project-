import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:web_front1/controllers/auth_controller.dart';
import '../controllers/user_controller.dart';

class Sidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const Sidebar({
    Key? key,
    required this.currentIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final UserController userController = Get.find();
    final AuthController authController = Get.find(); // الوصول لمتحكم تسجيل الخروج

    return Container(
      width: 280.w,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // معلومات المستخدم
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Obx(() {
              final user = userController.user.value;
              return Column(
                children: [
                  CircleAvatar(
                    radius: 40.w,
                    backgroundImage: NetworkImage(user?.imageUrl??'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150'),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    user?.name??'user',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16.w),
                      SizedBox(width: 4.w),
                      Text(
                        '3',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),

          // قائمة التنقل
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  icon: Icons.dashboard,
                  title: 'لوحة التحكم',
                  index: 0,
                  isSelected: currentIndex == 0,
                ),
                _buildNavItem(
                  icon: Icons.school,
                  title: 'المسارات التعليمية',
                  index: 1,
                  isSelected: currentIndex == 1,
                ),

                // --- إضافة زر تسجيل الخروج هنا ---
                const Divider(), // خط فاصل
                _buildLogoutBtn(authController),
              ],
            ),
          ),

          // عنصر جمالي في الأسفل
          Container(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.auto_stories,
                    size: 40.w,
                    color: Colors.blue[300],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'منصة التعلم',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دالة مخصصة لزر تسجيل الخروج
  Widget _buildLogoutBtn(AuthController authController) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutDialog(authController),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
          child: Row(
            children: [
              Icon(
                Icons.logout,
                size: 20.w,
                color: Colors.redAccent,
              ),
              SizedBox(width: 12.w),
              Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.redAccent,
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // تنبيه لتأكيد الخروج
  void _showLogoutDialog(AuthController authController) {
    Get.defaultDialog(
      title: "Confirm Logout",
      middleText: "Are you sure you want to sign out?",
      textConfirm: "Yes, Logout",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        authController.logout(); // استدعاء دالة المسح والتوجيه
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected ? Colors.blue[50] : Colors.transparent,
      child: InkWell(
        onTap: () => onItemTapped(index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
          decoration: BoxDecoration(
            border: isSelected
                ? Border(
              right: BorderSide(color: Colors.blue, width: 3.w),
            )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20.w,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: isSelected ? Colors.blue : Colors.grey[600],
                  fontFamily: 'Tajawal',
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}