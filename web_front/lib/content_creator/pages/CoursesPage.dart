import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/course_controller.dart';
import '../pages/WebCourseVideosPage.dart';
import 'package:web_front1/content_creator/pages/course_question_manager.dart';
// تأكد من صحة مسار استيراد صفحة الإضافة أدناه
import 'add_course_page.dart';

class CoursesPage extends StatelessWidget {
  final CourseController controller = Get.put(CourseController());
  final int pathId;

  CoursesPage({super.key, required this.pathId}) {
    controller.loadPathContents(pathId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: CustomScrollView(
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: Obx(() => _buildHeader(context)),
          ),

          // Contents Grid Section
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 30.h),
            sliver: Obx(() {
              if (controller.isLoading.value) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF4A90E2))),
                );
              }

              if (controller.contents.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState());
              }

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 25.w,
                  mainAxisSpacing: 25.h,
                  mainAxisExtent: 400.h,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final content = controller.contents[index];
                    return _buildCourseCard(content);
                  },
                  childCount: controller.contents.length,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final title = controller.pathData['title'] ?? 'المسار التعليمي';
    final desc = controller.pathData['description'] ?? 'تصفح محتويات المسار وأضف الأسئلة التعليمية';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(40.w, 30.h, 40.w, 30.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40.r),
          bottomRight: Radius.circular(40.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1A202C),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF718096),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
              _buildBackButton(),
            ],
          ),
          SizedBox(height: 30.h),
          Row(
            children: [
              _buildStatCard(
                icon: Icons.layers_outlined,
                title: 'إجمالي الدروس',
                value: '${controller.contents.length}',
                color: const Color(0xFF4A90E2),
              ),
              SizedBox(width: 20.w),
              _buildStatCard(
                icon: Icons.help_center_outlined,
                title: 'إجمالي الأسئلة',
                value: '${_calculateTotalQuestions()}',
                color: const Color(0xFF38B2AC),
              ),
              const Spacer(),
              // --- الزر المضاف حديثاً ---
              ElevatedButton.icon(
                onPressed: () async {
                  // ننتظر العودة من صفحة الإضافة
                  await Get.to(() => AddCoursePage(pathId: pathId));
                  // تحديث البيانات فور العودة
                  controller.loadPathContents(pathId);
                },
                icon: Icon(Icons.add_circle_outline, size: 20.w),
                label: Text(
                  'إضافة كورس جديد',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 15.h),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> content) {
    final String title = content['course_name'] ?? content['title'] ?? 'بدون عنوان';
    final List questions = content['questions'] ?? [];
    final String type = content['content_type'] == 'quiz' ? 'اختبار' : 'فيديو';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardImage(content, questions.length),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTypeBadge(type),
                      SizedBox(height: 10.h),
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: const Color(0xFF2D3748),
                          fontFamily: 'Tajawal',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        content['description'] ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12.sp,
                          fontFamily: 'Tajawal',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      const Divider(height: 1),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'عرض الدرس',
                            style: TextStyle(
                              color: const Color(0xFF4A90E2),
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Get.to(() => WebCourseVideosPage(
                    courseId: content['id'],
                    courseTitle: title,
                  ));
                },
              ),
            ),
          ),
          Positioned(
            bottom: 12.h,
            left: 16.w,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.to(() => CourseQuestionsManager(
                  learningContentId: content['id'],
                  contentTitle: title,
                ));
              },
              icon: Icon(Icons.edit_note, size: 16.w),
              label: Text(
                'إدارة الأسئلة',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38B2AC),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardImage(Map<String, dynamic> content, int qCount) {
    return Container(
      height: 160.h,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/path.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
              ),
            ),
          ),
          Positioned(
            top: 12.h,
            right: 12.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.quiz_outlined, size: 12.w, color: const Color(0xFF38B2AC)),
                  SizedBox(width: 4.w),
                  Text(
                    'سؤال $qCount',
                    style: TextStyle(
                      color: const Color(0xFF2D3748),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 40)),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22.w),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2D3748),
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12.sp, color: const Color(0xFF718096)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    bool isVideo = type == 'فيديو';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isVideo
            ? const Color(0xFF4A90E2).withOpacity(0.1)
            : const Color(0xFFF6AD55).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: isVideo ? const Color(0xFF4A90E2) : const Color(0xFFDD6B20),
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Get.back(),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
        child: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF4A5568)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80.w, color: Colors.grey.shade300),
          SizedBox(height: 20.h),
          Text(
            'لا يوجد محتوى متاح حالياً',
            style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey.shade500, fontSize: 16.sp),
          ),
        ],
      ),
    );
  }

  int _calculateTotalQuestions() {
    return controller.contents.fold<int>(0, (sum, item) {
      final List q = item['questions'] ?? [];
      return sum + q.length;
    });
  }
}