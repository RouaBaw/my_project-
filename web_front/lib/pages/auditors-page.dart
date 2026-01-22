import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';

class AuditorsPage extends StatefulWidget {
  @override
  _AuditorsPageState createState() => _AuditorsPageState();
}

class _AuditorsPageState extends State<AuditorsPage> {
  final String apiUrl = 'http://127.0.0.1:8000/api/users/auditors';
  final String registerUrl = 'http://127.0.0.1:8000/api/register';
  final _storage = GetStorage();

  List<dynamic> auditors = [];
  bool isLoading = true;
  bool _isSaving = false;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final fatherNameController = TextEditingController();
  final nationalIdController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();
  final educationLevelController = TextEditingController();

  File? _imageFile;
  Uint8List? _webImage;

  @override
  void initState() {
    super.initState();
    fetchAuditors();
  }

  Future<void> fetchAuditors() async {
    try {
      String? token = _storage.read('token');
      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      if (response.statusCode == 200) {
        setState(() {
          auditors = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _isSaving = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse(registerUrl));
      request.fields.addAll({
        'first_name': firstNameController.text,
        'father_name': fatherNameController.text,
        'last_name': lastNameController.text,
        'national_id': nationalIdController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'phone_number': phoneController.text,
        'age': ageController.text,
        'education_level': educationLevelController.text,
        'user_type': 'content_auditor',
      });

      if (kIsWeb && _webImage != null) {
        request.files.add(http.MultipartFile.fromBytes('image_file', _webImage!, filename: 'profile.png'));
      } else if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image_file', _imageFile!.path));
      }

      var response = await request.send();
      if (response.statusCode == 201) {
        Get.back();
        Get.snackbar('نجاح', 'تمت إضافة المراقب بنجاح', backgroundColor: Colors.green, colorText: Colors.white);
        _clearControllers();
        fetchAuditors();
      } else {
        Get.snackbar('خطأ', 'فشل في الإضافة', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ في الاتصال', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _clearControllers() {
    firstNameController.clear();
    lastNameController.clear();
    fatherNameController.clear();
    nationalIdController.clear();
    emailController.clear();
    passwordController.clear();
    phoneController.clear();
    ageController.clear();
    educationLevelController.clear();
    _webImage = null;
    _imageFile = null;
  }

  // --- مودال عرض تفاصيل الحساب بشكل جميل وعصري ---
  void _showDetailsModal(Map<String, dynamic> user) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        elevation: 10,
        child: Container(
          width: 800.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ترويسة التصميم - صورة المستخدم ومعلوماته الأساسية
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 120.h,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF805AD5), Color(0xFF3182CE)]),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    ),
                  ),
                  Positioned(
                    top: 60.h,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 50.r,
                        backgroundColor: Colors.grey[100],
                        backgroundImage: (user['image_url'] != null) ? NetworkImage(user['image_url']) : null,
                        child: (user['image_url'] == null) ? Icon(Icons.person, size: 50.r, color: Colors.grey) : null,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 60.h),
              Text("${user['first_name']} ${user['last_name']}", style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
              Text("مراقب محتوى معتمد", style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
              SizedBox(height: 20.h),
              const Divider(),
              // شبكة البيانات
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 20.h),
                child: Wrap(
                  spacing: 40.w,
                  runSpacing: 20.h,
                  children: [
                    _detailItem('الاسم الكامل', '${user['first_name']} ${user['father_name'] ?? ''} ${user['last_name']}', Icons.person_outline),
                    _detailItem('البريد الإلكتروني', user['email'], Icons.email_outlined),
                    _detailItem('الرقم الوطني', user['national_id'] ?? '---', Icons.badge_outlined),
                    _detailItem('رقم الهاتف', user['phone_number'] ?? '---', Icons.phone_android),
                    _detailItem('العمر', '${user['age']} عاماً', Icons.cake_outlined),
                    _detailItem('المستوى التعليمي', user['education_level'] ?? '---', Icons.school_outlined),
                    _detailItem('حالة الحساب', user['account_status'] == 'pending' ? 'قيد الانتظار' : 'نشط', Icons.info_outline),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.w),
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black87),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String label, String value, IconData icon) {
    return SizedBox(
      width: 320.w,
      child: Row(
        children: [
          Icon(icon, size: 22.w, color: Colors.blue[600]),
          SizedBox(width: 15.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12.sp)),
              Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // --- مودال الإضافة (كما هو سابقاً) ---
  void _showAddAuditorModal() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              width: 900.w,
              padding: EdgeInsets.all(30.w),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('إضافة مراقب محتوى جديد', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.purple[900])),
                    SizedBox(height: 30.h),
                    Row(
                      children: [
                        Expanded(child: _modalTextField('الاسم الأول', firstNameController, Icons.person_outline)),
                        SizedBox(width: 15.w),
                        Expanded(child: _modalTextField('اسم الأب', fatherNameController, Icons.person_pin)),
                        SizedBox(width: 15.w),
                        Expanded(child: _modalTextField('الكنية', lastNameController, Icons.family_restroom)),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(child: _modalTextField('الرقم الوطني', nationalIdController, Icons.badge_outlined)),
                        SizedBox(width: 15.w),
                        Expanded(child: _modalTextField('البريد الإلكتروني', emailController, Icons.email_outlined)),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(child: _modalTextField('كلمة المرور', passwordController, Icons.lock_outline, isPass: true)),
                        SizedBox(width: 15.w),
                        Expanded(child: _modalTextField('رقم الهاتف', phoneController, Icons.phone_android)),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(child: _modalTextField('العمر', ageController, Icons.cake, kType: TextInputType.number)),
                        SizedBox(width: 15.w),
                        Expanded(child: _modalTextField('المستوى التعليمي', educationLevelController, Icons.school)),
                      ],
                    ),
                    SizedBox(height: 30.h),
                    _buildImageSection(setModalState),
                    SizedBox(height: 40.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
                        SizedBox(width: 20.w),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 15.h)),
                          child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('إضافة الحساب', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _modalTextField(String label, TextEditingController controller, IconData icon, {bool isPass = false, TextInputType kType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: isPass,
          keyboardType: kType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.purple, size: 20.sp),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الصورة الشخصية (اختياري)', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 10.h),
        InkWell(
          onTap: () async {
            final img = await ImagePicker().pickImage(source: ImageSource.gallery);
            if (img != null) {
              if (kIsWeb) {
                var bytes = await img.readAsBytes();
                setModalState(() => _webImage = bytes);
              } else {
                setModalState(() => _imageFile = File(img.path));
              }
            }
          },
          child: Container(
            height: 100.h, width: double.infinity,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10.r)),
            child: _webImage != null || _imageFile != null
                ? ClipRRect(borderRadius: BorderRadius.circular(10.r), child: kIsWeb ? Image.memory(_webImage!, fit: BoxFit.contain) : Image.file(_imageFile!, fit: BoxFit.contain))
                : Icon(Icons.add_a_photo, color: Colors.purple[200]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: EdgeInsets.all(30.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUpperHeader(),
            SizedBox(height: 30.h),
            _buildStatsRow(),
            SizedBox(height: 40.h),
            _buildListTitleRow(),
            SizedBox(height: 20.h),
            Expanded(
              child: isLoading ? const Center(child: CircularProgressIndicator()) : _buildDataTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpperHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مراقبي المحتوى', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold)),
            Text('إدارة حسابات مراقبة المنصة بالكامل', style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
          ],
        ),
        const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.admin_panel_settings, color: Colors.white)),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statBox('${auditors.length}', 'مراقب محتوى', Colors.blue[50]!, Colors.blue),
        SizedBox(width: 20.w),
        _statBox('2', 'أولياء أمور', Colors.green[50]!, Colors.green),
        SizedBox(width: 20.w),
        _statBox('1', 'أطفال', Colors.orange[50]!, Colors.orange),
      ],
    );
  }

  Widget _statBox(String val, String label, Color bg, Color iconColor) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15.r)),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: iconColor, radius: 20.r, child: const Icon(Icons.show_chart, color: Colors.white, size: 16)),
            SizedBox(width: 15.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(val, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: Colors.black54)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildListTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('قائمة حسابات المراقبين', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
        ElevatedButton.icon(
          onPressed: _showAddAuditorModal,
          icon: const Icon(Icons.add),
          label: const Text('إضافة حساب جديد'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
        )
      ],
    );
  }

  Widget _buildDataTable() {
    if (auditors.isEmpty) return const Center(child: Text("لا توجد بيانات"));
    return ListView.builder(
      itemCount: auditors.length,
      itemBuilder: (context, index) {
        final user = auditors[index];
        String? imageUrl = user['image_url'];

        return Card(
          margin: EdgeInsets.only(bottom: 15.h),
          elevation: 0.5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: CircleAvatar(
              radius: 25.r,
              backgroundColor: Colors.purple[50],
              backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
              child: (imageUrl == null || imageUrl.isEmpty) ? Icon(Icons.person, color: Colors.purple, size: 25.sp) : null,
            ),
            title: Text("${user['first_name']} ${user['last_name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user['email'] ?? ''),
            trailing: ElevatedButton(
              onPressed: () => _showDetailsModal(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: Colors.blue[700],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: const Text('عرض التفاصيل'),
            ),
          ),
        );
      },
    );
  }
}