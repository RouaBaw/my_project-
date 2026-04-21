import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controllers/notifications_controller.dart';
import '../pages/notifications_page.dart';

/// Standalone bell with an unread badge.
///
/// Relies on the [NotificationsController] being registered globally
/// (see `main.dart` `Get.put(NotificationsController(), permanent: true)`).
class NotificationBell extends StatelessWidget {
  final Color iconColor;
  final double iconSize;

  const NotificationBell({
    Key? key,
    this.iconColor = const Color(0xFF334155),
    this.iconSize = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final NotificationsController controller =
        Get.isRegistered<NotificationsController>()
            ? Get.find<NotificationsController>()
            : Get.put(NotificationsController(), permanent: true);

    return Obx(() {
      final count = controller.unreadCount.value;
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                controller.fetchAll();
                Get.to(() => const NotificationsPage());
              },
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Icon(
                  Icons.notifications_outlined,
                  size: iconSize.w,
                  color: iconColor,
                ),
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              top: 2.h,
              right: 2.w,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.w,
                  vertical: 2.h,
                ),
                constraints: BoxConstraints(
                  minWidth: 18.w,
                  minHeight: 18.w,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
