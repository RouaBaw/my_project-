class Course {
  final int id;
  final int pathId;
  final String title;
  final String description;
  final List<Question> questions;
  final DateTime createdAt;

  Course({
    required this.id,
    required this.pathId,
    required this.title,
    required this.description,
    required this.questions,
    required this.createdAt,
  });
}
class Question {
  final int id;
  String questionText; // إزالة final
  final String type;
  List<String>? options; // إزالة final
  int? correctOptionIndex; // إزالة final
  bool? correctAnswer; // إزالة final

  Question({
    required this.id,
    required this.questionText,
    required this.type,
    this.options,
    this.correctOptionIndex,
    this.correctAnswer,
  });
}
