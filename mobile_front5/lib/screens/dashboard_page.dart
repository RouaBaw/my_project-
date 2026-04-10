import 'package:untitled1/screens/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../widgets/colorful_card.dart';
import '../widgets/animated_background.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Learning Dashboard',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Get.offAll(() => const LoginPage()),
          ),
        ],
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Text(
                  'Welcome Back! 👋',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Let\'s continue learning with fun!',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 30.h),

                // Child Profile
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.w),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF6584),
                        ),
                        child: Icon(
                          Icons.child_care,
                          size: 30.w,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alex Johnson',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6C63FF),
                              ),
                            ),
                            Text(
                              'Age: 6 years',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit,
                        color: const Color(0xFF6C63FF),
                        size: 20.w,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),

                // Learning Categories
                Text(
                  'Learning Categories',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                    children: [
                      ColorfulCard(
                        title: 'Alphabet',
                        subtitle: 'A-Z Learning',
                        icon: Icons.abc,
                        color: const Color(0xFFFF6584),
                        onTap: () {},
                      ),
                      ColorfulCard(
                        title: 'Numbers',
                        subtitle: '1-20 Counting',
                        icon: Icons.numbers,
                        color: const Color(0xFF36D1DC),
                        onTap: () {},
                      ),
                      ColorfulCard(
                        title: 'Colors',
                        subtitle: 'Learn Colors',
                        icon: Icons.color_lens,
                        color: const Color(0xFFFFB347),
                        onTap: () {},
                      ),
                      ColorfulCard(
                        title: 'Shapes',
                        subtitle: 'Basic Shapes',
                        icon: Icons.shape_line,
                        color: const Color(0xFF42E695),
                        onTap: () {},
                      ),
                      ColorfulCard(
                        title: 'Animals',
                        subtitle: 'Animal Sounds',
                        icon: Icons.pets,
                        color: const Color(0xFFC471ED),
                        onTap: () {},
                      ),
                      ColorfulCard(
                        title: 'Music',
                        subtitle: 'Fun Songs',
                        icon: Icons.music_note,
                        color: const Color(0xFF6C63FF),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}