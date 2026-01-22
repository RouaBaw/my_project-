import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  // 1. إضافة متغير لاستقبال الدالة من "الأب"
  final VoidCallback onStartLearning;

  // 2. تحديث الـ Constructor لاستقبال هذه الدالة كعنصر إجباري
  const HomeScreen({super.key, required this.onStartLearning});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity, // لضمان أخذ كامل العرض
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              "مرحباً بك في تطبيق التعلم الذكي",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // 3. إضافة الزر الذي يستدعي الدالة عند النقر
            ElevatedButton.icon(
              onPressed: onStartLearning, // استدعاء الدالة الممررة
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text("ابدأ رحلة التعلم الآن"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}