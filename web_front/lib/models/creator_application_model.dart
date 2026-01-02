import 'dart:convert';

class CreatorApplication {
  final int id; // غيرناه إلى int لأن لارافيل تستخدم BigInteger للـ ID
  final String nationalId;
  final String firstName;
  final String lastName;
  final String fatherName;
  final String? motherName; // أضفناه لأنه موجود في قاعدة البيانات
  final int? age;
  final String? educationLevel;
  final String email;
  final String? phone;
  final String? imageUrl; // الحقل الجديد الذي يمثل صورة الملف الشخصي أو الهوية
  final String status;    // pending, accepted, rejected (تأكد من مطابقة accepted مع لارافيل)
  final DateTime? appliedAt;

  CreatorApplication({
    required this.id,
    required this.nationalId,
    required this.firstName,
    required this.lastName,
    required this.fatherName,
    this.motherName,
    this.age,
    this.educationLevel,
    required this.email,
    this.phone,
    this.imageUrl,
    required this.status,
    this.appliedAt,
  });

  // الحصول على الاسم الكامل
  String get fullName => '$firstName $fatherName $lastName';

  // تحويل البيانات القادمة من API (Map) إلى Object
  factory CreatorApplication.fromMap(Map<String, dynamic> map) {
    return CreatorApplication(
      id: map['id']?.toInt() ?? 0,
      nationalId: map['national_id'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      fatherName: map['father_name'] ?? '',
      motherName: map['mother_name'],
      age: map['age']?.toInt(),
      educationLevel: map['education_level'],
      email: map['email'] ?? '',
      phone: map['phone_number'], // تأكد من مطابقة الاسم مع Laravel
      imageUrl: map['image_url'], // الحقل الجديد
      status: map['account_status'] ?? 'pending', // نستخدم account_status كما في لارافيل
      appliedAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  // تحويل الـ Object إلى Map لإرساله إلى الـ API إذا لزم الأمر
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'national_id': nationalId,
      'first_name': firstName,
      'last_name': lastName,
      'father_name': fatherName,
      'mother_name': motherName,
      'age': age,
      'education_level': educationLevel,
      'email': email,
      'phone_number': phone,
      'image_url': imageUrl,
      'account_status': status,
    };
  }

  String toJson() => json.encode(toMap());

  factory CreatorApplication.fromJson(String source) =>
      CreatorApplication.fromMap(json.decode(source));
}