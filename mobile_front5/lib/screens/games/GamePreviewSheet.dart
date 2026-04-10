import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:untitled1/core/api_config.dart'; // تأكد من استيراد ملف الإعدادات
import 'package:untitled1/screens/games/game_play_widget.dart';

class GamePreviewSheet extends StatefulWidget {
  final Map<String, dynamic> gameData;

  const GamePreviewSheet({super.key, required this.gameData});

  @override
  State<GamePreviewSheet> createState() => _GamePreviewSheetState();
}

class _GamePreviewSheetState extends State<GamePreviewSheet> {
  String? baseUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  /// جلب الـ BaseUrl مرة واحدة عند بدء تشغيل الودجت
  Future<void> _loadBaseUrl() async {
    try {
      final url = await ApiConfig.getBaseUrl();
      setState(() {
        baseUrl = url;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        baseUrl = "localhost";
        isLoading = false;
      });
    }
  }

  /// دالة إصلاح الروابط المحسنة
  String fixImageUrl(String url) {
    if (baseUrl == null) return url;

    String cleanBaseUrl = baseUrl!;
    // إزالة البروتوكول والمنفذ للمقارنة النظيفة إذا لزم الأمر
    cleanBaseUrl = cleanBaseUrl.replaceAll(':8000', '').replaceAll('http://', '').replaceAll('https://', '');

    String fixedUrl = url;
    fixedUrl = fixedUrl.replaceAll('127.0.0.1', cleanBaseUrl);
    fixedUrl = fixedUrl.replaceAll('localhost', cleanBaseUrl);
    fixedUrl = fixedUrl.replaceAll('/api', '');

    return fixedUrl;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 300.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final gameData = widget.gameData;
    final title = gameData['title'] ?? '';
    final type = gameData['type'] ?? '';
    final content = Map<String, dynamic>.from(gameData['content'] ?? {});
    final settings = Map<String, dynamic>.from(gameData['settings'] ?? {});

    final points = settings['points'] ?? 10;
    final timer = settings['timer'] ?? settings['time_limit'] ?? 30;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF7F8FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// Handle (المقبض العلوي للسحب)
                Center(
                  child: Container(
                    width: 60.w,
                    height: 6.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                /// عنوان + نوع اللعبة
                _buildHeader(title, type),

                SizedBox(height: 18.h),

                /// معلومات اللعبة (نقاط ووقت)
                _buildInfoBar(points, timer),

                SizedBox(height: 22.h),

                Text(
                  "معاينة سريعة",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: "Tajawal",
                    color: Colors.grey[800],
                  ),
                ),

                SizedBox(height: 12.h),

                /// كارد المعاينة
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: _buildPreview(type, content),
                ),

                SizedBox(height: 24.h),

                _buildNote(),

                SizedBox(height: 20.h),

                /// زر اللعب
                _buildPlayButton(type, gameData),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            fontFamily: "Tajawal",
            height: 1.3,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: _getTypeColor(type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videogame_asset_rounded, size: 16.sp, color: _getTypeColor(type)),
              SizedBox(width: 5.w),
              Text(
                type == "reorder" ? "لعبة ترتيب الحروف" : type == "select_image" ? "لعبة اختيار الصورة" : "لعبة تعليمية",
                style: TextStyle(fontSize: 12.sp, color: _getTypeColor(type), fontFamily: "Tajawal"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBar(int points, int timer) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _info(Icons.star_rounded, "$points نقطة", Colors.orange),
          _info(Icons.timer_rounded, "$timer ثانية", Colors.blue),
        ],
      ),
    );
  }

  Widget _buildPreview(String type, Map content) {
    if (type == "select_image") return _selectImagePreview(content);
    if (type == "reorder") return _reorderPreview(content);
    return const Center(child: Text("معاينة غير متوفرة لهذا النوع"));
  }

  Widget _selectImagePreview(Map content) {
    final options = content['options'] ?? [];
    return Column(
      children: [
        Text(content['question'] ?? "", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 15.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length > 4 ? 4 : options.length, // عرض أول 4 خيارات فقط للمعاينة
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Image.network(
              fixImageUrl(options[i]['image']),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reorderPreview(Map content) {
    final letters = (content['word'] ?? "").toString().split("")..shuffle();
    final image = content['image'];
    return Column(
      children: [
        if (image != null)
          Image.network(fixImageUrl(image), height: 100.h, errorBuilder: (_, __, ___) => const SizedBox()),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8,
          children: letters.take(5).map((l) => Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(8)),
            child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildPlayButton(String type, Map<String, dynamic> gameData) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton.icon(
        onPressed: () {
          Get.back();
          Get.to(() => Scaffold(
            appBar: AppBar(title: Text(gameData["title"] ?? "اللعبة")),
            body: GamePlayWidget(gameData: gameData),
          ));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _getTypeColor(type),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        ),
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
        label: const Text("ابدأ اللعب الآن", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 16.sp, color: Colors.grey),
        SizedBox(width: 5.w),
        Text("هذه مجرد معاينة سريعة للعبة", style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
      ],
    );
  }

  Widget _info(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18.sp),
        SizedBox(width: 5.w),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13.sp)),
      ],
    );
  }

  Color _getTypeColor(String type) {
    if (type == "reorder") return Colors.purple;
    if (type == "select_image") return Colors.teal;
    return Colors.blue;
  }
}