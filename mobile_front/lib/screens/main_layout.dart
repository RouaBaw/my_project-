import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../widgets/app_drawer.dart';
import 'home_screen.dart';
import 'coursepath.dart';
import 'child_management_page.dart';
import 'ProfilePage.dart';

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final box = GetStorage();
  int _bottomNavIndex = 0;
  Widget? _drawerScreen;
  String _title = "الرئيسية";

  void _changeTab(int index) {
    setState(() {
      _bottomNavIndex = index;
      _drawerScreen = null;
      _updateTitle(index);
    });
  }

  void _updateTitle(int index) {
    final userData = box.read('user_data') ?? {};
    String userType = userData['user_type'] ?? 'child';

    List<String> titles;
    if (userType == 'parent') {
      titles = ["الرئيسية", "المسارات", "إدارة الأبناء", "البروفايل"];
    } else {
      titles = ["الرئيسية", "المسارات", "البروفايل"];
    }

    if (index < titles.length) {
      _title = titles[index];
    }
  }

  void _updateScreenFromDrawer(Widget screen, String title) {
    setState(() {
      _drawerScreen = screen;
      _title = title;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // 1. التحقق من حالة تسجيل الدخول للتحكم بالشريط السفلي فقط
    final String? token = box.read('token');
    final bool isLoggedIn = token != null && token.isNotEmpty;

    final userData = box.read('user_data') ?? {};
    String userType = userData['user_type'] ?? 'child';

    List<Widget> screens = [
      HomeScreen(onStartLearning: () => _changeTab(1)),
      const Coursepath(),
      if (userType == 'parent') const ChildrenManagementPage(),
      const ProfilePage(),
    ];

    List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
      const BottomNavigationBarItem(icon: Icon(Icons.auto_stories_rounded), label: 'المسارات'),
      if (userType == 'parent')
        const BottomNavigationBarItem(icon: Icon(Icons.family_restroom_rounded), label: 'الأبناء'),
      const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'البروفايل'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        centerTitle: true,
      ),

      // --- التعديل هنا: الشريط الجانبي يظهر دائماً الآن ---
      drawer: AppDrawer(onTapLink: _updateScreenFromDrawer),

      body: _drawerScreen ?? screens[_bottomNavIndex >= screens.length ? 0 : _bottomNavIndex],

      // --- إخفاء الشريط السفلي فقط إذا لم يسجل الدخول ---
      bottomNavigationBar: isLoggedIn
          ? BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _bottomNavIndex >= navItems.length ? 0 : _bottomNavIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
            _drawerScreen = null;
            _updateTitle(index);
          });
        },
        items: navItems,
      )
          : null, // يختفي فقط في حال عدم وجود توكن
    );
  }
}