import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:untitled1/screens/login_page.dart';
import 'package:untitled1/screens/child_management_page.dart'; // استيراد صفحة الإدارة

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});


  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final Map<String, dynamic> userData = box.read('user_data') ?? {};
    final String userType = userData['user_type'] ?? 'child';

    final Color primaryColor = userType == 'parent' ? const Color(0xFF1976D2) : Colors.orangeAccent;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // القسم العلوي (التصميم المتدرج)
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50)),
                ),
              ),
              Positioned(
                bottom: -45,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(
                      userType == 'parent' ? Icons.supervisor_account : Icons.child_care,
                      size: 50,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 55),

          Text(
            "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              userType == 'parent' ? "ولي أمر" : "حساب طفل",
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          const SizedBox(height: 30),

          // بطاقة معلومات الحساب
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  _buildInfoTile(Icons.email_outlined, "البريد الإلكتروني", userData['email'] ?? 'لا يوجد بريد'),
                  if (userType == 'child' && userData['parent_id'] != null) ...[
                    const Divider(height: 1, indent: 60),
                    _buildInfoTile(Icons.link, "رقم الأب المرجعي", userData['parent_id'].toString()),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // بطاقة إدارة الأبناء (تظهر فقط للأب بدل الإعدادات)
          if (userType == 'parent')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: InkWell(
                onTap: () => Get.to(() => const ChildrenManagementPage()),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.people, color: Colors.white),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("إدارة حسابات الأبناء", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("أضف، عدل، أو احذف حسابات أطفالك", style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                    ],
                  ),
                ),
              ),
            ),

          const Spacer(),

          // زر تسجيل الخروج
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("تسجيل الخروج", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.blueGrey, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  void _confirmLogout(BuildContext context) {
    Get.defaultDialog(
      title: "تنبيه",
      middleText: "هل تود فعلاً تسجيل الخروج؟",
      textConfirm: "خروج",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        GetStorage().erase();
        Get.offAll(() => const LoginPage());
      },
    );
  }
}