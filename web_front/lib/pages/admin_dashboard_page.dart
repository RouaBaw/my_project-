import 'package:flutter/material.dart';
import 'package:web_front1/pages/LearningPathsContent.dart';
import 'package:web_front1/pages/auditors-page.dart';
import 'package:web_front1/pages/children_page.dart';
import 'package:web_front1/pages/parents_page.dart';
import 'package:web_front1/widgets/Content%20industry%20monitor/admin_sidebar.dart';
import 'package:web_front1/widgets/Content%20industry%20monitor/creator_accounts_content.dart';
// تأكد من استيراد صفحة المراقبين التي صممناها سابقاً

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;

  // تحديث القائمة لتشمل 3 صفحات بدلاً من 2
  final List<Widget> _pages = [
    CreatorAccountsContent(), // Index 0
    LearningPathsContent(),    // Index 1
    AuditorsPage(),            // Index 2 (الصفحة الجديدة)
    ParentsPage(),
    ChildrenPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Row(
          children: [
            // 1. الشريط الجانبي (على اليمين)
            Container(
              width: 300,
              child: AdminSidebar(
                currentIndex: _currentIndex,
                onItemTapped: (index) {
                  setState(() {
                    // الآن index 2 أصبح موجوداً ولن يسبب RangeError
                    _currentIndex = index;
                  });
                },
              ),
            ),

            // 2. المحتوى الرئيسي
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                // عرض الصفحة بناءً على الفهرس المختار
                child: _pages[_currentIndex],
              ),
            ),
          ],
        ),
      ),
    );
  }
}