import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/course_model.dart';

class TrueFalseQuestionWidget extends StatefulWidget {
  final Question question;
  final int index;
  final VoidCallback onDelete;

  const TrueFalseQuestionWidget({
    Key? key,
    required this.question,
    required this.index,
    required this.onDelete,
  }) : super(key: key);

  @override
  _TrueFalseQuestionWidgetState createState() => _TrueFalseQuestionWidgetState();
}

class _TrueFalseQuestionWidgetState extends State<TrueFalseQuestionWidget> {
  late TextEditingController _questionController;
  late bool _correctAnswer;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question.questionText);
    _correctAnswer = widget.question.correctAnswer ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // شريط العنوان والحذف
        Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: Colors.green,
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
                  'true / false question',
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

        // نص السؤال
        TextFormField(
          controller: _questionController,
          decoration: InputDecoration(
            labelText: 'Question',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // اختيار الإجابة الصحيحة
        Text(
          'true answer : ',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Tajawal',
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            // زر صح
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _correctAnswer = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _correctAnswer ? Colors.green : Colors.grey[300],
                  foregroundColor: _correctAnswer ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, size: 18.w),
                    SizedBox(width: 8.w),
                    Text(
                      'true',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // زر خطأ
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _correctAnswer = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_correctAnswer ? Colors.red : Colors.grey[300],
                  foregroundColor: !_correctAnswer ? Colors.white : Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, size: 18.w),
                    SizedBox(width: 8.w),
                    Text(
                      'false',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }
}