import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../core/api_config.dart';
import 'main_layout.dart'; // الانتقال للـ Layout الأساسي لضمان عمل الأشرطة
import 'parent_registration_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final box = GetStorage();
  bool _isPasswordVisible = false;

  final _emailController = TextEditingController();
  final _parentPasswordController = TextEditingController();
  final _childPasswordController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // لإعادة بناء الواجهة عند تغيير التبويب وتغيير الألوان
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  Future<void> _handleLogin() async {
    // التأكد من الحقول
    if (_tabController.index == 0) {
      if (_emailController.text.isEmpty || _parentPasswordController.text.isEmpty) {
        Get.snackbar("تنبيه", "يرجى إدخال بيانات الأب", snackPosition: SnackPosition.BOTTOM);
        return;
      }
    } else {
      if (_childPasswordController.text.isEmpty || _pinController.text.isEmpty) {
        Get.snackbar("تنبيه", "يرجى إدخال بيانات الطفل", snackPosition: SnackPosition.BOTTOM);
        return;
      }
    }

    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      bool isParentTab = _tabController.index == 0;

      Map<String, dynamic> body = isParentTab
          ? {'email': _emailController.text.trim(), 'password': _parentPasswordController.text}
          : {'password': _childPasswordController.text, 'pin': _pinController.text.trim()};

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(body),
      );

      Get.back();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await box.write('token', data['token']);
        await box.write('user_data', data['user']);

        Get.snackbar("نجاح", "أهلاً بك مجدداً", backgroundColor: Colors.green, colorText: Colors.white);

        // الانتقال لـ MainLayout وليس HomeScreen لضمان عمل الـ Drawer والـ BottomBar
        Get.offAll(() => MainLayout());
      } else {
        Get.snackbar("خطأ", "بيانات الدخول غير صحيحة");
      }
    } catch (e) {
      Get.back();
      Get.snackbar("خطأ", "تعذر الاتصال بالسيرفر");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  _buildCustomTabBar(),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 350,
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildParentForm(), _buildChildForm()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.auto_awesome, size: 70, color: Colors.white),
          SizedBox(height: 15),
          Text('تعلم وامرح', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
          Text('بوابتك نحو المعرفة الذكية', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // التعديل المطلوب: تبويب أنيق مع خط سفلي صغير
  Widget _buildCustomTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.blueAccent,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label, // التعديل لجعل الخط تحت الكلمة فقط
      labelColor: Colors.blueAccent,
      unselectedLabelColor: Colors.grey,
      labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      tabs: const [Tab(text: "حساب الأب"), Tab(text: "دخول الأطفال")],
    );
  }

  Widget _buildParentForm() {
    return Column(
      children: [
        _buildTextField('البريد الإلكتروني', Icons.email_outlined, _emailController),
        const SizedBox(height: 20),
        _buildTextField('كلمة المرور', Icons.lock_outline, _parentPasswordController, isPassword: true),
        const SizedBox(height: 35),
        _buildLoginButton(),
        TextButton(
          onPressed: () => Get.to(() => const ParentRegisterPage()),
          child: const Text('ليس لديك حساب؟ سجل كأب الآن', style: TextStyle(color: Colors.blueGrey)),
        ),
      ],
    );
  }

  Widget _buildChildForm() {
    return Column(
      children: [
        _buildTextField('كلمة مرور الطفل', Icons.child_care, _childPasswordController, isPassword: true),
        const SizedBox(height: 20),
        _buildTextField('رمز الـ PIN', Icons.pin, _pinController, isNumeric: true, maxLength: 4),
        const SizedBox(height: 35),
        _buildLoginButton(),
        const SizedBox(height: 20),
        const Text("رمز الـ PIN يُطلب من الوالد", style: TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller,
      {bool isPassword = false, bool isNumeric = false, int? maxLength}) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        counterText: "",
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        )
            : null,
        filled: true,
        fillColor: Colors.blue.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent, width: 1)),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
        ),
        child: const Text('دخول', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}