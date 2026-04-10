import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:untitled1/core/api_config.dart';

class ChildSubscriptionPage extends StatefulWidget {
  final Map<String, dynamic> child;

  const ChildSubscriptionPage({
    super.key,
    required this.child,
  });

  @override
  State<ChildSubscriptionPage> createState() => _ChildSubscriptionPageState();
}

class _ChildSubscriptionPageState extends State<ChildSubscriptionPage> {
  final box = GetStorage();
  final TextEditingController notesController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  List<dynamic> plans = [];
  List<dynamic> subscriptions = [];
  dynamic selectedPlan;
  XFile? receiptFile;
  bool isLoading = true;
  bool isSubmitting = false;
  String? loadError;

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = box.read('token');

      final responses = await Future.wait([
        http.get(
          Uri.parse('$baseUrl/subscription-plans'),
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
        ),
        http.get(
          Uri.parse('$baseUrl/children/${widget.child['id']}/subscriptions'),
          headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
        ),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final plansDecoded = jsonDecode(responses[0].body);
        final subscriptionsDecoded = jsonDecode(responses[1].body);
        setState(() {
          plans = plansDecoded['data'] ?? [];
          subscriptions = subscriptionsDecoded['data'] ?? [];
          if (plans.isNotEmpty && selectedPlan == null) {
            selectedPlan = plans.first;
          }
          isLoading = false;
        });
      } else {
        setState(() {
          loadError = 'تعذر تحميل بيانات الاشتراك';
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        loadError = 'فشل الاتصال بالسيرفر';
        isLoading = false;
      });
    }
  }

  dynamic get latestSubscription => subscriptions.isNotEmpty ? subscriptions.first : null;

  Future<void> _pickReceipt() async {
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() => receiptFile = picked);
    }
  }

  Future<void> _submitSubscription() async {
    if (selectedPlan == null || receiptFile == null) {
      Get.snackbar(
        'تنبيه',
        'اختر الخطة وارفع إشعار الدفع أولًا',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = box.read('token');
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/child-subscriptions'));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['child_id'] = widget.child['id'].toString();
      request.fields['subscription_plan_id'] = selectedPlan['id'].toString();
      request.fields['notes'] = notesController.text.trim();
      request.files.add(await http.MultipartFile.fromPath('payment_receipt', receiptFile!.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201 || response.statusCode == 200) {
        notesController.clear();
        setState(() => receiptFile = null);
        await _loadData();
        Get.snackbar(
          'نجاح',
          'تم إرسال طلب الاشتراك وبانتظار المراجعة',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        final body = response.body.isNotEmpty ? response.body : 'فشل إرسال الطلب';
        Get.snackbar(
          'خطأ',
          body,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'خطأ',
        'تعذر الاتصال بالسيرفر',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _cancelSubscription(int id) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = box.read('token');
      final response = await http.patch(
        Uri.parse('$baseUrl/child-subscriptions/$id/cancel'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        await _loadData();
        Get.snackbar(
          'تم',
          'تم إلغاء الاشتراك بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'خطأ',
          'تعذر إلغاء الاشتراك',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'خطأ',
        'فشل الاتصال بالسيرفر',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'pending':
        return 'بانتظار المراجعة';
      case 'rejected':
        return 'مرفوض';
      case 'cancelled':
        return 'ملغي';
      case 'expired':
        return 'منتهي';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF16A34A);
      case 'pending':
        return const Color(0xFF2563EB);
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'cancelled':
        return const Color(0xFF7C3AED);
      case 'expired':
        return const Color(0xFF92400E);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: Text('اشتراك ${widget.child['first_name']}'),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : loadError != null
                ? Center(child: Text(loadError!))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 18),
                      if (latestSubscription != null) _buildCurrentSubscriptionCard(latestSubscription),
                      const SizedBox(height: 18),
                      _buildPlansSection(),
                      const SizedBox(height: 18),
                      _buildReceiptSection(),
                      const SizedBox(height: 18),
                      _buildHistorySection(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نظام اشتراك الطفل',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'اختر الخطة المناسبة لهذا الطفل ثم ارفع إشعار الدفع ليتم مراجعته من الإدارة.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard(dynamic subscription) {
    final plan = subscription['plan'] ?? {};
    final status = (subscription['status'] ?? '').toString();
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'آخر حالة اشتراك',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${plan['name'] ?? 'خطة غير معروفة'}'),
          const SizedBox(height: 6),
          Text(
            'الفترة: ${plan['billing_cycle'] == 'yearly' ? 'سنوي' : 'شهري'}',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          if (subscription['ends_at'] != null) ...[
            const SizedBox(height: 6),
            Text(
              'ينتهي في: ${subscription['ends_at']}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
          const SizedBox(height: 12),
          if (status == 'active' || status == 'pending')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelSubscription(subscription['id']),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('إلغاء هذا الاشتراك'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر خطة الاشتراك',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ...plans.map((plan) {
            final selected = selectedPlan?['id'] == plan['id'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? const Color(0xFF60A5FA) : const Color(0xFFE2E8F0),
                ),
              ),
              child: ListTile(
                onTap: () {
                  setState(() {
                    selectedPlan = plan;
                  });
                },
                leading: Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? const Color(0xFF2563EB) : Colors.grey,
                ),
                title: Text(
                  (plan['name'] ?? '').toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${plan['billing_cycle'] == 'yearly' ? 'سنوي' : 'شهري'} - ${plan['price']}',
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReceiptSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إشعار الدفع',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'ارفع صورة إشعار الدفع ليتم تثبيت الاشتراك بعد المراجعة.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickReceipt,
            icon: const Icon(Icons.upload_file),
            label: Text(receiptFile == null ? 'رفع إشعار الدفع' : 'تغيير الإشعار'),
          ),
          if (receiptFile != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(receiptFile!.path),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'ملاحظات إضافية (اختياري)',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submitSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text(
                      'إرسال طلب الاشتراك',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'سجل الاشتراكات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          if (subscriptions.isEmpty)
            const Text('لا توجد طلبات اشتراك سابقة لهذا الطفل')
          else
            ...subscriptions.map((subscription) {
              final plan = subscription['plan'] ?? {};
              final status = (subscription['status'] ?? '').toString();
              final color = _statusColor(status);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (plan['name'] ?? '').toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          _statusLabel(status),
                          style: TextStyle(color: color, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('السعر: ${plan['price']}'),
                    if (subscription['created_at'] != null)
                      Text('تاريخ الطلب: ${subscription['created_at']}'),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
