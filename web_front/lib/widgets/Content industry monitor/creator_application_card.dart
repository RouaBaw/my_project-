import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:web_front1/models/creator_application_model.dart';
import 'dart:ui_web' as ui; // استيراد للمكتبة الخاصة بالويب
import 'dart:html' as html;

class CreatorApplicationCard extends StatelessWidget {
  final CreatorApplication application;
  final VoidCallback onViewDetails;

  const CreatorApplicationCard({
    Key? key,
    required this.application,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: Colors.white,
        ),
        child: Row(
          children: [
            // --- قسم الصورة المعدل للويب ---
            ClipRRect(
              borderRadius: BorderRadius.circular(30.r),
              child: Container(
                width: 60.w,
                height: 60.w,
                color: Colors.grey[200],
                child: (application.imageUrl != null && application.imageUrl!.isNotEmpty)
                    ? Builder(
                  builder: (context) {
                    // إنشاء معرف فريد لكل صورة بناءً على المعرف
                    final String viewID = 'img-view-${application.id}';

                    // تسجيل العنصر في محرك الويب ليتم عرضه كـ HTML Image
                    // ignore: undefined_prefixed_name
                    ui.platformViewRegistry.registerViewFactory(viewID, (int viewId) {
                      return html.ImageElement()
                        ..src = application.imageUrl!
                        ..style.width = '100%'
                        ..style.height = '100%'
                        ..style.objectFit = 'cover'
                        ..style.borderRadius = '50%';
                    });

                    return HtmlElementView(viewType: viewID);
                  },
                )
                    : Icon(Icons.person, size: 30.w, color: Colors.grey),
              ),
            ),
            // ------------------------

            SizedBox(width: 16.w),

            // Application Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${application.firstName} ${application.lastName}",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    application.email,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _buildStatusBadge(),
                ],
              ),
            ),

            // View Details Button
            ElevatedButton(
              onPressed: onViewDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[50],
                foregroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: 0,
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 18.w),
                  SizedBox(width: 6.w),
                  Text(
                    'عرض التفاصيل',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
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

  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _getStatusColor(application.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: _getStatusColor(application.status).withOpacity(0.5),
        ),
      ),
      child: Text(
        _getStatusText(application.status),
        style: TextStyle(
          fontSize: 11.sp,
          color: _getStatusColor(application.status),
          fontWeight: FontWeight.bold,
        ),
      ),
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
    return 'قيد المراجعة';
  }
}