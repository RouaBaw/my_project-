import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:untitled1/core/api_config.dart';
import 'package:untitled1/screens/games/GamePreviewSheet.dart';

class course_games_manager1 extends StatefulWidget {
  final int learningContentId;
  final String contentTitle;

  const course_games_manager1({
    super.key,
    required this.learningContentId,
    required this.contentTitle,
  });

  @override
  State<course_games_manager1> createState() => _course_games_manager1State();
}

class _course_games_manager1State extends State<course_games_manager1> {
  List<dynamic> gamesList = [];
  bool isLoading = true;
  String? loadError;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // --- جلب البيانات ---
  Future<void> _fetchGames() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = GetStorage().read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/courses_games/${widget.learningContentId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          gamesList = json.decode(response.body)['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          loadError = 'فشل تحميل الألعاب (رمز: ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        loadError = 'تعذر الاتصال بالسيرفر. تأكد من اتصالك بالإنترنت.';
      });
    }
  }

  // --- تصفية البحث ---
  List<dynamic> get _filteredGames {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return gamesList;
    return gamesList.where((g) {
      final title = (g['title'] ?? '').toString().toLowerCase();
      final type = (g['type'] ?? '').toString().toLowerCase();
      return title.contains(q) || type.contains(q);
    }).toList();
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'reorder': return 'ترتيب كلمات';
      case 'select_image': return 'اختيار صورة';
      case 'match': return 'توصيل العناصر';
      default: return 'لعبة تعليمية';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9), // لون خلفية هادئ
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildSearchSection(),
            Expanded(child: _buildGamesList()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الألعاب المتوفرة',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            widget.contentTitle,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12.sp,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent),
          onPressed: _fetchGames,
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 15.h),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: 'ابحث عن لعبة معينة...',
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: EdgeInsets.symmetric(horizontal: 15.w),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          _countBadge(),
        ],
      ),
    );
  }

  Widget _buildGamesList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }
    if (loadError != null) {
      return _buildErrorState();
    }

    final items = _filteredGames;
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildGameCard(items[index]),
    );
  }

  Widget _buildGameCard(dynamic game) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => _showGamePreview(game),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Icon / Type Representer
                _buildTypeIcon(game['type']),
                SizedBox(width: 16.w),
                // Game Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game['title'] ?? 'بدون عنوان',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          _typeBadge(_typeLabel(game['type'])),
                          SizedBox(width: 8.w),
                          _statusBadge(game['status']),
                        ],
                      ),
                    ],
                  ),
                ),
                // Visual Indicator
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.sp,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String? type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'reorder':
        icon = Icons.sort_by_alpha_rounded;
        color = Colors.orange;
        break;
      case 'select_image':
        icon = Icons.image_search_rounded;
        color = Colors.blue;
        break;
      case 'match':
        icon = Icons.extension_rounded;
        color = Colors.purple;
        break;
      default:
        icon = Icons.videogame_asset_rounded;
        color = Colors.teal;
    }

    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(icon, color: color, size: 24.sp),
    );
  }

  Widget _typeBadge(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11.sp, color: const Color(0xFF64748B)),
      ),
    );
  }

  Widget _statusBadge(dynamic status) {
    final s = status.toString().toLowerCase();
    bool isPublished = s == 'published';

    return Row(
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPublished ? Colors.green : Colors.orange,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          isPublished ? 'نشط' : 'قيد المراجعة',
          style: TextStyle(
              fontSize: 11.sp,
              color: isPublished ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w500
          ),
        ),
      ],
    );
  }

  Widget _countBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        '${gamesList.length}',
        style: TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp
        ),
      ),
    );
  }

  void _showGamePreview(dynamic game) {
    Get.bottomSheet(
      GamePreviewSheet(gameData: game),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 60.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          Text('لا توجد ألعاب متوفرة حالياً', style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
            SizedBox(height: 12.h),
            Text(loadError!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp)),
            TextButton(onPressed: _fetchGames, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}