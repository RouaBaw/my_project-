class User {
  final int id;
  final String name;
  final String? imageUrl;
  final double rating;
  final int totalPaths;
  final int activePaths;

  User({
    required this.id,
    required this.name,
    this.imageUrl,
    this.rating = 0.0,
    this.totalPaths = 0,
    this.activePaths = 0,
  });

  // دالة لتحويل JSON السيرفر إلى كائن User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      // دمج الاسم الأول والأخير
      name: '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      // استخدام صورة افتراضية في حال كانت profile_picture فارغة
      imageUrl: json['profile_picture'] ?? 'https://ui-avatars.com/api/?name=${json['first_name']}&background=random',
      rating: 4.5, // قيمة ثابتة أو افتراضية كما طلبت
      totalPaths: 0,
      activePaths: 0,
    );
  }
}