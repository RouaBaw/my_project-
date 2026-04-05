import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:web_front1/content_creator/pages/stories/add_story.dart';

class StoryManagerPage extends StatefulWidget {
  final int pathId;
  final int learningContentId;
  final String contentTitle;

  const StoryManagerPage({
    super.key,
    required this.pathId,
    required this.learningContentId,
    required this.contentTitle,
  });

  @override
  State<StoryManagerPage> createState() => _StoryManagerPageState();
}

class _StoryManagerPageState extends State<StoryManagerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _stories = [];
  dynamic _selectedStory;
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _loadError;

  String get baseUrl {
    if (kIsWeb && Uri.base.host.isNotEmpty) {
      return '${Uri.base.scheme}://${Uri.base.host}:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  String get baseServerUrl {
    if (kIsWeb && Uri.base.host.isNotEmpty) {
      return '${Uri.base.scheme}://${Uri.base.host}:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  @override
  void initState() {
    super.initState();
    _fetchStories();
    _searchCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _fetchStories() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final token = GetStorage().read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/courses_stories/${widget.learningContentId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> fetchedStories = decoded is Map<String, dynamic>
            ? (decoded['data'] as List? ?? [])
            : (decoded as List? ?? []);

        setState(() {
          _stories = fetchedStories;
          if (_stories.isEmpty) {
            _selectedStory = null;
          } else {
            final currentId = _selectedStory?['id'];
            _selectedStory = _stories.firstWhereOrNull(
                  (story) => story['id'] == currentId,
                ) ??
                _stories.first;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _loadError = 'فشل تحميل القصص (${response.statusCode})';
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
        _loadError = 'تعذر الاتصال بالسيرفر';
      });
    }
  }

  List<dynamic> get _filteredStories {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _stories;

    return _stories.where((story) {
      final title = (story['title'] ?? '').toString().toLowerCase();
      final desc = (story['description'] ?? '').toString().toLowerCase();
      final status = (story['status'] ?? '').toString().toLowerCase();
      return title.contains(query) || desc.contains(query) || status.contains(query);
    }).toList(growable: false);
  }

  List<dynamic> _storyContents(dynamic story) {
    final List<dynamic> items = List<dynamic>.from(story['contents'] ?? []);
    items.sort((a, b) {
      final orderA = int.tryParse(a['order']?.toString() ?? '0') ?? 0;
      final orderB = int.tryParse(b['order']?.toString() ?? '0') ?? 0;
      return orderA.compareTo(orderB);
    });
    return items;
  }

  List<dynamic> _storyQuestions(dynamic story) {
    return List<dynamic>.from(story['questions'] ?? []);
  }

  String _mediaUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    final normalized = path.startsWith('/') ? path.substring(1) : path;
    if (normalized.startsWith('storage/')) {
      return '$baseServerUrl/$normalized';
    }
    return '$baseServerUrl/storage/$normalized';
  }

  bool _isCorrect(dynamic value) {
    return value == true || value == 1 || value == '1';
  }

  Future<void> _openAddStory() async {
    final created = await Get.to<bool>(
      () => StoryFormPage(
        pathId: widget.pathId,
        learningContentId: widget.learningContentId,
        closeOnSuccess: true,
      ),
    );

    if (created == true) {
      await _fetchStories();
      Get.snackbar(
        'نجاح',
        'تمت إضافة القصة بنجاح',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteStory(int id) async {
    setState(() => _isDeleting = true);
    try {
      final token = GetStorage().read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/stories/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _fetchStories();
        Get.snackbar(
          'تم',
          'تم حذف القصة',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'خطأ',
          'تعذر حذف القصة',
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
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _confirmDelete(dynamic story) {
    Get.defaultDialog(
      title: 'حذف القصة',
      middleText: 'هل تريد حذف "${story['title'] ?? 'هذه القصة'}"؟',
      textConfirm: 'حذف',
      textCancel: 'إلغاء',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        _deleteStory(story['id']);
      },
    );
  }

  Future<void> _playAudio(String url) async {
    if (url.isEmpty) return;
    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(url));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.of(context).size.width < 1100;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدارة القصص',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                widget.contentTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12.sp,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _fetchStories,
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(18.w),
          child: isNarrow
              ? Column(
                  children: [
                    SizedBox(height: 360.h, child: _buildStoriesPanel(cs)),
                    SizedBox(height: 16.h),
                    Expanded(child: _buildPreviewPanel(cs)),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 3, child: _buildStoriesPanel(cs)),
                    SizedBox(width: 16.w),
                    Expanded(flex: 4, child: _buildPreviewPanel(cs)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStoriesPanel(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'قصص هذا المحتوى',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    _pill(
                      cs,
                      icon: Icons.auto_stories_outlined,
                      text: '${_stories.length}',
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن قصة بالعنوان أو الوصف...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openAddStory,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'إضافة قصة جديدة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_loadError != null) {
                  return _stateCard(
                    icon: Icons.error_outline,
                    title: 'حدث خطأ',
                    subtitle: _loadError!,
                    buttonLabel: 'إعادة المحاولة',
                    onPressed: _fetchStories,
                  );
                }

                if (_stories.isEmpty) {
                  return _stateCard(
                    icon: Icons.menu_book_outlined,
                    title: 'لا توجد قصص بعد',
                    subtitle: 'يمكنك إضافة أول قصة لهذا المحتوى من الزر العلوي.',
                    buttonLabel: 'إضافة قصة',
                    onPressed: _openAddStory,
                  );
                }

                final items = _filteredStories;
                if (items.isEmpty) {
                  return _stateCard(
                    icon: Icons.search_off,
                    title: 'لا توجد نتائج',
                    subtitle: 'جرّب تعديل كلمة البحث.',
                    buttonLabel: 'مسح البحث',
                    onPressed: () => _searchCtrl.clear(),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(14.w),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) => _buildStoryCard(items[index], index, cs),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(dynamic story, int index, ColorScheme cs) {
    final title = (story['title'] ?? '').toString();
    final description = (story['description'] ?? '').toString();
    final isSelected = _selectedStory?['id'] == story['id'];
    final contentsCount = (story['contents'] as List?)?.length ?? 0;
    final questionsCount = (story['questions'] as List?)?.length ?? 0;

    return InkWell(
      onTap: () => setState(() => _selectedStory = story),
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF60A5FA) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'بدون عنوان' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (description.trim().isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12.sp,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      _smallBadge(cs, '$contentsCount مشهد'),
                      _smallBadge(cs, '$questionsCount سؤال'),
                      _statusBadge((story['status'] ?? 'draft').toString()),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _isDeleting ? null : () => _confirmDelete(story),
              tooltip: 'حذف',
              icon: Icon(
                Icons.delete_outline,
                color: _isDeleting ? Colors.grey : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewPanel(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _selectedStory == null
          ? _stateCard(
              icon: Icons.visibility_outlined,
              title: 'معاينة القصة',
              subtitle: _stories.isEmpty
                  ? 'أضف قصة جديدة لتظهر هنا.'
                  : 'اختر قصة من القائمة لعرض محتواها بالتسلسل.',
              buttonLabel: _stories.isEmpty ? 'إضافة قصة' : 'تحديث',
              onPressed: _stories.isEmpty ? _openAddStory : _fetchStories,
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreviewHeader(cs, _selectedStory),
                  SizedBox(height: 20.h),
                  Text(
                    'تسلسل القصة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ..._buildStorySequence(cs, _selectedStory),
                  SizedBox(height: 24.h),
                  _buildQuestionsSection(_selectedStory),
                ],
              ),
            ),
    );
  }

  Widget _buildPreviewHeader(ColorScheme cs, dynamic story) {
    final contentsCount = (story['contents'] as List?)?.length ?? 0;
    final questionsCount = (story['questions'] as List?)?.length ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (story['title'] ?? 'بدون عنوان').toString(),
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          if ((story['description'] ?? '').toString().trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              story['description'].toString(),
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13.sp,
                color: Colors.white.withValues(alpha: 0.92),
                height: 1.6,
              ),
            ),
          ],
          SizedBox(height: 14.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _headerChip(Icons.view_agenda_outlined, '$contentsCount عنصر'),
              _headerChip(Icons.quiz_outlined, '$questionsCount سؤال'),
              _headerChip(Icons.flag_outlined, _statusLabel((story['status'] ?? 'draft').toString())),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStorySequence(ColorScheme cs, dynamic story) {
    final items = _storyContents(story);
    if (items.isEmpty) {
      return [_emptyBlock('لا يوجد محتوى داخل هذه القصة بعد')];
    }

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final type = (item['type'] ?? 'text').toString();
      final fileUrl = _mediaUrl(item['file_path']?.toString());

      return Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: cs.primary.withValues(alpha: 0.12),
                  foregroundColor: cs.primary,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  _contentTypeLabel(type),
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            if (type == 'text')
              Text(
                (item['content'] ?? '').toString(),
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14.sp,
                  height: 1.8,
                  color: const Color(0xFF1E293B),
                ),
              )
            else if (type == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: fileUrl.isEmpty
                    ? _emptyBlock('لا يوجد رابط صورة صالح')
                    : Image.network(
                        fileUrl,
                        height: 260.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _emptyBlock('تعذر عرض الصورة'),
                      ),
              )
            else
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    IconButton.filled(
                      onPressed: fileUrl.isEmpty ? null : () => _playAudio(fileUrl),
                      icon: const Icon(Icons.play_arrow),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        fileUrl.isEmpty
                            ? 'لا يوجد ملف صوتي صالح'
                            : 'تشغيل المقطع الصوتي الخاص بهذا المشهد',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _audioPlayer.stop(),
                      icon: const Icon(Icons.stop),
                      label: const Text('إيقاف'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildQuestionsSection(dynamic story) {
    final questions = _storyQuestions(story);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأسئلة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 12.h),
        if (questions.isEmpty)
          _emptyBlock('لا توجد أسئلة مرفقة بهذه القصة')
        else
          ...questions.asMap().entries.map((entry) {
            final qIndex = entry.key;
            final question = entry.value;
            final answers = List<dynamic>.from(question['answers'] ?? []);

            return Container(
              margin: EdgeInsets.only(bottom: 14.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سؤال ${qIndex + 1}',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12.sp,
                      color: const Color(0xFF92400E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    (question['question'] ?? '').toString(),
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ...answers.map((answer) {
                    final correct = _isCorrect(answer['is_correct']);
                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: correct ? const Color(0xFFDCFCE7) : Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: correct ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            correct ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: correct ? const Color(0xFF15803D) : Colors.grey,
                            size: 18.w,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              (answer['answer'] ?? '').toString(),
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13.sp,
                                fontWeight: correct ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _headerChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.w, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallBadge(ColorScheme cs, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;

    switch (status.toLowerCase().trim()) {
      case 'published':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        break;
      case 'reviewed':
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0369A1);
        break;
      default:
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFF9A3412);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontFamily: 'Tajawal',
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 12.sp,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase().trim()) {
      case 'published':
        return 'منشورة';
      case 'reviewed':
        return 'قيد المراجعة';
      default:
        return 'مسودة';
    }
  }

  String _contentTypeLabel(String type) {
    switch (type) {
      case 'image':
        return 'صورة';
      case 'audio':
        return 'صوت';
      default:
        return 'نص';
    }
  }

  Widget _pill(ColorScheme cs, {required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.w, color: cs.primary),
          SizedBox(width: 6.w),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBlock(String text) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Tajawal',
          color: Colors.grey.shade700,
          fontSize: 13.sp,
        ),
      ),
    );
  }

  Widget _stateCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420.w),
          child: Container(
            padding: EdgeInsets.all(22.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62.w,
                  height: 62.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Icon(icon, size: 32.w, color: const Color(0xFF4F46E5)),
                ),
                SizedBox(height: 14.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13.sp,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w900,
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
}
