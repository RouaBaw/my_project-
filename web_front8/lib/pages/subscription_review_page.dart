import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class SubscriptionReviewPage extends StatefulWidget {
  const SubscriptionReviewPage({super.key});

  @override
  State<SubscriptionReviewPage> createState() => _SubscriptionReviewPageState();
}

class _SubscriptionReviewPageState extends State<SubscriptionReviewPage> {
  static const List<String> _statusFilters = [
    'all',
    'pending',
    'active',
    'rejected',
    'cancelled',
    'expired',
  ];

  List<dynamic> items = [];
  dynamic selectedItem;
  bool isLoading = true;
  bool isUpdating = false;
  String? loadError;
  String selectedStatusFilter = 'all';

  List<dynamic> get filteredItems => _applyStatusFilter(items);

  String get baseUrl {
    if (kIsWeb && Uri.base.host.isNotEmpty) {
      return '${Uri.base.scheme}://${Uri.base.host}:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  List<dynamic> _applyStatusFilter(List<dynamic> source) {
    if (selectedStatusFilter == 'all') {
      return List<dynamic>.from(source);
    }
    return source.where((item) => _statusValue(item) == selectedStatusFilter).toList();
  }

  dynamic _resolveSelectedItem(List<dynamic> source, {dynamic preferredItem}) {
    final visibleItems = _applyStatusFilter(source);
    if (visibleItems.isEmpty) {
      return null;
    }

    final preferredId = preferredItem?['id'];
    for (final item in visibleItems) {
      if (item['id'] == preferredId) {
        return item;
      }
    }

    return visibleItems.first;
  }

  String _statusValue(dynamic item) {
    return (item?['status'] ?? 'pending').toString();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'active':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'cancelled':
        return 'ملغي';
      case 'expired':
        return 'منتهي';
      default:
        return 'الكل';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'active':
        return const Color(0xFF15803D);
      case 'rejected':
        return const Color(0xFFB91C1C);
      case 'cancelled':
        return const Color(0xFF475569);
      case 'expired':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _billingCycleLabel(String cycle) {
    if (cycle.isEmpty) {
      return 'غير محدد';
    }
    return cycle == 'yearly' ? 'سنوية' : 'شهرية';
  }

  String _formatDate(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty) {
      return 'غير محدد';
    }

    return text.replaceFirst('T', ' ').split('.').first;
  }

  String _emptyStateMessage() {
    if (selectedStatusFilter == 'all') {
      return 'لا توجد اشتراكات حالياً';
    }

    return 'لا توجد اشتراكات بحالة ${_statusLabel(selectedStatusFilter)}';
  }

  void _changeFilter(String status) {
    setState(() {
      selectedStatusFilter = status;
      selectedItem = _resolveSelectedItem(items, preferredItem: selectedItem);
    });
  }

  Widget _buildStatusChip(String status, {bool compact = false}) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: compact ? 12 : 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _fetchQueue() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final token = GetStorage().read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/child-subscriptions/review-queue'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final queue = decoded['data'] ?? [];
        setState(() {
          items = queue;
          selectedItem = _resolveSelectedItem(queue, preferredItem: selectedItem);
          isLoading = false;
        });
      } else {
        setState(() {
          loadError = 'تعذر تحميل طلبات الاشتراك';
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

  Future<void> _review(int id, String status) async {
    setState(() => isUpdating = true);
    try {
      final token = GetStorage().read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/child-subscriptions/$id/review'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        await _fetchQueue();
        Get.snackbar(
          'تم',
          status == 'active' ? 'تم قبول الاشتراك' : 'تم رفض الاشتراك',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar('خطأ', 'فشل تحديث حالة الاشتراك', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (_) {
      Get.snackbar('خطأ', 'فشل الاتصال بالسيرفر', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchQueue();
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = filteredItems;
    final selectedStatus = selectedItem == null ? '' : _statusValue(selectedItem);
    final canReviewSelected = selectedStatus == 'pending';
    final plan = selectedItem?['plan'] ?? {};

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'إدارة الاشتراكات',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              onPressed: isLoading ? null : _fetchQueue,
                              tooltip: 'تحديث',
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _statusFilters.map((status) {
                              final selected = selectedStatusFilter == status;
                              return ChoiceChip(
                                label: Text(_statusLabel(status)),
                                selected: selected,
                                onSelected: (_) => _changeFilter(status),
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : _statusColor(status),
                                  fontWeight: FontWeight.w700,
                                ),
                                backgroundColor: _statusColor(status).withOpacity(0.1),
                                selectedColor: _statusColor(status),
                                side: BorderSide(color: _statusColor(status).withOpacity(0.2)),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : loadError != null
                                ? Center(child: Text(loadError!))
                                : visibleItems.isEmpty
                                    ? Center(child: Text(_emptyStateMessage()))
                                    : ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                        itemCount: visibleItems.length,
                                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          final item = visibleItems[index];
                                          final selected = selectedItem?['id'] == item['id'];
                                          final child = item['child'] ?? {};
                                          final itemPlan = item['plan'] ?? {};
                                          final itemStatus = _statusValue(item);
                                          return InkWell(
                                            borderRadius: BorderRadius.circular(18),
                                            onTap: () => setState(() => selectedItem = item),
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(18),
                                                border: Border.all(
                                                  color: selected ? const Color(0xFF60A5FA) : const Color(0xFFE2E8F0),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          '${child['first_name'] ?? ''} ${child['last_name'] ?? ''}'.trim(),
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                        ),
                                                      ),
                                                      _buildStatusChip(itemStatus, compact: true),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text((itemPlan['name'] ?? '').toString()),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'السعر: ${itemPlan['price'] ?? ''}',
                                                    style: TextStyle(color: Colors.grey.shade700),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: selectedItem == null
                      ? Center(child: Text(_emptyStateMessage()))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'اشتراك الطفل ${selectedItem['child']?['first_name'] ?? ''}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        _buildStatusChip(selectedStatus),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ولي الأمر: ${(selectedItem['parent']?['first_name'] ?? '')} ${(selectedItem['parent']?['last_name'] ?? '')}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'رقم الطلب: ${selectedItem['id']}',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _InfoCard(label: 'الخطة', value: '${plan['name'] ?? ''}'),
                                  _InfoCard(label: 'السعر', value: '${plan['price'] ?? ''}'),
                                  _InfoCard(
                                    label: 'الدورة',
                                    value: _billingCycleLabel((plan['billing_cycle'] ?? '').toString()),
                                  ),
                                  _InfoCard(label: 'تاريخ البدء', value: _formatDate(selectedItem['starts_at'])),
                                  _InfoCard(label: 'تاريخ الانتهاء', value: _formatDate(selectedItem['ends_at'])),
                                  _InfoCard(label: 'تاريخ المراجعة', value: _formatDate(selectedItem['reviewed_at'])),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if ((selectedItem['notes'] ?? '').toString().trim().isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text('ملاحظات: ${selectedItem['notes']}'),
                                ),
                              const SizedBox(height: 16),
                              if ((selectedItem['receipt_url'] ?? '').toString().isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.network(
                                    selectedItem['receipt_url'],
                                    height: 320,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 120,
                                      alignment: Alignment.center,
                                      color: const Color(0xFFF8FAFC),
                                      child: const Text('تعذر عرض إشعار الدفع'),
                                    ),
                                  ),
                                ),
                              if (canReviewSelected) ...[
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: isUpdating ? null : () => _review(selectedItem['id'], 'active'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF16A34A),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        icon: const Icon(Icons.check_circle_outline),
                                        label: const Text('قبول الاشتراك'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: isUpdating ? null : () => _review(selectedItem['id'], 'rejected'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFB91C1C),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        icon: const Icon(Icons.close),
                                        label: const Text('رفض الاشتراك'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.isEmpty ? 'غير محدد' : value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
