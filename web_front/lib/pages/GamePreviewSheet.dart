import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:web_front1/content_creator/pages/game_play_widget.dart';

class GamePreviewSheet extends StatelessWidget {
  final Map<String, dynamic> gameData;

  const GamePreviewSheet({super.key, required this.gameData});
  String fixImageUrl(String url) {
    if (url.contains("127.0.0.1")) {
      return url.replaceAll("127.0.0.1", "localhost");
    }
    return url;
  }
  @override
  Widget build(BuildContext context) {
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
                /// Handle
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
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
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: _getTypeColor(type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videogame_asset_rounded,
                                  size: 16.sp,
                                  color: _getTypeColor(type),
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  type == "reorder"
                                      ? "لعبة ترتيب الحروف"
                                      : type == "select_image"
                                          ? "لعبة اختيار الصورة"
                                          : "لعبة تعليمية",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: _getTypeColor(type),
                                    fontFamily: "Tajawal",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 18.h),

                /// معلومات اللعبة
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _info(Icons.star_rounded, "$points نقطة",
                              Colors.orange),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _info(Icons.timer_rounded, "$timer ثانية",
                              Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 22.h),

                /// عنوان جزء المعاينة
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

                /// معاينة اللعبة داخل كارد
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

                /// ملاحظة بسيطة
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline,
                        size: 18.sp, color: Colors.grey[600]),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        "هذه مجرد معاينة، قد يختلف شكل اللعبة قليلاً أثناء اللعب الفعلي.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                          fontFamily: "Tajawal",
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                /// زر اللعب
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.to(
                        Scaffold(
                          appBar: AppBar(title: Text(gameData["title"])),
                          body: GamePlayWidget(gameData: gameData),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getTypeColor(type),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      Icons.play_arrow_rounded,
                      size: 26.sp,
                    ),
                    label: Text(
                      "ابدأ اللعب الآن",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Tajawal",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Preview حسب نوع اللعبة
  Widget _buildPreview(String type, Map content) {
    switch (type) {

      case "select_image":
        return _selectImagePreview(content);

      case "reorder":
        return _reorderPreview(content);

      default:
        return Text("معاينة غير متوفرة");
    }
  }

  /// preview لعبة اختيار صورة
  Widget _selectImagePreview(Map content) {

    final question = content['question'] ?? "";
    final options = content['options'] ?? [];

    return Column(
      children: [

        Text(
          question,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 20.h),

        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
          ),
          itemBuilder: (_, index) {

            final image = fixImageUrl(options[index]['image']);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.r),
                child:
                Image.network(
                  fixImageUrl(image),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image_not_supported, size: 40),
                    );
                  },

                  headers: {"Access-Control-Allow-Origin": "*"},

                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// preview لعبة ترتيب الحروف
  Widget _reorderPreview(Map content) {

    final word = content['word'] ?? "";
    final hint = content['hint'] ?? "";
    final image = content['image'];
    final letters = word.split("")..shuffle();

    return Column(
      children: [

        /// صورة اللعبة
        if (image != null)
          Padding(
            padding: EdgeInsets.only(bottom: 15.h),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.r),
              child: Image.network(
                fixImageUrl(image),
                height: 150.h,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 150.h,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image_not_supported, size: 40),
                  );
                },
              ),
            ),
          ),

        /// التلميح
        if (hint.isNotEmpty)
          Text(
            hint,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

        SizedBox(height: 20.h),

        /// الحروف المبعثرة
        Wrap(
          spacing: 10,
          children: letters.map<Widget>((letter) {

            return Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            );

          }).toList(),
        ),
      ],
    );
  }
  Widget _info(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case "reorder":
        return Colors.purple;
      case "select_image":
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  void _navigateToGame(String type, dynamic data) {
    print(data);
  }
}