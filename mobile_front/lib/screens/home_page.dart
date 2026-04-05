import 'package:untitled1/screens/playlist.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        items: [
        BottomNavigationBarItem(icon: Icon(Icons.video_file),label: 'المسارات'),
        BottomNavigationBarItem(icon: Icon(Icons.question_answer),label: 'الانجازات'),
        BottomNavigationBarItem(icon: Icon(Icons.settings),label: 'الاعدادات'),
        BottomNavigationBarItem(icon: Icon(Icons.person),label: 'البروفايل')
      ]),
      body: Playlist(),
    );
  }
}