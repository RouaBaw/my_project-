import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';

class UserController extends GetxController {
  final _storage = GetStorage();

  // نستخدم .obs مع كائن فارغ أو نجعل المتغير يقبل القيمة الفارغة بشكل صحيح
  final user = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  void loadUserData() {
    // قراءة البيانات من GetStorage
    var storedData = _storage.read('user');

    if (storedData != null) {
      // التأكد من الوصول للمفتاح الصحيح داخل الـ JSON
      // إذا كان الـ JSON يحتوي على مفتاح "user" بداخله البيانات
      var userDataMap = storedData['user'];
      if (userDataMap != null) {
        user.value = User.fromJson(userDataMap);
      }
    }
  }
}