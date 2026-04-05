import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:web_front1/controllers/admin_controller.dart';
import 'package:web_front1/pages/application_details_page.dart';
import 'package:web_front1/widgets/Content%20industry%20monitor/creator_application_card.dart';

class CreatorAccountsContent extends StatefulWidget {
  @override
  State<CreatorAccountsContent> createState() => _CreatorAccountsContentState();
}

class _CreatorAccountsContentState extends State<CreatorAccountsContent> {
  final AdminController _adminController = Get.find();

  // متغيرات الحالة للفلترة والبحث
  final RxString selectedFilter = 'all'.obs;
  final TextEditingController _searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Section
            _buildHeader(),
            SizedBox(height: 32.h),

            // 2. Statistics Cards Section
            _buildStatisticsCards(),
            SizedBox(height: 32.h),

            // 3. Search and Filter Bar
            _buildSearchAndFilterBar(),
            SizedBox(height: 24.h),

            // 4. Applications List Section
            Expanded(
              child: Obx(() {
                if (_adminController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: Colors.purple));
                }

                final allApps = _adminController.applications;

                // منطق الفلترة الشامل
                final filteredList = allApps.where((app) {
                  // أ- فلترة الحالة (Status Filter)
                  bool matchesFilter = true;
                  if (selectedFilter.value == 'all') {
                    matchesFilter = true; // عرض الجميع
                  } else if (selectedFilter.value == 'pending') {
                    matchesFilter = app.status == 'pending';
                  } else if (selectedFilter.value == 'accepted') {
                    matchesFilter = app.status == 'accepted';
                  } else if (selectedFilter.value == 'rejected') {
                    matchesFilter = app.status == 'rejected';
                  }

                  // ب- فلترة البحث (Search Filter)
                  bool matchesSearch =
                      app.firstName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                          app.lastName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                          app.email.toLowerCase().contains(searchQuery.value.toLowerCase());

                  return matchesFilter && matchesSearch;
                }).toList();

                if (filteredList.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final application = filteredList[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: CreatorApplicationCard(
                        application: application,
                        onViewDetails: () {
                          Get.to(() => ApplicationDetailsPage(application: application));
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إدارة حسابات صناع المحتوى',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'متابعة طلبات الانضمام، القبول، والرفض',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
          ],
        ),
        const Spacer(),
        // زر التحديث اليدوي
        ElevatedButton.icon(
          onPressed: () => _adminController.fetchApplications(),
          icon: const Icon(Icons.refresh, size: 20),
          label: const Text('تحديث البيانات'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    return Obx(() {
      final apps = _adminController.applications;
      return Row(
        children: [
          _buildStatCard('الكل', '${apps.length}', Icons.group, Colors.blue),
          SizedBox(width: 12.w),
          _buildStatCard('قيد الانتظار', '${apps.where((e) => e.status == 'pending').length}', Icons.hourglass_top, Colors.orange),
          SizedBox(width: 12.w),
          _buildStatCard('تم قبولها', '${apps.where((e) => e.status == 'accepted').length}', Icons.verified_user, Colors.green),
          SizedBox(width: 12.w),
          _buildStatCard('المرفوضة', '${apps.where((e) => e.status == 'rejected').length}', Icons.block, Colors.red),
        ],
      );
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24.w),
            SizedBox(height: 12.h),
            Text(title, style: TextStyle(fontSize: 13.sp, color: Colors.grey[600])),
            Text(value, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          // حقل البحث
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => searchQuery.value = val,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو الإيميل...',
                prefixIcon: const Icon(Icons.search, color: Colors.purple),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(width: 20.w),
          // أزرار الفلترة (Tabs)
          Expanded(
            flex: 4,
            child: Obx(() => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton('الكل', 'all'),
                  _buildTabButton('المعلقة', 'pending'),
                  _buildTabButton('الموثقة', 'accepted'),
                  _buildTabButton('المرفوضة', 'rejected'),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String value) {
    bool isSelected = selectedFilter.value == value;
    return GestureDetector(
      onTap: () => selectedFilter.value = value,
      child: Container(
        margin: EdgeInsets.only(left: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 70.w, color: Colors.grey[300]),
          SizedBox(height: 16.h),
          Text(
            'لا توجد طلبات في هذا القسم حالياً',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}