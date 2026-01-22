import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../core/api_config.dart';

class AddChildPage extends StatefulWidget {
  const AddChildPage({super.key});

  @override
  State<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends State<AddChildPage> {
  final box = GetStorage();
  final _formKey = GlobalKey<FormState>();

  // وحدات التحكم بالمدخلات
  final _firstNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _ageController = TextEditingController();
  final _pinController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _addChild() async {
    if (!_formKey.currentState!.validate()) return;

    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF4361EE))),
      barrierDismissible: false,
    );

    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = box.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'first_name': _firstNameController.text,
          'father_name': _fatherNameController.text,
          'last_name': _lastNameController.text,
          'mother_name': _motherNameController.text,
          'national_id': _nationalIdController.text,
          'age': int.tryParse(_ageController.text),
          'user_type': 'child',
          'password': _passwordController.text,
          'pin': _pinController.text.isEmpty ? null : _pinController.text,
          'education_level': 'Primary',
        }),
      ).timeout(const Duration(seconds: 10));

      Get.back();

      if (response.statusCode == 201) {
        Get.back(result: true);
        _showSnackbar("نجاح", "تم إنشاء حساب الطفل بنجاح", isError: false);
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackbar("خطأ", errorData['message'] ?? "فشل الإنشاء", isError: true);
      }
    } catch (e) {
      Get.back();
      _showSnackbar("خطأ اتصال", "تعذر الوصول للسيرفر", isError: true);
    }
  }

  void _showSnackbar(String title, String message, {required bool isError}) {
    Get.snackbar(title, message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError ? Colors.redAccent.withOpacity(0.9) : Colors.green.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(15),
      borderRadius: 15,
      icon: Icon(isError ? Icons.error : Icons.check_circle, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('إضافة طفل جديد', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF2D3142),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 25),

              _buildSectionHeader("المعلومات الأساسية", Icons.face_rounded),
              _buildInputCard([
                _buildModernField("الاسم الأول", Icons.person, _firstNameController),
                _buildModernField("اسم الأب", Icons.person_outline, _fatherNameController),
                _buildModernField("اسم الأم (اختياري)", Icons.woman_rounded, _motherNameController, isRequired: false),
                _buildModernField("الكنية / العائلة", Icons.family_restroom, _lastNameController),
              ]),

              const SizedBox(height: 25),

              _buildSectionHeader("بيانات الحساب", Icons.security_rounded),
              _buildInputCard([
                _buildModernField("الرقم الوطني", Icons.badge_outlined, _nationalIdController, type: TextInputType.number),
                _buildModernField("العمر", Icons.cake_outlined, _ageController, type: TextInputType.number),
                _buildModernField("كلمة المرور", Icons.lock_open_rounded, _passwordController, isPassword: true),
                _buildModernField("رمز PIN", Icons.pin_rounded, _pinController, type: TextInputType.number, isPassword: true, isRequired: false),
              ]),

              const SizedBox(height: 40),

              _buildSubmitButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4361EE), Color(0xFF4CC9F0)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.child_care_rounded, size: 50, color: Colors.white),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ملف تعريف جديد", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("قم بإنشاء حساب خاص بطفلك لمتابعة تقدمه الدراسي", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 5),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4361EE)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        ],
      ),
    );
  }

  Widget _buildInputCard(List<Widget> fields) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(children: fields.expand((f) => [f, const SizedBox(height: 15)]).toList()..removeLast()),
    );
  }

  Widget _buildModernField(String label, IconData icon, TextEditingController controller, {TextInputType type = TextInputType.text, bool isPassword = false, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: isPassword,
      validator: isRequired ? (value) => value!.isEmpty ? "هذا الحقل مطلوب" : null : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22, color: const Color(0xFF4361EE).withOpacity(0.7)),
        filled: true,
        fillColor: const Color(0xFFF8F9FE),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF4361EE), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)]),
        boxShadow: [
          BoxShadow(color: const Color(0xFF4361EE).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _addChild,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: const Text("إنشاء الحساب الآن", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}