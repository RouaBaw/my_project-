import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/course_model.dart';

class MultipleQuestionWidget extends StatefulWidget {
  final Question question;
  final int index;
  final VoidCallback onDelete;

  const MultipleQuestionWidget({
    Key? key,
    required this.question,
    required this.index,
    required this.onDelete,
  }) : super(key: key);

  @override
  _MultipleQuestionWidgetState createState() => _MultipleQuestionWidgetState();
}

class _MultipleQuestionWidgetState extends State<MultipleQuestionWidget> {
  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;
  late int _correctOptionIndex;

  @override
  void initState() {
    super.initState();
    // ربط الحقل بالنص الموجود حالياً في الكائن
    _questionController = TextEditingController(text: widget.question.questionText);

    // إنشاء 3 خيارات والتأكد من تحديث الكائن بها
    _optionControllers = List.generate(3, (index) {
      String initialText = (widget.question.options != null && index < widget.question.options!.length)
          ? widget.question.options![index]
          : '';
      return TextEditingController(text: initialText);
    });

    _correctOptionIndex = widget.question.correctOptionIndex ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // شريط العنوان وزر الحذف
        Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'سؤال اختيار من متعدد',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red, size: 20.w),
              onPressed: widget.onDelete,
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // حقل نص السؤال مع التحديث الفوري
        TextFormField(
          controller: _questionController,
          onChanged: (value) {
            // تحديث نص السؤال في الكائن الرئيسي فوراً لمنع خطأ "السؤال فارغ"
            widget.question.questionText = value;
          },
          decoration: InputDecoration(
            labelText: 'اكتب السؤال هنا',
            labelStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 14.sp),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // قائمة الخيارات (3 خيارات)
        ...List.generate(3, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                // اختيار الإجابة الصحيحة وتحديث الكائن
                Radio(
                  value: index,
                  groupValue: _correctOptionIndex,
                  onChanged: (value) {
                    setState(() {
                      _correctOptionIndex = value as int;
                      widget.question.correctOptionIndex = _correctOptionIndex;
                    });
                  },
                ),
                SizedBox(width: 8.w),
                // حقل نص الخيار مع التحديث الفوري
                Expanded(
                  child: TextFormField(
                    controller: _optionControllers[index],
                    onChanged: (value) {
                      // تحديث الخيار المحدد داخل مصفوفة الخيارات في الكائن
                      if (widget.question.options != null) {
                        widget.question.options![index] = value;
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'الخيار ${index + 1}',
                      labelStyle: TextStyle(fontFamily: 'Tajawal', fontSize: 13.sp),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}