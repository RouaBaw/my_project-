import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:untitled1/screens/add_child_page.dart';
import 'package:untitled1/screens/edit_child_page.dart';
import '../core/api_config.dart';

class ChildrenManagementPage extends StatefulWidget {
  const ChildrenManagementPage({super.key});

  @override
  State<ChildrenManagementPage> createState() => _ChildrenManagementPageState();
}

class _ChildrenManagementPageState extends State<ChildrenManagementPage> {
  final box = GetStorage();
  List children = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  // 1. جلب قائمة الأبناء من السيرفر
  Future<void> _fetchChildren() async {
    setState(() => isLoading = true);
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = box.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/users/my-children'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          children = responseData['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        Get.snackbar("خطأ", "فشل السيرفر في جلب البيانات");
      }
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar("خطأ", "حدث خطأ أثناء الاتصال بالسيرفر");
    }
  }

  // 2. جلب نتائج اختبارات طفل محدد
  Future<Map<String, dynamic>?> _fetchChildResults(int childId) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/child/$childId/results'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Error fetching results: $e");
    }
    return null;
  }

  // 3. حذف حساب ابن
  Future<void> _deleteChild(int id) async {
    Get.dialog(const Center(child: CircularProgressIndicator(color: Colors.redAccent)), barrierDismissible: false);
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = box.read('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/users/my-children/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      Get.back(); // إغلاق لودينج الحذف

      if (response.statusCode == 200) {
        _fetchChildren();
        Get.snackbar("نجاح", "تم حذف الحساب بنجاح", backgroundColor: Colors.green, colorText: Colors.white);
      }
    } catch (e) {
      Get.back();
      Get.snackbar("خطأ", "فشل الاتصال أثناء عملية الحذف");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('إدارة الأبناء',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3142)),
      ),

      // --- زر الإضافة المحسن بتدرج لوني ---
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4361EE).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Get.to(() => const AddChildPage());
            _fetchChildren();
          },
          label: const Text("إضافة طفل جديد",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4361EE)))
          : children.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _fetchChildren,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          itemCount: children.length,
          itemBuilder: (context, index) => _buildEnhancedChildCard(children[index]),
        ),
      ),
    );
  }

  // --- تصميم بطاقة الطفل القابلة للضغط ---
  Widget _buildEnhancedChildCard(dynamic child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showResultsSheet(child), // النقر على الكارد يفتح الإحصائيات
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.blue.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.face_retouching_natural_rounded, size: 35, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${child['first_name']} ${child['last_name']}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                      ),
                      const SizedBox(height: 4),
                      Text("ID: ${child['national_id']}", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: Text(
                          "رمز PIN: ${child['pin']}",
                          style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSmallActionBtn(Icons.edit_note_rounded, Colors.orange, () async {
                      final result = await Get.to(() => EditChildPage(childData: child));
                      if (result == true) _fetchChildren();
                    }),
                    const SizedBox(height: 10),
                    _buildSmallActionBtn(Icons.delete_outline_rounded, Colors.redAccent, () => _confirmDelete(child)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  // --- عرض الإحصائيات (Sheet) ---
  void _showResultsSheet(dynamic child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: FutureBuilder(
            future: _fetchChildResults(child['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());

              final data = snapshot.data;
              final results = (data != null && data['data'] != null) ? data['data'] as List : [];

              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 20),
                    Text("إحصائيات ${child['first_name']}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 25),

                    Row(
                      children: [
                        _buildSummaryCard("المتوسط", "${data?['averageScore'] ?? 0}%", Colors.orange),
                        const SizedBox(width: 16),
                        _buildSummaryCard("المكتملة", "${data?['completedCourses'] ?? 0}", Colors.green),
                      ],
                    ),
                    const SizedBox(height: 30),

                    if (results.isNotEmpty) ...[
                      const Align(alignment: Alignment.centerRight, child: Text("منحنى التطور", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                      const SizedBox(height: 20),
                      SizedBox(height: 180, child: _buildLineChart(results)),
                    ],

                    const SizedBox(height: 30),
                    const Align(alignment: Alignment.centerRight, child: Text("سجل النشاط", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    const SizedBox(height: 10),
                    ...results.map((res) => _buildResultItem(res)).toList(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(dynamic res) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const Icon(Icons.stars_rounded, color: Color(0xFF4361EE)),
        title: Text(res['learning_content']['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text("${res['score']}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4361EE))),
      ),
    );
  }

  Widget _buildLineChart(List results) {
    List graphData = results.reversed.toList();
    if (graphData.length > 6) graphData = graphData.sublist(graphData.length - 6);

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: graphData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), double.parse(e.value['score'].toString()))).toList(),
            isCurved: true,
            color: const Color(0xFF4361EE),
            barWidth: 5,
            belowBarData: BarAreaData(show: true, color: const Color(0xFF4361EE).withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text("لا يوجد أطفال مضافين حالياً", style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmDelete(dynamic child) {
    Get.defaultDialog(
      title: "تأكيد الحذف",
      middleText: "هل أنت متأكد من حذف حساب ${child['first_name']}؟",
      textConfirm: "حذف",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        _deleteChild(child['id']);
      },
    );
  }
}