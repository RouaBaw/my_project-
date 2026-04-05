import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import 'parent_dashboard_page.dart';
import 'login_page.dart';

class ParentRegisterPage extends StatefulWidget {
  const ParentRegisterPage({super.key});

  @override
  State<ParentRegisterPage> createState() => _ParentRegisterPageState();
}

class _ParentRegisterPageState extends State<ParentRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // وحدات التحكم
  final _firstNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    Get.dialog(const Center(child: CircularProgressIndicator(color: Color(0xFF4361EE))), barrierDismissible: false);

    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'first_name': _firstNameController.text,
          'father_name': _fatherNameController.text,
          'last_name': _lastNameController.text,
          'national_id': _nationalIdController.text,
          'age': int.tryParse(_ageController.text) ?? 0,
          'user_type': 'parent',
          'email': _emailController.text,
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
          'phone_number': _phoneController.text,
          'is_mobile': 1,
          'education_level': 'جامعي',
        }),
      ).timeout(const Duration(seconds: 10));

      Get.back();
      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSnackbar("نجاح", "أهلاً بك في عائلتنا الذكية", isError: false);
        Get.offAll(() => LoginPage());
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackbar("خطأ", errorData['message'] ?? "تأكد من البيانات", isError: true);
      }
    } catch (e) {
      Get.back();
      _showSnackbar("خطأ", "تعذر الاتصال بالسيرفر", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String title, String message, {required bool isError}) {
    Get.snackbar(title, message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        colorText: Colors.white,
        borderRadius: 15,
        margin: const EdgeInsets.all(15),
        icon: Icon(isError ? Icons.error : Icons.check_circle, color: Colors.white));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSectionTitle("المعلومات الشخصية", Icons.person_rounded),
                    _buildInputCard([
                      _buildField("الاسم الأول", Icons.person, _firstNameController),
                      _buildField("اسم الأب", Icons.person_outline, _fatherNameController),
                      _buildField("الكنية", Icons.family_restroom, _lastNameController),
                      _buildField("العمر", Icons.cake, _ageController, keyboardType: TextInputType.number),
                    ]),
                    const SizedBox(height: 25),
                    _buildSectionTitle("بيانات التواصل والهوية", Icons.contact_mail_rounded),
                    _buildInputCard([
                      _buildField("الرقم الوطني", Icons.badge, _nationalIdController, keyboardType: TextInputType.number),
                      _buildField("رقم الهاتف", Icons.phone_android, _phoneController, keyboardType: TextInputType.phone),
                      _buildField("البريد الإلكتروني", Icons.alternate_email, _emailController, keyboardType: TextInputType.emailAddress),
                    ]),
                    const SizedBox(height: 25),
                    _buildSectionTitle("الأمان", Icons.lock_rounded),
                    _buildInputCard([
                      _buildField("كلمة المرور", Icons.lock_outline, _passwordController, isPassword: true),
                      _buildField("تأكيد كلمة المرور", Icons.lock_reset, _confirmPasswordController, isPassword: true, isConfirm: true),
                    ]),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                    _buildLoginLink(),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF4361EE),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text("إنشاء حساب جديد", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4361EE), Color(0xFF4CC9F0)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Opacity(
            opacity: 0.2,
            child: Icon(Icons.family_restroom, size: 150, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4361EE)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        ],
      ),
    );
  }

  Widget _buildInputCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(children: children.expand((w) => [w, const SizedBox(height: 16)]).toList()..removeLast()),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController controller,
      {bool isPassword = false, bool isConfirm = false, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) return "هذا الحقل مطلوب";
        if (isConfirm && value != _passwordController.text) return "كلمات المرور غير متطابقة";
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22, color: const Color(0xFF4361EE).withOpacity(0.6)),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ) : null,
        filled: true,
        fillColor: const Color(0xFFF8F9FE),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF4361EE))),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF4361EE), Color(0xFF3F37C9)]),
        boxShadow: [BoxShadow(color: const Color(0xFF4361EE).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: const Text("إنشاء الحساب والبدء", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLoginLink() {
    return TextButton(
      onPressed: () => Get.to(() => const LoginPage()),
      child: RichText(
        text: TextSpan(
          text: "لديك حساب بالفعل؟ ",
          style: const TextStyle(color: Colors.grey),
          children: [
            TextSpan(text: "سجل دخولك", style: TextStyle(color: const Color(0xFF4361EE), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}