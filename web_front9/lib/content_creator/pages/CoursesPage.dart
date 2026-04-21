import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:web_front1/content_creator/pages/stories/story_manager.dart';
import '../controllers/course_controller.dart';
import '../pages/WebCourseVideosPage.dart';
import 'course_games_manager.dart';
import 'course_question_manager.dart';
import 'add_course_page.dart';

class CoursesPage extends StatefulWidget {
  final int pathId;

  const CoursesPage({super.key, required this.pathId});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final CourseController controller = Get.put(CourseController());

  final TextEditingController _searchCtrl = TextEditingController();
  final RxString _query = ''.obs;
  final RxInt _sortIndex = 0.obs; // 0: default, 1: A-Z, 2: Z-A

  @override
  void initState() {
    super.initState();
    controller.loadPathContents(widget.pathId);
    _searchCtrl.addListener(() {
      _query.value = _searchCtrl.text;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredAndSortedContents() {
    final q = _query.value.trim().toLowerCase();

    final filtered = controller.contents.where((c) {
      if (q.isEmpty) return true;
      final name = (c['course_name'] ?? '').toString().toLowerCase();
      final desc = (c['description'] ?? '').toString().toLowerCase();
      return name.contains(q) || desc.contains(q);
    }).toList(growable: false);

    if (_sortIndex.value == 1) {
      filtered.sort((a, b) => (a['course_name'] ?? '').toString().compareTo((b['course_name'] ?? '').toString()));
    } else if (_sortIndex.value == 2) {
      filtered.sort((a, b) => (b['course_name'] ?? '').toString().compareTo((a['course_name'] ?? '').toString()));
    }

    return filtered;
  }

  int _crossAxisCountForWidth(double w) {
    if (w >= 1400) return 4;
    if (w >= 1050) return 3;
    if (w >= 700) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: Obx(() => _buildHeader(context, cs))),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 30.h),
            sliver: Obx(() {
              if (controller.isLoading.value) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: SizedBox(
                      width: 42.w,
                      height: 42.w,
                      child: CircularProgressIndicator(color: cs.primary),
                    ),
                  ),
                );
              }

              final items = _filteredAndSortedContents();

              if (controller.contents.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyStateCard(
                    title: 'لا توجد كورسات بعد',
                    subtitle: 'ابدأ بإضافة أول كورس لهذا المسار.',
                    primaryLabel: 'إضافة كورس',
                    onPrimary: () async {
                      await Get.to(() => AddCoursePage(pathId: widget.pathId));
                      controller.loadPathContents(widget.pathId);
                    },
                  ),
                );
              }

              if (items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyStateCard(
                    title: 'لا توجد نتائج',
                    subtitle: 'جرّب تعديل كلمات البحث أو تغيير الترتيب.',
                    primaryLabel: 'مسح البحث',
                    onPrimary: () {
                      _searchCtrl.clear();
                      _query.value = '';
                    },
                    secondaryLabel: 'إظهار الكل',
                    onSecondary: () {
                      _searchCtrl.clear();
                      _query.value = '';
                      _sortIndex.value = 0;
                    },
                  ),
                );
              }

              return SliverLayoutBuilder(
                builder: (context, constraints) {
                  final cols = _crossAxisCountForWidth(constraints.crossAxisExtent);
                  final extent = cols == 1 ? 560.h : cols == 2 ? 490.h : 430.h;

                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 22.w,
                      mainAxisSpacing: 22.h,
                      mainAxisExtent: extent,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final content = items[index];
                        return _HoverScale(
                          enabled: kIsWeb,
                          child: _buildCourseCard(content, cs),
                        );
                      },
                      childCount: items.length,
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    final title = controller.pathData['title'] ?? 'المسار التعليمي';
    final desc = controller.pathData['description'] ?? '';

    return Container(
      padding: EdgeInsets.fromLTRB(40.w, 30.h, 40.w, 30.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            cs.primary.withOpacity(0.06),
            const Color(0xFFF1F5F9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40.r),
          bottomRight: Radius.circular(40.r),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (desc.toString().trim().isNotEmpty)
                      Text(
                        desc,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
              ),
              _buildBackButton(),
            ],
          ),
          SizedBox(height: 25.h),
          Row(
            children: [
              _buildStatCard(cs, Icons.layers, 'الدروس',
                  controller.contents.length.toString()),
              SizedBox(width: 15.w),
              _buildStatCard(cs, Icons.auto_stories, 'القصص',
                  _calculateTotalStories().toString()),
              SizedBox(width: 15.w),
              _buildStatCard(cs, Icons.videogame_asset, 'الألعاب',
                  _calculateTotalGames().toString()),
              SizedBox(width: 15.w),
              _buildStatCard(cs, Icons.quiz, 'الأسئلة',
                  _calculateTotalQuestions().toString()),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  await Get.to(() => AddCoursePage(pathId: widget.pathId));
                  controller.loadPathContents(widget.pathId);
                },
                icon: const Icon(Icons.add),
                label: const Text('إضافة كورس'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
              )
            ],
          )
        ,
          SizedBox(height: 18.h),
          _buildSearchAndSort(cs),
        ],
      ),
    );
  }

  Widget _buildSearchAndSort(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ابحث عن كورس بالاسم أو الوصف...',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                suffixIcon: Obx(() {
                  final hasText = _query.value.trim().isNotEmpty;
                  if (!hasText) return const SizedBox.shrink();
                  return IconButton(
                    tooltip: 'مسح',
                    onPressed: () {
                      _searchCtrl.clear();
                      _query.value = '';
                    },
                    icon: Icon(Icons.close, color: Colors.grey.shade700),
                  );
                }),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Obx(() {
            return DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _sortIndex.value,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('الترتيب: افتراضي')),
                  DropdownMenuItem(value: 1, child: Text('الترتيب: A-Z')),
                  DropdownMenuItem(value: 2, child: Text('الترتيب: Z-A')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  _sortIndex.value = v;
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  // ================= CARD =================
  Widget _buildCourseCard(Map<String, dynamic> content, ColorScheme cs) {
    final title = content['course_name'] ?? 'بدون عنوان';
    final description = (content['description'] ?? '').toString().trim();
    final questions = content['questions'] ?? [];
    final games = content['games'] ?? [];
    final stories = content['stories'] ?? [];
    final dynamic rawId = content['id'] ?? content['learning_content_id'];
    final int? learningContentId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Get.to(() => WebCourseVideosPage(
                    courseId: content['id'],
                    courseTitle: title,
                  ));
                },
                child: _buildCardImage(
                  cs,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildCourseMetaChip('كورس تعليمي'),
                          const Spacer(),
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 16.w,
                            color: const Color(0xFFCBD5E1),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 15.5.sp : 16.5.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        description.isEmpty
                            ? 'لا يوجد وصف مضاف لهذا الكورس حالياً.'
                            : description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: Colors.grey.shade600,
                          height: 1.45,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: [
                          _buildMetricChip(
                            icon: Icons.quiz_outlined,
                            label: 'الأسئلة',
                            value: questions.length,
                            color: const Color(0xFFF59E0B),
                            onTap: () {
                              Get.to(() => CourseQuestionsManager(
                                learningContentId: content['id'],
                                contentTitle: title,
                              ));
                            },
                          ),
                          _buildMetricChip(
                            icon: Icons.videogame_asset_outlined,
                            label: 'الألعاب',
                            value: games.length,
                            color: const Color(0xFF10B981),
                            onTap: () {
                              Get.to(() => CourseGamesManager(
                                learningContentId: content['id'],
                                contentTitle: title,
                              ));
                            },
                          ),
                          _buildMetricChip(
                            icon: Icons.auto_stories_outlined,
                            label: 'القصص',
                            value: stories.length,
                            color: const Color(0xFF3B82F6),
                            onTap: () {
                              if (learningContentId == null) {
                                Get.snackbar(
                                  'تنبيه',
                                  'لا يمكن فتح إدارة القصص: معرف المحتوى غير متوفر',
                                  backgroundColor: Colors.orange,
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              Get.to(() => StoryManagerPage(
                                    pathId: widget.pathId,
                                    learningContentId: learningContentId,
                                    contentTitle: title,
                                  ));
                            },
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCourseMetaChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF4F46E5),
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: color.withOpacity(0.16)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15.w, color: color),
              SizedBox(width: 6.w),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage(ColorScheme cs) {
    return Stack(
      children: [
        Container(
          height: 136.h,
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(22.r)),
            image: const DecorationImage(
              image: AssetImage('assets/images/path.jpeg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: 136.h,
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(22.r)),
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: 12.h,
          right: 12.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(999.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_fill, size: 16.w, color: cs.primary),
                SizedBox(width: 6.w),
                Text(
                  'عرض المحتوى',
                  style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 4.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withOpacity(0.95),
                  const Color(0xFF38B2AC),
                  const Color(0xFF6366F1),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= UI HELPERS =================
  Widget _buildStatCard(ColorScheme cs, IconData icon, String title, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  fontSize: 14.sp,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => Get.back(),
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
            color: Colors.grey.shade200, shape: BoxShape.circle),
        child: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  int _calculateTotalQuestions() {
    return controller.contents.fold<int>(0, (sum, item) {
      final List q = item['questions'] ?? [];
      return sum + q.length;
    });
  }

  int _calculateTotalGames() {
    return controller.contents.fold<int>(0, (sum, item) {
      final List games = item['games'] ?? [];
      return sum + games.length;
    });
  }

  int _calculateTotalStories() {
    return controller.contents.fold<int>(0, (sum, item) {
      final List stories = item['stories'] ?? [];
      return sum + stories.length;
    });
  }
}

class _HoverScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const _HoverScale({required this.child, required this.enabled});

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, _hover ? -6.0 : 0.0),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          scale: _hover ? 1.01 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}

extension _CoursesEmpty on _CoursesPageState {
  Widget _buildEmptyStateCard({
    required String title,
    required String subtitle,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520.w),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: Icon(Icons.school, size: 34.w, color: const Color(0xFF4F46E5)),
              ),
              SizedBox(height: 14.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onPrimary,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      ),
                      child: Text(primaryLabel),
                    ),
                  ),
                  if (secondaryLabel != null && onSecondary != null) ...[
                    SizedBox(width: 10.w),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onSecondary,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                        ),
                        child: Text(secondaryLabel),
                      ),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}