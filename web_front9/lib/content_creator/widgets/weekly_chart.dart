import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/dashboard_controller.dart';

class WeeklyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dashboardData = Get.find<DashboardController>().dashboardData.value;

      // 1. الحماية من كون البيانات null أو القائمة فارغة
      final weeklyStats = dashboardData?.weeklyStats ?? [];

      if (weeklyStats.isEmpty) {
        return Center(
          child: Text(
            "لا توجد بيانات لهذا الأسبوع",
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
          ),
        );
      }

      // 2. إيجاد أكبر قيمة مع التأكد أنها ليست صفراً لمنع القسمة على صفر
      double maxCoursesValue = 0;
      for (var e in weeklyStats) {
        if (e.courses > maxCoursesValue) maxCoursesValue = e.courses.toDouble();
      }

      // إذا كانت كل القيم أصفار، نجعل الـ max هو 1 وهمياً لمنع الـ NaN
      final double divisor = maxCoursesValue == 0 ? 1 : maxCoursesValue;

      return Container(
        height: 200.h,
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weeklyStats.map((stat) {
            // حساب الارتفاع بأمان
            final double height = (stat.courses / divisor) * 120.h;

            return Column(
              mainAxisAlignment: MainAxisAlignment.end, // لضمان بقاء الأعمدة في الأسفل
              children: [
                // رسم العمود
                Container(
                  width: 25.w,
                  height: height > 0 ? height : 2.h, // حد أدنى للارتفاع لكي لا يختفي تماماً
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.blue,
                        stat.courses > 0 ? Colors.lightBlue[100]! : Colors.blue.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                SizedBox(height: 8.h),
                // اسم اليوم
                Text(
                  stat.day ?? "",
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                    fontFamily: 'Tajawal',
                  ),
                ),
                SizedBox(height: 4.h),
                // عدد الكورسات (يظهر 0 إذا لم يوجد بيانات)
                Text(
                  '${stat.courses ?? 0}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.black,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    });
  }
}