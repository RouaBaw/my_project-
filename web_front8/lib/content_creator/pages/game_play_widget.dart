import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GamePlayWidget extends StatefulWidget {

  final Map<String,dynamic> gameData;

  const GamePlayWidget({super.key,required this.gameData});

  @override
  State<GamePlayWidget> createState() => _GamePlayWidgetState();
}

class _GamePlayWidgetState extends State<GamePlayWidget> {

  String fixImageUrl(String url){
    if(url.contains("127.0.0.1")){
      return url.replaceAll("127.0.0.1","localhost");
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {

    final type = widget.gameData["type"];
    final content = widget.gameData["content"];
    final settings =
        Map<String, dynamic>.from(widget.gameData["settings"] ?? {});
    final points = settings['points'] ?? 10;
    final timer = settings['timer'] ?? settings['time_limit'] ?? 30;

    Widget gameBody;
    switch (type) {
      case "select_image":
        gameBody = SelectImageGame(content: content, fixUrl: fixImageUrl);
        break;
      case "reorder":
        gameBody = ReorderWordGame(content: content, fixUrl: fixImageUrl);
        break;
      case "match":
        gameBody = MatchGame(content: content, fixUrl: fixImageUrl);
        break;
      default:
        gameBody = const Center(child: Text("نوع لعبة غير معروف"));
    }

    return Container(
      color: const Color(0xffF7F8FC),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// شريط علوي بسيط لمعلومات اللعبة
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.orange,
                          size: 20.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          "$points نقطة",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Tajawal",
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          color: Colors.blue,
                          size: 20.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          "$timer ثانية",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: "Tajawal",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              /// جسم اللعبة داخل كارد جميل
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: gameBody,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class SelectImageGame extends StatefulWidget {

  final Map content;
  final Function fixUrl;

  const SelectImageGame({super.key,required this.content,required this.fixUrl});

  @override
  State<SelectImageGame> createState() => _SelectImageGameState();
}

class _SelectImageGameState extends State<SelectImageGame> {

  int? selected;
  bool? correct;

  @override
  Widget build(BuildContext context) {

    final question = widget.content["question"];
    final options = widget.content["options"];
    final description = widget.content["description"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontFamily: "Tajawal",
          ),
        ),
        if (description != null && description.toString().isNotEmpty) ...[
          SizedBox(height: 6.h),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[700],
              fontFamily: "Tajawal",
            ),
          ),
        ],
        SizedBox(height: 12.h),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // عرض أقصى مناسب لعرض المتصفح حتى لا تكبر الصور جداً
                maxWidth: 420.w,
              ),
              child: GridView.builder(
                padding: EdgeInsets.all(6.w),
                itemCount: options.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                  // نجعل الكروت مربعة تقريباً ولكن أصغر على الشاشات العريضة
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, index) {
                  final image = widget.fixUrl(options[index]["image"]);
                  final isSelected = selected == index;
                  final isCorrect = correct == true && isSelected;
                  final isWrong = correct == false && isSelected;

                  Color borderColor = Colors.grey.shade300;
                  if (isCorrect) borderColor = Colors.green;
                  if (isWrong) borderColor = Colors.red;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selected = index;
                        correct = options[index]["is_correct"];
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15.r),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: borderColor.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15.r),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                            if (isCorrect || isWrong)
                              Container(
                                color: Colors.black26,
                                child: Center(
                                  child: Icon(
                                    isCorrect
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    color: Colors.white,
                                    size: 40.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (correct != null)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              correct! ? "إجابة صحيحة 🎉" : "حاول مرة أخرى",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: correct! ? Colors.green : Colors.red,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                fontFamily: "Tajawal",
              ),
            ),
          ),
      ],
    );
  }
}
class ReorderWordGame extends StatefulWidget {

  final Map content;
  final Function fixUrl;

  const ReorderWordGame({super.key,required this.content,required this.fixUrl});

  @override
  State<ReorderWordGame> createState() => _ReorderWordGameState();
}

class _ReorderWordGameState extends State<ReorderWordGame> {

  List letters = [];
  List answer = [];

  @override
  void initState() {

    final word = widget.content["word"];

    letters = word.split("")..shuffle();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    final word = widget.content["word"];
    final hint = widget.content["hint"];
    final image = widget.content["image"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (image != null)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: SizedBox(
                width: 260.w,
                height: 180.h,
                child: Image.network(
                  widget.fixUrl(image),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        if (hint != null && hint.toString().isNotEmpty) ...[
          SizedBox(height: 12.h),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              fontFamily: "Tajawal",
            ),
          ),
        ],
        SizedBox(height: 18.h),
        Text(
          "كوّن الكلمة الصحيحة عن طريق ترتيب الحروف:",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[700],
            fontFamily: "Tajawal",
          ),
        ),
        SizedBox(height: 16.h),
        Wrap(
          alignment: WrapAlignment.center,
          children: answer.map((letter) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  letters.add(letter);
                  answer.remove(letter);
                });
              },
              child: letterBox(letter, selected: true),
            );
          }).toList(),
        ),
        SizedBox(height: 20.h),
        Wrap(
          alignment: WrapAlignment.center,
          children: letters.map((e) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  answer.add(e);
                  letters.remove(e);
                });
              },
              child: letterBox(e, selected: false),
            );
          }).toList(),
        ),
        SizedBox(height: 24.h),
        if (answer.join() == word)
          Text(
            "أحسنت 🎉",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24.sp,
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontFamily: "Tajawal",
            ),
          ),
      ],
    );
  }

  Widget letterBox(String letter, {required bool selected}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? Colors.purple.shade400 : Colors.purple.shade50,
        borderRadius: BorderRadius.circular(10),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 22.sp,
          color: selected ? Colors.white : Colors.purple,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}




class MatchGame extends StatefulWidget {
  final Map content;
  final Function fixUrl;

  const MatchGame({super.key, required this.content, required this.fixUrl});

  @override
  State<MatchGame> createState() => _MatchGameState();
}

class _MatchGameState extends State<MatchGame> {

  int? selectedText;

  List images = [];
  List matched = [];

  @override
  void initState() {
    super.initState();

    final pairs = widget.content["pairs"];

    images = List.from(pairs);
    images.shuffle();
  }

  @override
  Widget build(BuildContext context) {

    final pairs = widget.content["pairs"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Text(
          "وصّل الحرف بالصورة المناسبة",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              /// الكلمات
              Expanded(
                child: ListView.builder(
                  itemCount: pairs.length,
                  itemBuilder: (context, i) {
                    bool done = matched.contains(i);
                    bool selected = selectedText == i;

                    return GestureDetector(
                      onTap: done
                          ? null
                          : () {
                              setState(() {
                                selectedText = i;
                              });
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: done
                              ? LinearGradient(colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600,
                                ])
                              : selected
                                  ? LinearGradient(colors: [
                                      Colors.blue.shade400,
                                      Colors.blue.shade600,
                                    ])
                                  : null,
                          color: !done && !selected
                              ? Colors.white
                              : null,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            pairs[i]["text"],
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: done || selected
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              /// الصور
              Expanded(
                child: ListView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap: () {
                        if (selectedText == null) return;

                        bool correct =
                            pairs[selectedText!]["image"] ==
                                images[i]["image"];

                        if (correct) {
                          matched.add(selectedText);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("أحسنت 🎉"),
                              duration: Duration(milliseconds: 700),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("حاول مرة أخرى"),
                            ),
                          );
                        }

                        setState(() {
                          selectedText = null;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 220,
                                maxHeight: 110,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  widget.fixUrl(images[i]["image"]),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        /// نهاية اللعبة
        if (matched.length == pairs.length)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              "🎉 أحسنت! أكملت اللعبة",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
      ],
    );
  }
}