import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:untitled1/core/api_config.dart';

class GamePlayWidget extends StatefulWidget {
  final Map<String, dynamic> gameData;

  const GamePlayWidget({super.key, required this.gameData});

  @override
  State<GamePlayWidget> createState() => _GamePlayWidgetState();
}

class _GamePlayWidgetState extends State<GamePlayWidget> {
  String? baseUrl;
  bool isLoading = true;
  bool _isSubmittingResult = false;

  // متغيرات الوقت
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

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

  String fixImageUrl(String url) {
    if (baseUrl == null) return url;
    String cleanBase = baseUrl!.replaceAll(':8000', '').replaceAll('http://', '');
    return url.replaceAll('127.0.0.1', cleanBase).replaceAll('localhost', cleanBase).replaceAll('/api', '');
  }

  int _calculateScore(int elapsedSeconds) {
    const int baseScore = 10;
    if (elapsedSeconds <= 10) return baseScore;
    final int delayedSeconds = elapsedSeconds - 10;
    final int deduction = delayedSeconds ~/ 3;
    final int finalScore = baseScore - deduction;
    return finalScore < 0 ? 0 : finalScore;
  }

  Future<Map<String, dynamic>> _submitResult({
    required int gameId,
    required int score,
    required int timeTaken,
  }) async {
    try {
      final apiBaseUrl = await ApiConfig.getBaseUrl();
      final token = GetStorage().read('token');
      final response = await http.post(
        Uri.parse('$apiBaseUrl/play/game/$gameId/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'score': score,
          'time_taken': timeTaken,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'تم حفظ النتيجة بنجاح',
        };
      }

      String message = 'تم إنهاء اللعبة لكن تعذر حفظ النتيجة';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}

      return {
        'success': false,
        'message': message,
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'تم إنهاء اللعبة لكن حدث خطأ أثناء الاتصال بالسيرفر',
      };
    }
  }

  // دالة تظهر عند الفوز
  Future<void> _onGameWin() async {
    if (_isSubmittingResult) return;
    _isSubmittingResult = true;
    _timer?.cancel();

    final int finalScore = _calculateScore(_elapsedSeconds);
    final dynamic gameIdRaw = widget.gameData['id'];
    final int? gameId = gameIdRaw is int ? gameIdRaw : int.tryParse(gameIdRaw?.toString() ?? '');

    Map<String, dynamic> submitResult = {
      'success': false,
      'message': 'تم إنهاء اللعبة بنجاح',
    };

    if (gameId != null) {
      submitResult = await _submitResult(
        gameId: gameId,
        score: finalScore,
        timeTaken: _elapsedSeconds,
      );
    } else {
      submitResult = {
        'success': false,
        'message': 'تم إنهاء اللعبة لكن لم يتم العثور على معرف اللعبة للإرسال',
      };
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text("تهانينا! 🎉", textAlign: TextAlign.center, style: TextStyle(fontFamily: "Tajawal")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("لقد أتممت المهمة بنجاح", textAlign: TextAlign.center),
            SizedBox(height: 10.h),
            Text("الوقت المستغرق: $_elapsedSeconds ثانية",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: Colors.blue)),
            SizedBox(height: 8.h),
            Text("النقاط التي حصلت عليها: $finalScore / 10",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: Colors.orange)),
            SizedBox(height: 8.h),
            Text(
              submitResult['message']?.toString() ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: submitResult['success'] == true ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // إغلاق الديالوج
              Navigator.pop(context); // العودة للشاشة السابقة
            },
            child: const Text("حسناً"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final type = widget.gameData["type"];
    final content = widget.gameData["content"];
    final settings = Map<String, dynamic>.from(widget.gameData["settings"] ?? {});
    final points = settings['points'] ?? 10;

    Widget gameBody;
    switch (type) {
      case "select_image":
        gameBody = SelectImageGame(content: content, fixUrl: fixImageUrl, onWin: _onGameWin);
        break;
      case "reorder":
        gameBody = ReorderWordGame(content: content, fixUrl: fixImageUrl, onWin: _onGameWin);
        break;
      case "match":
        gameBody = MatchGame(content: content, fixUrl: fixImageUrl, onWin: _onGameWin);
        break;
      default:
        gameBody = const Center(child: Text("نوع لعبة غير معروف"));
    }

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FC),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _buildTopBar(points, _elapsedSeconds),
              SizedBox(height: 16.h),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22.r),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: gameBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(int points, int seconds) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18.r)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _infoItem(Icons.star_rounded, Colors.orange, "$points نقطة"),
          _infoItem(Icons.timer_rounded, Colors.blue, "$seconds ثانية"),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20.sp),
        SizedBox(width: 6.w),
        Text(text, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, fontFamily: "Tajawal")),
      ],
    );
  }
}

// --- تم تعديل الألعاب لإرسال تنبيه الفوز ---

class SelectImageGame extends StatefulWidget {
  final Map content;
  final String Function(String) fixUrl;
  final VoidCallback onWin;

  const SelectImageGame({super.key, required this.content, required this.fixUrl, required this.onWin});

  @override
  State<SelectImageGame> createState() => _SelectImageGameState();
}

class _SelectImageGameState extends State<SelectImageGame> {
  int? selected;
  @override
  Widget build(BuildContext context) {
    final options = widget.content["options"];
    return Column(
      children: [
        Text(widget.content["question"], style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 20.h),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: options.length,
            itemBuilder: (context, index) {
              bool isCorrect = options[index]["is_correct"] == true;
              return GestureDetector(
                onTap: () {
                  setState(() => selected = index);
                  if (isCorrect) {
                    Future.delayed(const Duration(milliseconds: 500), widget.onWin);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: selected == index ? (isCorrect ? Colors.green : Colors.red) : Colors.grey.shade300, width: 3),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.network(widget.fixUrl(options[index]["image"]), fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}

class ReorderWordGame extends StatefulWidget {
  final Map content;
  final String Function(String) fixUrl;
  final VoidCallback onWin;

  const ReorderWordGame({super.key, required this.content, required this.fixUrl, required this.onWin});

  @override
  State<ReorderWordGame> createState() => _ReorderWordGameState();
}

class _ReorderWordGameState extends State<ReorderWordGame> {
  List<String> letters = [];
  List<String> answer = [];
  late String originalWord;

  @override
  void initState() {
    super.initState();
    originalWord = widget.content["word"] ?? "";
    letters = originalWord.split("")..shuffle();
  }

  void _checkWin() {
    if (answer.join() == originalWord) {
      Future.delayed(const Duration(milliseconds: 500), widget.onWin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.content["image"] != null)
          Image.network(widget.fixUrl(widget.content["image"]), height: 120.h),
        SizedBox(height: 20.h),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: 8,
            children: answer.asMap().entries.map((e) => GestureDetector(
              onTap: () => setState(() {
                letters.add(e.value);
                answer.removeAt(e.key);
              }),
              child: _box(e.value, true),
            )).toList(),
          ),
        ),
        const Divider(height: 40),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: 8,
            children: letters.asMap().entries.map((e) => GestureDetector(
              onTap: () => setState(() {
                answer.add(e.value);
                letters.removeAt(e.key);
                _checkWin();
              }),
              child: _box(e.value, false),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _box(String s, bool active) => Container(
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(color: active ? Colors.purple : Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
    child: Text(s, style: TextStyle(color: active ? Colors.white : Colors.purple, fontWeight: FontWeight.bold, fontSize: 18.sp)),
  );
}

class MatchGame extends StatefulWidget {
  final Map content;
  final String Function(String) fixUrl;
  final VoidCallback onWin;

  const MatchGame({super.key, required this.content, required this.fixUrl, required this.onWin});

  @override
  State<MatchGame> createState() => _MatchGameState();
}

class _MatchGameState extends State<MatchGame> {
  int? selectedTextIndex;
  List matchedIndices = [];
  List shuffledImages = [];

  @override
  void initState() {
    super.initState();
    shuffledImages = List.from(widget.content["pairs"])..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    final pairs = widget.content["pairs"];
    return Row(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: pairs.length,
            itemBuilder: (context, i) {
              bool done = matchedIndices.contains(i);
              return GestureDetector(
                onTap: done ? null : () => setState(() => selectedTextIndex = i),
                child: Container(
                  margin: EdgeInsets.all(5.w),
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: done ? Colors.green.shade100 : (selectedTextIndex == i ? Colors.blue.shade100 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(pairs[i]["text"], textAlign: TextAlign.center),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: shuffledImages.length,
            itemBuilder: (context, i) {
              return GestureDetector(
                onTap: () {
                  if (selectedTextIndex == null) return;
                  if (pairs[selectedTextIndex!]["image"] == shuffledImages[i]["image"]) {
                    setState(() {
                      matchedIndices.add(selectedTextIndex);
                      selectedTextIndex = null;
                    });
                    if (matchedIndices.length == pairs.length) {
                      Future.delayed(const Duration(milliseconds: 500), widget.onWin);
                    }
                  }
                },
                child: Container(
                  margin: EdgeInsets.all(5.w),
                  height: 80.h,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200)),
                  child: Image.network(widget.fixUrl(shuffledImages[i]["image"])),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}