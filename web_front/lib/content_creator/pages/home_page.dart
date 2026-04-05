  import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/dashboard_content.dart';
import '../widgets/paths_content.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    DashboardContent(),
    PathsContent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: Row(
        children: [
          // الشريط الجانبي
          Sidebar(
            currentIndex: _currentIndex,
            onItemTapped: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          // المحتوى الرئيسي
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
    );
  }
}