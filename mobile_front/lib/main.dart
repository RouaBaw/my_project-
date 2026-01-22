import 'package:get_storage/get_storage.dart';
import 'package:untitled1/screens/tests_page.dart';
import 'package:untitled1/screens/home_page.dart';
import 'package:untitled1/screens/main_layout.dart';
import 'package:untitled1/screens/parent_registration_page.dart';
import 'package:untitled1/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async{
  await GetStorage.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return GetMaterialApp(
          title: 'Kids Learning Fun',
          theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
          home: MainLayout(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

















