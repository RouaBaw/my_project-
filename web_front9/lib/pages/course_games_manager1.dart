import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:web_front1/content_creator/pages/GamePreviewSheet.dart';

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
  final String baseUrl = 'http://127.0.0.1:8000/api';
  final Set<int> _updatingGameIds = {};
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

  // --- API Methods ---

  Future<void> _fetchGames() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
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
        loadError = 'تعذر الاتصال بالسيرفر. حاول مرة أخرى.';
      });
    }
  }

  Future<void> _updateGameStatus(int gameId, String status) async {
    if (_updatingGameIds.contains(gameId)) return;
    setState(() => _updatingGameIds.add(gameId));
    try {
      final token = GetStorage().read('token');
      final response = await http.patch(
        Uri.parse('$baseUrl/games/$gameId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final idx = gamesList.indexWhere((g) => g['id'] == gameId);
        if (idx != -1) {
          setState(() {
            gamesList[idx]['status'] = status;
          });
        }
        Get.snackbar("نجاح", status == 'published' ? "تم قبول اللعبة بنجاح" : "تم رفض اللعبة");
      } else {
        Get.snackbar("خطأ", "فشل التحديث (${response.statusCode})");
      }
    } catch (e) {
      Get.snackbar("خطأ", "تعذر الاتصال بالسيرفر");
    } finally {
      if (mounted) {
        setState(() => _updatingGameIds.remove(gameId));
      }
    }
  }

  // --- Logic & Helpers ---

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
      case 'match': return 'توصيل';
      default: return t;
    }
  }

  // --- Build Components ---

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إدارة واعتماد الألعاب', style: TextStyle(fontFamily: 'Tajawal', fontSize: 16.sp, fontWeight: FontWeight.bold)),
              Text(widget.contentTitle, style: TextStyle(fontFamily: 'Tajawal', fontSize: 11.sp, color: Colors.grey)),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchGames),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: _buildMainPanel(cs),
        ),
      ),
    );
  }

  Widget _buildMainPanel(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Expanded(child: _buildSearchField(cs)),
                SizedBox(width: 10.w),
                _countBadge(cs, gamesList.length),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildGamesList(cs)),
        ],
      ),
    );
  }

  Widget _buildGamesList(ColorScheme cs) {
    if (isLoading) return Center(child: CircularProgressIndicator(color: cs.primary));
    if (loadError != null) return _errorState();

    final items = _filteredGames;
    if (items.isEmpty) return _emptyState();

    return ListView.separated(
      padding: EdgeInsets.all(12.w),
      itemCount: items.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) => _buildGameCard(items[index], index, cs),
    );
  }

  Widget _buildGameCard(dynamic game, int index, ColorScheme cs) {
    final String status = (game['status'] ?? '').toString().toLowerCase().trim();
    final bool isAccepted = status == 'published';

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Index
          CircleAvatar(
            radius: 15.r,
            backgroundColor: cs.primary.withOpacity(0.1),
            child: Text('${index + 1}', style: TextStyle(fontSize: 12.sp, color: cs.primary, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 12.w),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game['title'] ?? 'بدون عنوان', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                SizedBox(height: 4.h),
                Wrap(
                  spacing: 6.w,
                  children: [
                    _smallBadge(_typeLabel(game['type']), Colors.blueGrey),
                    _statusBadge(status),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.blue),
                onPressed: () => _showGamePreview(game),
                tooltip: 'معاينة',
              ),
              const VerticalDivider(),
              _buildActionButtons(game['id'], status, isAccepted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(int gameId, String status, bool isAccepted) {
    return Column(
      children: [
        if (!isAccepted)
          _statusButton(
            gameId: gameId,
            label: 'قبول',
            targetStatus: 'published',
            color: Colors.green,
            isOutline: false,
          ),
        if (!isAccepted) SizedBox(height: 4.h),
        _statusButton(
          gameId: gameId,
          label: 'رفض',
          targetStatus: 'reviewed',
          color: Colors.red,
          isOutline: status != 'reviewed', // ممتلئ إذا كان مرفوضاً بالفعل، مفرغ إذا لم يكن
        ),
      ],
    );
  }

  Widget _statusButton({
    required int gameId,
    required String label,
    required String targetStatus,
    required Color color,
    required bool isOutline,
  }) {
    final isBusy = _updatingGameIds.contains(gameId);
    
    return SizedBox(
      width: 70.w,
      height: 28.h,
      child: isOutline 
        ? OutlinedButton(
            onPressed: isBusy ? null : () => _updateGameStatus(gameId, targetStatus),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
            ),
            child: isBusy ? _loader(color) : Text(label, style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.bold)),
          )
        : ElevatedButton(
            onPressed: isBusy ? null : () => _updateGameStatus(gameId, targetStatus),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
            ),
            child: isBusy ? _loader(Colors.white) : Text(label, style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold)),
          ),
    );
  }

  // --- UI Elements ---

  Widget _statusBadge(String status) {
    Color color; String text;
    if (status == 'published') {
      color = Colors.green; text = 'مقبولة';
    } else if (status == 'reviewed') {
      color = Colors.red; text = 'مرفوضة';
    } else {
      color = Colors.orange; text = 'بانتظار المراجعة';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4.r)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold)),
    );
  }

  Widget _smallBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(4.r), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(text, style: TextStyle(color: color, fontSize: 10.sp)),
    );
  }

  Widget _buildSearchField(ColorScheme cs) {
    return TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'ابحث عن لعبة...',
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10.w),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide.none),
      ),
    );
  }

  void _showGamePreview(dynamic game) {
    Get.bottomSheet(
      GamePreviewSheet(gameData: game),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _loader(Color c) => SizedBox(width: 12.w, height: 12.w, child: CircularProgressIndicator(strokeWidth: 2, color: c));

  Widget _countBadge(ColorScheme cs, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r)),
      child: Text('$count لعبة', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
    );
  }

  Widget _emptyState() => Center(child: Text('لا توجد ألعاب متوفرة'));
  Widget _errorState() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(loadError ?? 'خطأ غير معروف'),
      TextButton(onPressed: _fetchGames, child: const Text('إعادة المحاولة'))
    ],
  ));
}