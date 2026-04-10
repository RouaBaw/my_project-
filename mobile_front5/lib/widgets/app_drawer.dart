import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:untitled1/screens/ProfilePage.dart';
import 'package:untitled1/screens/child_management_page.dart';
import 'package:untitled1/screens/coursepath.dart';

import '../screens/home_page.dart';
import '../screens/login_page.dart';
import '../screens/parent_registration_page.dart';
import '../screens/settings_screen.dart';
import '../screens/dashboard_page.dart';

class AppDrawer extends StatelessWidget {
  final Function(Widget, String) onTapLink;

  AppDrawer({required this.onTapLink});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();

    // 1. التحقق من حالة تسجيل الدخول
    bool isLoggedIn = box.hasData('token');

    // 2. جلب بيانات المستخدم ونوعه
    Map<String, dynamic> userData = box.read('user_data') ?? {};
    String userName = userData['first_name'] ?? "زائر";
    String userType = userData['user_type'] ?? 'child'; // الافتراضي طفل

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle, size: 60, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  isLoggedIn ? "أهلاً، $userName" : "نظام التعليم الذكي",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                if (isLoggedIn)
                  Text(
                    userType == 'parent' ? "ولي أمر" : "حساب طفل",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),

          // القسم العام (يظهر للجميع)
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("الرئيسية"),
            onTap: () => onTapLink(const Coursepath(), "الرئيسية"),
          ),

          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("لوحة التحكم العامة"),
            onTap: () => onTapLink(DashboardPage(), "لوحة التحكم"),
          ),

          const Divider(),

          // --- قسم الحساب - التحكم الديناميكي ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              isLoggedIn ? "حسابي" : "بوابة الآباء",
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),

          // 1. إذا كان المستخدم "أب" مسجل دخول -> أظهر إدارة الأبناء والملف الشخصي
          if (isLoggedIn && userType == 'parent') ...[
            ListTile(
              leading: const Icon(Icons.family_restroom, color: Colors.blue),
              title: const Text("إدارة حسابات الأبناء"),
              onTap: () => onTapLink(const ChildrenManagementPage(), "إدارة الأبناء"),
            ),
          ],

          // 2. إذا كان المستخدم مسجل دخول (أب أو طفل) -> أظهر الملف الشخصي
          if (isLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("الملف الشخصي"),
              onTap: () => onTapLink(const ProfilePage(), "الملف الشخصي"),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: const Text("تسجيل الخروج من الحساب"),
              onTap: () {
                box.erase();
                Get.offAll(() => const LoginPage());
              },
            ),
          ],

          // 3. إذا كان المستخدم "غير مسجل" (زائر) -> أظهر خيارات الدخول فقط
          if (!isLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text("تسجيل الدخول"),
              onTap: () => onTapLink(LoginPage(), "تسجيل الدخول"),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text("إنشاء حساب أب"),
              onTap: () => onTapLink(ParentRegisterPage(), "إنشاء حساب أب"),
            ),
          ],

          const Divider(),

          // الإعدادات والخروج النهائي
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("إعدادات الـ IP"),
            onTap: () => onTapLink(SettingsScreen(), "إعدادات الاتصال"),
          ),

          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text("إغلاق التطبيق"),
            onTap: () {
              SystemNavigator.pop();
            },
          ),
        ],
      ),
    );
  }
}