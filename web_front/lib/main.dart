import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:web_front1/content_creator/controllers/course_controller.dart';
import 'package:web_front1/content_creator/controllers/courses_controller.dart';
import 'package:web_front1/content_creator/controllers/dashboard_controller.dart';
import 'package:web_front1/content_creator/controllers/paths_controller.dart';
import 'package:web_front1/content_creator/controllers/user_controller.dart';
import 'package:web_front1/controllers/admin_controller.dart';
import 'package:web_front1/controllers/auth_controller.dart';
import 'package:web_front1/pages/moderator_login_page.dart';
import 'package:web_front1/pages/admin_dashboard_page.dart';
import 'package:web_front1/content_creator/pages/home_page.dart'; // تأكد من المسار
import 'package:intl/date_symbol_data_local.dart';
void main() async {
  await initializeDateFormatting('ar', null); // تفعيل اللغة العربية للتواريخ
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  final box = GetStorage();

  // 1. حقن المتحكمات الأساسية فوراً لضمان توفرها في مرحلة الـ Initial Screen
  // نضع AuthController هنا لتفادي خطأ "Not Found" نهائياً
  Get.put(AuthController(), permanent: true);

  String? token = box.read('token');
  String? userType = box.read('user_type');

  Widget initialScreen;

  if (token != null) {
    if (userType == 'system_administrator' || userType == 'content_auditor') {
      initialScreen = AdminDashboardPage();
    } else if (userType == 'content_creator') {
      initialScreen = HomePage();
    } else {
      initialScreen = ModeratorLoginPage();
    }
  } else {
    initialScreen = ModeratorLoginPage();
  }

  runApp(MyApp(startScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({Key? key, required this.startScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1440, 1024),
      builder: (_, child) {
        return GetMaterialApp(
          title: 'منصة التعلم للأطفال',
          debugShowCheckedModeBanner: false,
          home: startScreen,
          // 2. هنا نضع المتحكمات الأخرى التي لا نحتاجها في لحظة الإقلاع الأولى
          initialBinding: BindingsBuilder(() {
            Get.lazyPut(() => AdminController(), fenix: true);
            Get.lazyPut(() => UserController(), fenix: true);
            Get.lazyPut(() => PathsController(), fenix: true);
            Get.lazyPut(() => CourseController(), fenix: true);
            Get.lazyPut(() => DashboardController(), fenix: true);
            Get.lazyPut(() => CoursesController(), fenix: true);
          }),
        );
      },
    );
  }
}