import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/creator_application_model.dart';
import '../controllers/admin_controller.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;

class ApplicationDetailsPage extends StatelessWidget {
  final CreatorApplication application;

  const ApplicationDetailsPage({Key? key, required this.application}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AdminController adminController = Get.find();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'معلومات صانع المحتوى',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Profile Image (Clickable)
            _buildProfileHeader(context),
            SizedBox(height: 32.h),

            // Personal Information
            _buildSectionHeader('المعلومات الشخصية'),
            SizedBox(height: 16.h),
            _buildInfoGrid(),

            // Action Buttons (Approve / Reject)
            SizedBox(height: 40.h),
            _buildActionButtons(adminController),
          ],
        ),
      ),
    );
  }

  // دالة عرض الصورة بشكل مكبّر (Full Screen Dialog)
  void _showFullScreenImage(BuildContext context, String imageUrl, int id) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        insetPadding: EdgeInsets.zero, // ملء الشاشة
        child: Stack(
          alignment: Alignment.center,
          children: [
            // إطار عرض الصورة
            GestureDetector(
              onTap: () => Get.back(), // إغلاق عند الضغط خارج الصورة
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
                alignment: Alignment.center,
                child: Container(
                  width: 0.7.sw,
                  height: 0.7.sh,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Builder(
                      builder: (context) {
                        final String viewID = 'img-full-$id';
                        // ignore: undefined_prefixed_name
                        ui.platformViewRegistry.registerViewFactory(viewID, (int viewId) {
                          return html.ImageElement()
                            ..src = imageUrl
                            ..style.width = '100%'
                            ..style.height = '100%'
                            ..style.objectFit = 'contain'; // عرض كامل الصورة بدون قص
                        });
                        return HtmlElementView(viewType: viewID);
                      },
                    ),
                  ),
                ),
              ),
            ),
            // زر الإغلاق في الزاوية
            Positioned(
              top: 40,
              right: 40,
              child: FloatingActionButton(
                backgroundColor: Colors.white24,
                child: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Row(
      children: [
        // الصورة قابلة للضغط للتكبير
        GestureDetector(
          onTap: () => _showFullScreenImage(context, application.imageUrl ?? '', application.id),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40.r),
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purple.withOpacity(0.3), width: 3.w),
                ),
                child: Builder(
                  builder: (context) {
                    final String viewID = 'img-profile-${application.id}';
                    // ignore: undefined_prefixed_name
                    ui.platformViewRegistry.registerViewFactory(viewID, (int viewId) {
                      return html.ImageElement()
                        ..src = application.imageUrl ?? ''
                        ..style.width = '100%'
                        ..style.height = '100%'
                        ..style.objectFit = 'cover';
                    });
                    return HtmlElementView(viewType: viewID);
                  },
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                application.fullName,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                application.email,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8.h),
              _buildStatusLabel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusLabel() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _getStatusColor(application.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _getStatusColor(application.status)),
      ),
      child: Text(
        _getStatusText(application.status),
        style: TextStyle(
          fontSize: 14.sp,
          color: _getStatusColor(application.status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          _buildInfoRow('الرقم الوطني', application.nationalId),
          _buildDivider(),
          _buildInfoRow('الاسم ', application.firstName),
          _buildDivider(),
          _buildInfoRow('الكنية', application.lastName),
          _buildDivider(),
          _buildInfoRow("الأب", application.fatherName),
          _buildDivider(),
          _buildInfoRow('العمر', '${application.age} عاماً'),
          _buildDivider(),
          _buildInfoRow('المستوى التعليمي', application.educationLevel ?? 'غير محدد'),
          _buildDivider(),
          _buildInfoRow('رقم الهاتف', application.phone ?? 'غير متوفر'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[300], height: 1.h);
  }

  Widget _buildActionButtons(AdminController adminController) {
    if (application.status == 'accepted') {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, color: Colors.green),
            SizedBox(width: 8.w),
            const Text(
              'الحساب موثق بالفعل',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50.h,
            child: OutlinedButton.icon(
              onPressed: () => adminController.rejectApplication(application.id),
              icon: const Icon(Icons.close),
              label: const Text('رفض الطلب'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: SizedBox(
            height: 50.h,
            child: ElevatedButton.icon(
              onPressed: () => adminController.approveApplication(application.id),
              icon: const Icon(Icons.check),
              label: const Text('تأكيد القبول'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'accepted') return Colors.green;
    if (status == 'rejected') return Colors.red;
    return Colors.orange;
  }

  String _getStatusText(String status) {
    if (status == 'accepted') return 'موثق';
    if (status == 'rejected') return 'مرفوض';
    return 'قيد الانتظار';
  }
}