import './weekly_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/user_controller.dart';

class DashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final DashboardController dashboardController = Get.find();
    final UserController userController = Get.find();

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        return SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان والترحيب
              _buildHeader(userController),
              SizedBox(height: 32.h),

              // الإحصائيات: تظهر أصفاراً في حال عدم وجود بيانات
              Obx(() {
                final data = dashboardController.dashboardData.value;
                return isMobile
                    ? Column(
                  children: [
                    _buildStatCard('Total Tracks', '${data?.totalPaths ?? 0}', Icons.school, Colors.blue, false),
                    SizedBox(height: 16.h),
                    _buildStatCard('Active paths', '${data?.activePaths ?? 0}', Icons.check_circle, Colors.green, false),
                  ],
                )
                    : Row(
                  children: [
                    _buildStatCard('Total Tracks', '${data?.totalPaths ?? 0}', Icons.school, Colors.blue, true),
                    SizedBox(width: 16.w),
                    _buildStatCard('Active paths', '${data?.activePaths ?? 0}', Icons.check_circle, Colors.green, true),
                  ],
                );
              }),

              SizedBox(height: 32.h),

              // الرسم البياني والمسارات الأخيرة مع التحقق من وجود بيانات
              isMobile
                  ? Column(
                children: [
                  _buildWeeklyChartSection(dashboardController),
                  SizedBox(height: 24.h),
                  _buildRecentPathsSection(dashboardController),
                ],
              )
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildWeeklyChartSection(dashboardController)),
                  SizedBox(width: 24.w),
                  Expanded(flex: 1, child: _buildRecentPathsSection(dashboardController)),
                ],
              ),

              SizedBox(height: 32.h),
              _buildAdditionalInfo(),
            ],
          ),
        );
      },
    );
  }

  // قسم الرسم البياني مع رسالة "لا توجد بيانات"
  Widget _buildWeeklyChartSection(DashboardController controller) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This weeks publishing rate', style: _headerStyle()),
          SizedBox(height: 16.h),
          Obx(() {
            // التحقق إذا كان الرسم البياني يحتوي على بيانات (حسب منطق الـ Controller الخاص بك)
            final hasData = controller.dashboardData.value != null;
            return SizedBox(
              height: 200.h,
              child: hasData
                  ? WeeklyChart()
                  : Center(child: Text('لا توجد بيانات للرسم البياني حالياً', style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey))),
            );
          }),
        ],
      ),
    );
  }

  // قسم المسارات الأخيرة مع رسالة "لا توجد بيانات"
  Widget _buildRecentPathsSection(DashboardController controller) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Latest Tracks', style: _headerStyle()),
          SizedBox(height: 16.h),
          Obx(() {
            final recentPaths = controller.dashboardData.value?.recentPaths ?? [];
            if (recentPaths.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Text('لا توجد مسارات لعرضها', style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey)),
                ),
              );
            }
            return Column(
              children: recentPaths.map((path) => _buildPathItem(path)).toList(),
            );
          }),
        ],
      ),
    );
  }

  // --- دوال التصميم الفرعية ---

  Widget _buildHeader(UserController userController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Dashboard', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12.r)),
              child: Icon(Icons.dashboard, color: Colors.blue, size: 24.w),
            ),
          ],
        ),
        Obx(() => Text(
          'hello ${userController.user.value?.name ?? "Guest"}',
          style: TextStyle(fontSize: 16.sp, color: Colors.grey[600], fontFamily: 'Tajawal'),
        )),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool useExpanded) {
    Widget content = Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16.r)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28.w),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14.sp, color: Colors.grey[600], fontFamily: 'Tajawal')),
              Text(value, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
    return useExpanded ? Expanded(child: content) : content;
  }

  Widget _buildPathItem(dynamic path) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.network(path.imageUrl, width: 40.w, height: 40.w, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 20.w)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(path.name ?? 'بدون عنوان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue[50]!, Colors.purple[50]!]),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text('Keep creating great educational content!', textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w500)),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16.r),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
  );

  TextStyle _headerStyle() => TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Tajawal');
}