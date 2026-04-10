class Child {
  String id;
  String name;
  String nickname;
  String age;
  String? imageUrl;
  List<String> interests;

  Child({
    required this.id,
    required this.name,
    required this.nickname,
    required this.age,
    this.imageUrl,
    this.interests = const [],
  });
}