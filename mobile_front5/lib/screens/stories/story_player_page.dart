import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:untitled1/core/api_config.dart';

class StoryPlayerPage extends StatefulWidget {
  final int storyId;
  final String contentTitle;

  const StoryPlayerPage({
    super.key,
    required this.storyId,
    required this.contentTitle,
  });

  @override
  State<StoryPlayerPage> createState() => _StoryPlayerPageState();
}

class _StoryPlayerPageState extends State<StoryPlayerPage> {
  final box = GetStorage();
  final AudioPlayer audioPlayer = AudioPlayer();

  Map<String, dynamic>? story;
  bool isLoading = true;
  bool isSubmitting = false;
  bool quizStarted = false;
  String? loadError;
  int currentQuestionIndex = 0;
  final Map<int, int?> selectedAnswers = {};

  Future<void> _fetchStory() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = box.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/play/stories/${widget.storyId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          story = Map<String, dynamic>.from(decoded['data']);
          isLoading = false;
        });
      } else {
        setState(() {
          loadError = 'تعذر تحميل القصة';
          isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        loadError = 'فشل الاتصال بالسيرفر';
        isLoading = false;
      });
    }
  }

  String _serverBaseFromApi(String apiBase) {
    return apiBase.replaceFirst('/api', '');
  }

  Future<void> _playAudio(String path) async {
    if (path.trim().isEmpty) return;
    final baseUrl = await ApiConfig.getBaseUrl();
    final storyBase = (story?['base_server_url'] ?? '').toString();
    final fileUrl = path.startsWith('http')
        ? path
        : (_buildMediaUrlWithBase(
            path,
            storyBase.isNotEmpty ? storyBase : _serverBaseFromApi(baseUrl),
          ));
    await audioPlayer.stop();
    await audioPlayer.play(UrlSource(fileUrl));
  }

  String _buildMediaUrlWithBase(String path, String baseServer) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    if (normalized.startsWith('storage/')) return '$baseServer/$normalized';
    return '$baseServer/storage/$normalized';
  }

  Future<void> _submitQuiz() async {
    final questions = List<dynamic>.from(story?['questions'] ?? []);
    if (questions.any((q) => selectedAnswers[q['id']] == null)) {
      Get.snackbar(
        'تنبيه',
        'يرجى الإجابة على جميع الأسئلة',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final token = box.read('token');
      final answers = questions
          .map((q) => {
                'question_id': q['id'],
                'answer_id': selectedAnswers[q['id']],
              })
          .toList();

      final response = await http.post(
        Uri.parse('$baseUrl/play/stories/${widget.storyId}/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'answers': answers}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        _showResultDialog(decoded['data']['score']);
      } else {
        Get.snackbar(
          'خطأ',
          'فشل إرسال إجابات القصة',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'خطأ',
        'فشل الاتصال بالسيرفر',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showResultDialog(dynamic score) {
    Get.defaultDialog(
      title: 'أحسنت',
      barrierDismissible: false,
      content: Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 72),
          const SizedBox(height: 12),
          Text(
            'نتيجتك في القصة: $score%',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            score >= 50 ? 'قرأت القصة بشكل رائع وأجبت جيدًا' : 'حاول قراءة القصة مرة أخرى لتحصل على نتيجة أفضل',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      confirm: ElevatedButton(
        onPressed: () {
          Get.back();
          Get.back();
        },
        child: const Text('العودة إلى القصص'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchStory();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storyData = story;
    final questions = List<dynamic>.from(storyData?['questions'] ?? []);
    final contents = List<dynamic>.from(storyData?['contents'] ?? []);
    contents.sort((a, b) {
      final orderA = int.tryParse(a['order']?.toString() ?? '0') ?? 0;
      final orderB = int.tryParse(b['order']?.toString() ?? '0') ?? 0;
      return orderA.compareTo(orderB);
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: Text(storyData?['title'] ?? 'القصة'),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : loadError != null
                ? Center(child: Text(loadError!))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (storyData?['title'] ?? '').toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if ((storyData?['description'] ?? '').toString().trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  storyData!['description'].toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'مشاهد القصة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...contents.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final type = (item['type'] ?? 'text').toString();
                          final filePath = (item['file_path'] ?? '').toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFFDBEAFE),
                                      child: Text('${index + 1}'),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      type == 'image' ? 'صورة' : type == 'audio' ? 'صوت' : 'نص',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if (type == 'text')
                                  Text(
                                    (item['content'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.8,
                                    ),
                                  )
                                else if (type == 'image')
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.network(
                                      _buildMediaUrlWithBase(
                                        filePath,
                                        (storyData?['base_server_url'] ?? '').toString().isNotEmpty
                                            ? (storyData?['base_server_url'] ?? '').toString()
                                            : _serverBaseFromApi('http://127.0.0.1:8000/api'),
                                      ),
                                      height: 240,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                        height: 120,
                                        alignment: Alignment.center,
                                        child: const Text('تعذر عرض الصورة'),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton.filled(
                                          onPressed: () => _playAudio(filePath),
                                          icon: const Icon(Icons.play_arrow),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'استمع إلى المقطع الصوتي المرافق لهذا المشهد',
                                            style: TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => audioPlayer.stop(),
                                          icon: const Icon(Icons.stop),
                                          label: const Text('إيقاف'),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        if (questions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'أسئلة القصة',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  quizStarted
                                      ? 'أجب عن الأسئلة التالية لإكمال القصة.'
                                      : 'بعد الانتهاء من القراءة يمكنك البدء بالإجابة على أسئلة القصة.',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                if (!quizStarted)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => setState(() => quizStarted = true),
                                      icon: const Icon(Icons.quiz),
                                      label: const Text('ابدأ أسئلة القصة'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF16A34A),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  _buildQuizSection(questions),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildQuizSection(List<dynamic> questions) {
    final currentQuestion = questions[currentQuestionIndex];
    final isLast = currentQuestionIndex == questions.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / questions.length,
            minHeight: 9,
            backgroundColor: Colors.grey.shade200,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'السؤال ${currentQuestionIndex + 1} من ${questions.length}',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            (currentQuestion['question'] ?? '').toString(),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List<dynamic>.from(currentQuestion['answers'] ?? []).map((answer) {
          final isSelected = selectedAnswers[currentQuestion['id']] == answer['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: ListTile(
              onTap: () {
                setState(() {
                  selectedAnswers[currentQuestion['id']] = answer['id'];
                });
              },
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? const Color(0xFF2563EB) : Colors.grey,
              ),
              title: Text(
                (answer['answer'] ?? '').toString(),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedAnswers[currentQuestion['id']] == null || isSubmitting
                ? null
                : () {
                    if (isLast) {
                      _submitQuiz();
                    } else {
                      setState(() => currentQuestionIndex++);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isLast ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(isLast ? 'إنهاء وإرسال النتيجة' : 'السؤال التالي'),
          ),
        ),
      ],
    );
  }
}
