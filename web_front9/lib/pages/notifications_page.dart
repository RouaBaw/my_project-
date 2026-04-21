import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/notifications_controller.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NotificationsController>()
        ? Get.find<NotificationsController>()
        : Get.put(NotificationsController(), permanent: true);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
          title: Text(
            'الإشعارات',
            style: TextStyle(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              fontSize: 18.sp,
            ),
          ),
          actions: [
            Obx(() {
              final anyUnread = controller.unreadCount.value > 0;
              return TextButton.icon(
                onPressed: anyUnread ? controller.markAllRead : null,
                icon: Icon(
                  Icons.mark_email_read_outlined,
                  size: 18.w,
                  color: anyUnread
                      ? const Color(0xFF6366F1)
                      : Colors.grey,
                ),
                label: Text(
                  'تعليم الكل كمقروء',
                  style: TextStyle(
                    color: anyUnread
                        ? const Color(0xFF6366F1)
                        : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
            SizedBox(width: 8.w),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => controller.fetchAll(),
          child: Obx(() {
            if (controller.isLoading.value && controller.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.items.isEmpty) {
              return _emptyState();
            }

            final groups = _groupByDate(controller.items);

            return ListView(
              padding: EdgeInsets.symmetric(
                  horizontal: 16.w, vertical: 12.h),
              children: [
                for (final entry in groups.entries) ...[
                  _sectionTitle(entry.key),
                  ...entry.value.map(
                    (n) => _NotificationTile(
                      notification: n,
                      onTap: () {
                        controller.markAsRead(n['id']);
                      },
                      onDelete: () => controller.remove(n['id']),
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, right: 4.w, top: 8.h),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13.sp,
          color: const Color(0xFF475569),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64.w,
            color: const Color(0xFFCBD5E1),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد إشعارات حالياً',
            style: TextStyle(
              fontSize: 16.sp,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
      List<Map<String, dynamic>> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 6));

    final map = <String, List<Map<String, dynamic>>>{
      'اليوم': [],
      'هذا الأسبوع': [],
      'الأقدم': [],
    };

    for (final n in items) {
      DateTime? d;
      try {
        final raw = n['created_at'];
        if (raw is String) d = DateTime.parse(raw).toLocal();
      } catch (_) {}
      d ??= now;

      if (!d.isBefore(today)) {
        map['اليوم']!.add(n);
      } else if (!d.isBefore(weekAgo)) {
        map['هذا الأسبوع']!.add(n);
      } else {
        map['الأقدم']!.add(n);
      }
    }

    map.removeWhere((_, v) => v.isEmpty);
    return map;
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _NotificationTile({
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = NotificationsController.dataOf(notification);
    final isUnread = notification['read_at'] == null;
    final title = (data['title_ar'] ?? 'إشعار').toString();
    final body = (data['body_ar'] ?? '').toString();
    final type = (data['type'] ?? '').toString();
    final createdAt = notification['created_at']?.toString();
    DateTime? createdDate;
    try {
      if (createdAt != null) createdDate = DateTime.parse(createdAt).toLocal();
    } catch (_) {}

    final tone = _toneFor(type);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: isUnread ? tone.bg : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isUnread ? tone.border : const Color(0xFFE2E8F0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: tone.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(tone.icon, color: tone.accent, size: 22.w),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: tone.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            color: const Color(0xFF475569),
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (createdDate != null) ...[
                        SizedBox(height: 6.h),
                        Text(
                          DateFormat('d MMM y • HH:mm', 'ar')
                              .format(createdDate),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'حذف',
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18.w,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _Tone _toneFor(String type) {
    if (type.startsWith('path')) return _Tone.blue(Icons.route_outlined);
    if (type.startsWith('course')) return _Tone.indigo(Icons.book_outlined);
    if (type.startsWith('game')) {
      return _Tone.green(Icons.videogame_asset_outlined);
    }
    if (type.startsWith('story')) {
      return _Tone.purple(Icons.auto_stories_outlined);
    }
    if (type.startsWith('user')) {
      return _Tone.amber(Icons.person_add_alt_1_outlined);
    }
    if (type.startsWith('subscription')) {
      return _Tone.teal(Icons.workspace_premium_outlined);
    }
    if (type.startsWith('child')) {
      return _Tone.rose(Icons.child_care_outlined);
    }
    if (type.startsWith('points')) {
      return _Tone.amber(Icons.star_outline);
    }
    if (type.startsWith('reward')) {
      return _Tone.rose(Icons.redeem_outlined);
    }
    return _Tone.indigo(Icons.notifications_outlined);
  }
}

class _Tone {
  final Color accent;
  final Color bg;
  final Color border;
  final IconData icon;
  const _Tone._(this.accent, this.bg, this.border, this.icon);

  factory _Tone.blue(IconData i) => _Tone._(const Color(0xFF3B82F6),
      const Color(0xFFEFF6FF), const Color(0xFFBFDBFE), i);
  factory _Tone.indigo(IconData i) => _Tone._(const Color(0xFF6366F1),
      const Color(0xFFEEF2FF), const Color(0xFFC7D2FE), i);
  factory _Tone.green(IconData i) => _Tone._(const Color(0xFF10B981),
      const Color(0xFFECFDF5), const Color(0xFFA7F3D0), i);
  factory _Tone.purple(IconData i) => _Tone._(const Color(0xFF8B5CF6),
      const Color(0xFFF5F3FF), const Color(0xFFDDD6FE), i);
  factory _Tone.amber(IconData i) => _Tone._(const Color(0xFFF59E0B),
      const Color(0xFFFFFBEB), const Color(0xFFFDE68A), i);
  factory _Tone.teal(IconData i) => _Tone._(const Color(0xFF14B8A6),
      const Color(0xFFF0FDFA), const Color(0xFF99F6E4), i);
  factory _Tone.rose(IconData i) => _Tone._(const Color(0xFFF43F5E),
      const Color(0xFFFFF1F2), const Color(0xFFFECDD3), i);
}
