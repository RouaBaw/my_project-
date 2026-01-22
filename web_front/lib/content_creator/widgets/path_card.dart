import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/path_model.dart';

class PathCard extends StatefulWidget {
  final LearningPath path;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PathCard({
    Key? key,
    required this.path,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<PathCard> createState() => _PathCardState();
}

class _PathCardState extends State<PathCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        // تأثير بسيط بارتفاع البطاقة عند مرور الفأرة
        transform: isHovered
            ? (Matrix4.identity()..translate(0, -5, 0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? Colors.black.withOpacity(0.12)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isHovered ? 25 : 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          clipBehavior: Clip.antiAlias, // لقص الصورة والشرائط مع حواف البطاقة
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. قسم الصورة والشارات
              _buildImageSection(),

              // 2. قسم المحتوى (العنوان، الوصف، الإحصائيات، الأزرار)
              _buildContentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // استخدام AspectRatio يضمن ثبات حجم الصورة ويمنع أخطاء الـ Size
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            widget.path.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: Icon(Icons.image_not_supported_outlined,
                  color: Colors.grey[400], size: 40.sp),
            ),
          ),
        ),
        // التدرج اللوني فوق الصورة لسهولة قراءة النصوص إن وجدت
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                ],
              ),
            ),
          ),
        ),
        // شارة الحالة
        Positioned(
          top: 12.w,
          right: 12.w,
          child: _buildBadge(
            text: widget.path.status == 'active' ? 'نشط' : 'معلق',
            color: _getStatusColor(widget.path.status),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // التصنيف بلون مميز
          Text(
            widget.path.category,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.blueAccent,
              fontWeight: FontWeight.w600,
              fontFamily: 'Tajawal',
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 6.h),

          // اسم المسار
          Text(
            widget.path.name,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2D3748),
              fontFamily: 'Tajawal',
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 8.h),

          // وصف المسار (الوصف يملأ المساحة الفارغة)
          Text(
            widget.path.description,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
              fontFamily: 'Tajawal',
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 20.h), // مسافة قبل السطر الأخير

          // سطر الإحصائيات والأدوات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // أيقونة عدد الطلاب
              _buildInfoItem(Icons.people_outline, '${widget.path.studentCount} طالب'),

              // أزرار التحكم
              Row(
                children: [

                  SizedBox(width: 8.w),
                  _buildActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.red,
                      onTap: widget.onDelete
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ودجت لبناء الشارات (نشط/معلق)
  Widget _buildBadge({required String text, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
            color: Colors.white,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal'
        ),
      ),
    );
  }

  // ودجت لعناصر المعلومات (مثل عدد الطلاب)
  Widget _buildInfoItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: Colors.grey[500]),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontFamily: 'Tajawal'
          ),
        ),
      ],
    );
  }

  // ودجت لبناء أزرار التعديل والحذف بشكل احترافي
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Icon(icon, size: 18.sp, color: color),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    return status == 'active' ? const Color(0xFF48BB78) : const Color(0xFFED8936);
  }
}