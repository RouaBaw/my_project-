import 'package:flutter/material.dart';
import '../core/api_config.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();

  void _save() async {
    await ApiConfig.setConnection(_ipController.text, _portController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم حفظ الإعدادات بنجاح!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("إعدادات الاتصال بالسيرفر")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ipController,
              decoration: InputDecoration(labelText: "IP Address (مثال: 192.168.1.5)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _portController,
              decoration: InputDecoration(labelText: "Port (مثال: 8000)"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: Text("حفظ الإعدادات"))
          ],
        ),
      ),
    );
  }
}