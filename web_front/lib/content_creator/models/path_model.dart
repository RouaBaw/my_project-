class LearningPath {
  final int id;
  final String name; // يقابل 'title' في قاعدة البيانات
  final String status;
  final String imageUrl; // يقابل 'photo' في قاعدة البيانات
  final String category; // حقل إضافي يمكنك استخدامه أو تركه اختيارياً
  final int studentCount; // يقابل 'number_of_courses' أو عدد الطلاب حسب منطقك
  final DateTime createdAt;
  final String description;

  LearningPath({
    required this.id,
    required this.name,
    required this.status,
    required this.imageUrl,
    required this.category,
    required this.studentCount,
    required this.createdAt,
    required this.description,
  });

  // دالة لتحويل JSON القادم من Laravel إلى كائن LearningPath
  factory LearningPath.fromJson(Map<String, dynamic> json) {
    // قاعدة رابط السيرفر لعرض الصور
    const String baseUrl = "http://127.0.0.1:8000/";

    return LearningPath(
      id: json['id'] ?? 0,
      // نستخدم 'title' لأن هذا هو الاسم في Migration الـ Laravel
      name: json['title'] ?? '',
      status: json['status'] ?? 'draft',
      // إذا كانت الصورة موجودة نضع الرابط الكامل، وإلا نضع صورة افتراضية
      imageUrl: json['photo'] != null
          ? baseUrl + json['photo']
          : 'https://via.placeholder.com/150',
      category: json['category'] ?? 'General',
      // نربطه بحقل عدد الكورسات الموجود في الـ Migration
      studentCount: json['number_of_courses'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      description: json['description'] ?? '',
    );
  }

  // دالة لتحويل الكائن إلى Map لإرساله (إذا لم تكن تستخدم Multipart)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': name,
      'description': description,
      'status': status,
      'photo': imageUrl,
    };
  }
}