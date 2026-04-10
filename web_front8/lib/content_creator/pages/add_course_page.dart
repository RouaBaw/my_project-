import '../controllers/courses_controller.dart';
import '../controllers/paths_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/course_model.dart';
import '../widgets/multiple_question_widget.dart';
import '../widgets/true_false_question_widget.dart';

class AddCoursePage extends StatefulWidget {
  final int pathId;
  const AddCoursePage({Key? key, required this.pathId}) : super(key: key);

  @override
  _AddCoursePageState createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _courseDescriptionController = TextEditingController();
  final List<Question> _questions = [];
  final coursesController = Get.find<CoursesController>();

  @override
  Widget build(BuildContext context) {
    final path = Get.find<PathsController>().getPathById(widget.pathId);
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إضافة كورس جديد',
                style: TextStyle(
                  color: const Color(0xFF0F172A),
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w900,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                (path?.name ?? 'المسار').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontFamily: 'Tajawal',
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          leading: IconButton(
            tooltip: 'رجوع',
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A)),
            onPressed: () => Get.back(),
          ),
          actions: [
            Obx(() {
              final loading = coursesController.isLoading.value;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                child: ElevatedButton.icon(
                  onPressed: loading ? null : _saveCourse,
                  icon: loading
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    loading ? 'جارٍ الحفظ...' : 'حفظ',
                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  ),
                ),
              );
            }),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 980.w),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: EdgeInsets.all(18.w),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        cs,
                        icon: Icons.edit_note,
                        title: 'بيانات الكورس',
                        subtitle: 'اكتب الاسم والوصف ثم أضف الأسئلة.',
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              _courseNameController,
                              label: 'اسم الكورس',
                              hint: 'مثال: مقدمة في البرمجة',
                              validatorText: 'يرجى إدخال اسم الكورس',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      _buildTextField(
                        _courseDescriptionController,
                        label: 'وصف الكورس (اختياري)',
                        hint: 'وصف قصير يساعد الطالب على فهم محتوى الكورس...',
                        maxLines: 3,
                        requiredField: false,
                      ),
                      SizedBox(height: 22.h),

                      _buildSectionHeader(
                        cs,
                        icon: Icons.quiz_outlined,
                        title: 'الأسئلة',
                        subtitle: 'أضف على الأقل سؤالًا واحدًا قبل الحفظ.',
                        trailing: _buildAddButtons(cs),
                      ),
                      SizedBox(height: 14.h),
                      _buildQuestionsList(),
                      if (_questions.isEmpty) ...[
                        SizedBox(height: 8.h),
                        _buildInlineHint(
                          icon: Icons.info_outline,
                          text: 'لا توجد أسئلة حتى الآن. استخدم أزرار الإضافة بالأعلى.',
                        ),
                      ],

                      SizedBox(height: 22.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Get.back(),
                              icon: const Icon(Icons.close),
                              label: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Obx(() {
                              final loading = coursesController.isLoading.value;
                              return ElevatedButton.icon(
                                onPressed: loading ? null : _saveCourse,
                                icon: loading
                                    ? SizedBox(
                                        width: 18.w,
                                        height: 18.w,
                                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                      )
                                    : const Icon(Icons.check_circle_outline),
                                label: Text(
                                  loading ? 'جارٍ الحفظ...' : 'حفظ الكورس',
                                  style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w900),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(icon, color: cs.primary, size: 24.w),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.grey.shade700,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildInlineHint({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 18.w),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    required String label,
    required String hint,
    int maxLines = 1,
    String? validatorText,
    bool requiredField = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w900,
            fontSize: 14.sp,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: const TextStyle(fontFamily: 'Tajawal'),
          validator: (value) {
            if (!requiredField) return null;
            if (value == null || value.trim().isEmpty) {
              return validatorText ?? 'هذا الحقل مطلوب';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintTextDirection: TextDirection.rtl,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsList() {
    return Column(
      children: _questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value;
        return Container(
          key: ValueKey(question.id), // مهم جداً للحفاظ على حالة الحقول
          margin: EdgeInsets.only(bottom: 16.h),
          child: question.type == 'multiple'
              ? MultipleQuestionWidget(
            question: question,
            index: index,
            onDelete: () => setState(() => _questions.removeAt(index)),
          )
              : TrueFalseQuestionWidget(
            question: question,
            index: index,
            onDelete: () => setState(() => _questions.removeAt(index)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddButtons(ColorScheme cs) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: [
        OutlinedButton.icon(
          onPressed: _addMultipleChoice,
          icon: const Icon(Icons.list_alt),
          label: const Text('اختيار من متعدد', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _addTrueFalse,
          icon: const Icon(Icons.rule),
          label: const Text('صح / خطأ', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  void _addMultipleChoice() {
    setState(() {
      _questions.add(Question(id: DateTime.now().millisecondsSinceEpoch, questionText: '', type: 'multiple', options: ['', '', ''], correctOptionIndex: 0));
    });
  }

  void _addTrueFalse() {
    setState(() {
      _questions.add(Question(id: DateTime.now().millisecondsSinceEpoch, questionText: '', type: 'trueFalse', correctAnswer: true));
    });
  }

  void _saveCourse() async {
    // التحقق من صحة البيانات قبل الإرسال
    final ok = _formKey.currentState?.validate() ?? true;
    if (!ok) return;

    if (_questions.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إضافة سؤال واحد على الأقل');
      return;
    }

    // فحص كل سؤال للتأكد أن النص ليس فارغاً
    for (int i = 0; i < _questions.length; i++) {
      if (_questions[i].questionText.trim().isEmpty) {
        Get.snackbar('خطأ في السؤال ${i + 1}', 'نص السؤال فارغ! تأكد من الكتابة داخل الحقل.');
        return;
      }
    }

    bool success = await coursesController.saveCourseToApi(
      pathId: widget.pathId,
      name: _courseNameController.text,
      description: _courseDescriptionController.text,
      questions: _questions,
    );

    if (success) {
      Get.snackbar('نجاح', 'تم حفظ الكورس بنجاح');
      Get.back();
    }
  }
}