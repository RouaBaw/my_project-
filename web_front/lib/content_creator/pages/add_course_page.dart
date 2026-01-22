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
  final _courseNameController = TextEditingController();
  final _courseDescriptionController = TextEditingController();
  final List<Question> _questions = [];
  final coursesController = Get.find<CoursesController>();

  @override
  Widget build(BuildContext context) {
    final path = Get.find<PathsController>().getPathById(widget.pathId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('إضافة كورس جديد', style: TextStyle(color: Colors.black, fontFamily: 'Tajawal')),
        actions: [
          Obx(() => coursesController.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : IconButton(
            icon: Icon(Icons.save, color: Colors.blue, size: 28.w),
            onPressed: _saveCourse,
          )),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(_courseNameController, 'اسم الكورس'),
              SizedBox(height: 16.h),
              _buildTextField(_courseDescriptionController, 'وصف الكورس', maxLines: 3),
              SizedBox(height: 32.h),
              _buildQuestionsList(),
              _buildAddButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r))),
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

  Widget _buildAddButtons() {
    return Row(
      children: [
        Expanded(child: ElevatedButton(onPressed: _addMultipleChoice, child: const Text('اضافة سؤال'))),

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
    if (_courseNameController.text.trim().isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إدخال اسم الكورس');
      return;
    }

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