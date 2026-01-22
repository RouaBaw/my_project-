import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:web_front1/pages/moderator_login_page.dart';

class AdminSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  AdminSidebar({
    Key? key,
    required this.currentIndex,
    required this.onItemTapped,
  }) : super(key: key);

  final _storage = GetStorage();

  @override
  Widget build(BuildContext context) {
    // جلب نوع المستخدم من التخزين (تأكد من حفظه عند تسجيل الدخول باسم 'user_type')
    String userType = _storage.read('user_type') ?? 'system_administrator';
    bool isSystemAdmin = userType == 'system_administrator';

    return Container(
      width: 280.w,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSidebarHeader(userType),

          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              children: [
                // يظهر للجميع
                _buildNavItem(
                  icon: Icons.assignment_ind_outlined, // أيقونة صانعي المحتوى
                  title: 'حسابات صانعي المحتوى',
                  index: 0,
                  isSelected: currentIndex == 0,
                ),

                // يظهر للجميع
                _buildNavItem(
                  icon: Icons.auto_stories_outlined, // أيقونة المسارات التعليمية
                  title: 'المسارات التعليمية',
                  index: 1,
                  isSelected: currentIndex == 1,
                ),

                // هذه القوائم تظهر فقط للـ System Administrator
                if (isSystemAdmin) ...[
                  _buildNavItem(
                    icon: Icons.manage_accounts_outlined,
                    title: 'مراقبي المحتوى',
                    index: 2,
                    isSelected: currentIndex == 2,
                  ),
                  _buildNavItem(
                    icon: Icons.family_restroom_outlined,
                    title: 'ملفات الآباء',
                    index: 3,
                    isSelected: currentIndex == 3,
                  ),
                  _buildNavItem(
                    icon: Icons.child_care_outlined,
                    title: 'ملفات الأبناء',
                    index: 4,
                    isSelected: currentIndex == 4,
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),
          _buildLogoutBtn(),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(String role) {
    String roleLabel = role == 'system_administrator' ? 'مدير النظام' : 'مراقب محتوى';
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: Colors.purple[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              role == 'system_administrator' ? Icons.admin_panel_settings : Icons.visibility_outlined,
              size: 40.w,
              color: Colors.purple,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'لوحة التحكم',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(height: 4.h),
          Text(
            roleLabel,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
  }) {
    return Material(
      color: isSelected ? Colors.purple[50] : Colors.transparent,
      child: InkWell(
        onTap: () => onItemTapped(index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
          decoration: BoxDecoration(
            border: isSelected ? Border(right: BorderSide(color: Colors.purple, width: 4.w)) : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22.w, color: isSelected ? Colors.purple : Colors.grey[500]),
              SizedBox(width: 15.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: isSelected ? Colors.purple : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutBtn() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showLogoutDialog,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20.w, color: Colors.red[400]),
              SizedBox(width: 12.w),
              Text(
                'تسجيل الخروج',
                style: TextStyle(fontSize: 15.sp, color: Colors.red[400], fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Text(
        'Smart Learning v1.0',
        style: TextStyle(fontSize: 11.sp, color: Colors.grey[400]),
      ),
    );
  }

  void _showLogoutDialog() {
    Get.defaultDialog(
      title: 'تسجيل الخروج',
      middleText: 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
      textConfirm: 'خروج',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        _storage.remove('token');
        _storage.remove('user_type'); // مسح نوع المستخدم عند الخروج
        Get.offAll(() => ModeratorLoginPage());
      },
    );
  }
}