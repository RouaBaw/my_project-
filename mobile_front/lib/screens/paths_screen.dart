import 'package:flutter/material.dart';

class PathsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              "هنا ستظهر المسارات التعليمية قريباً",
              style: TextStyle(fontSize: 18),
            ),
            ElevatedButton(
              onPressed: () {
                // سنضع هنا دالة جلب البيانات من الـ API لاحقاً
              },
              child: Text("تحديث البيانات"),
            )
          ],
        ),
      ),
    );
  }
}