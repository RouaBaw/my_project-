import '../models/path_model.dart';
import '../pages/CoursesPage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/paths_controller.dart';
import 'path_card.dart';
import 'add_path_dialog.dart'; // تأكد من استيراد الـ Dialog

class PathsContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final PathsController pathsController = Get.find();

    return Scaffold( // التغيير هنا: إضافة Scaffold
      backgroundColor: Color(0xFFF8F9FA),
      body: Padding( // نقل المحتوى الحالي إلى body
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              children: [
                Text(
                  'Educational Pathways',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Tajawal',
                  ),
                ),
                Spacer(),
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.school,
                    size: 30.w,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
            'Managing children learning pathways',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
                fontFamily: 'Tajawal',
              ),
            ),
            SizedBox(height: 32.h),

            // شبكة المسارات
            Expanded(
              child: Obx(() {
                final paths = pathsController.learningPaths;
                
                if (paths.isEmpty) {
                  return _buildEmptyState();
                }
                
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(),
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: paths.length,
                  itemBuilder: (context, index) {
                    final path = paths[index];
                    return InkWell(onTap: () {
                      Get.to(CoursesPage(pathId: path.id));
                    },
                      child: PathCard(
                        path: path,
                        onEdit: () => _showEditDialog(path),
                        onDelete: () => _showDeleteConfirmation(path),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      // إضافة الزر العائم هنا - خارج ال body وداخل Scaffold
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddPathDialog(),
          );
        },
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text(
         'Add a path',
          style: TextStyle(
            fontSize: 14.sp,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories,
              size: 50.w,
              color: Colors.blue[300],
            ),
          ),
          SizedBox(height: 20.h),
          Text(
           'There are no educational pathways',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'Tajawal',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
           ' Click the "Add Path" button to begin creation.',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black54,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount() {
    final screenWidth = Get.width - 280.w; // عرض الشريط الجانبي
    if (screenWidth > 1200) return 4;
    if (screenWidth > 900) return 3;
    if (screenWidth > 600) return 2;
    return 1;
  }

  void _showEditDialog(LearningPath path) {
    Get.snackbar(
      'Road correction',
      'edit: ${path.name}',
      backgroundColor: Colors.blue[50],
      colorText: Colors.blue,
    );
  }

  void _showDeleteConfirmation(LearningPath path) {
    Get.dialog(
      AlertDialog(
        title: Text('delete path', style: TextStyle(fontFamily: 'Tajawal')),
        content: Text('are you sure${path.name}"؟', style: TextStyle(fontFamily: 'Tajawal')),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close', style: TextStyle(fontFamily: 'Tajawal')),
          ),
          TextButton(
            onPressed: () {
              Get.find<PathsController>().learningPaths.remove(path);
              Get.back();
              Get.snackbar(
                'deleted ',
                'delete   "${path.name}"',
                backgroundColor: Colors.green[50],
                colorText: Colors.green,
              );
            },
            child: Text('delete', style: TextStyle(fontFamily: 'Tajawal', color: Colors.red)),
          ),
        ],
      ),
    );
  }
}