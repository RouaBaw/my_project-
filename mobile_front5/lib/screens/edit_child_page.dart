import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../core/api_config.dart';

class EditChildPage extends StatefulWidget {
  final dynamic childData; // استلام بيانات الطفل الحالية

  const EditChildPage({super.key, required this.childData});

  @override
  State<EditChildPage> createState() => _EditChildPageState();
}

class _EditChildPageState extends State<EditChildPage> {
  final _formKey = GlobalKey<FormState>();
  final box = GetStorage();
  bool isLoading = false;

  // تعريف المتحكمات وتعبئتها بالبيانات القديمة
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController nationalIdController;
  late TextEditingController ageController;
  String? selectedLevel;

  final List<String> educationLevels = ['Primary', 'Middle', 'High School'];

  @override
  void initState() {
    super.initState();
    // تعبئة البيانات القادمة من الصفحة السابقة
    firstNameController = TextEditingController(text: widget.childData['first_name']);
    lastNameController = TextEditingController(text: widget.childData['last_name']);
    nationalIdController = TextEditingController(text: widget.childData['national_id']);
    ageController = TextEditingController(text: widget.childData['age'].toString());
    selectedLevel = widget.childData['education_level'];
  }

  Future<void> _updateChild() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = box.read('token');
      final childId = widget.childData['id'];

      final response = await http.put(
        Uri.parse('$baseUrl/users/my-children/$childId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'first_name': firstNameController.text,
          'last_name': lastNameController.text,
          'national_id': nationalIdController.text,
          'age': int.parse(ageController.text),
          'education_level': selectedLevel,
        }),
      );

      if (response.statusCode == 200) {
        Get.back(result: true); // العودة مع إشارة للنجاح لتحديث القائمة
        Get.snackbar("نجاح", "تم تحديث بيانات الطفل بنجاح",
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        final error = jsonDecode(response.body);
        Get.snackbar("خطأ", error['message'] ?? "فشل التحديث");
      }
    } catch (e) {
      Get.snackbar("خطأ", "حدث خطأ أثناء الاتصال بالسيرفر");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل بيانات الطفل'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.orangeAccent,
                child: Icon(Icons.edit, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 30),

              _buildTextField(firstNameController, "الاسم الأول", Icons.person),
              const SizedBox(height: 15),
              _buildTextField(lastNameController, "الكنية / اسم العائلة", Icons.family_restroom),
              const SizedBox(height: 15),
              _buildTextField(nationalIdController, "الرقم الوطني", Icons.badge, isNumber: true),
              const SizedBox(height: 15),
              _buildTextField(ageController, "العمر", Icons.cake, isNumber: true),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: selectedLevel,
                decoration: InputDecoration(
                  labelText: "المستوى التعليمي",
                  prefixIcon: const Icon(Icons.school),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
                items: educationLevels.map((level) => DropdownMenuItem(
                  value: level,
                  child: Text(level),
                )).toList(),
                onChanged: (val) => setState(() => selectedLevel = val),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _updateChild,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("حفظ التعديلات", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      validator: (value) => value!.isEmpty ? "هذا الحقل مطلوب" : null,
    );
  }
}