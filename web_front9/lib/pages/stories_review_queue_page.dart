import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class StoriesReviewQueuePage extends StatefulWidget {
  final int? learningContentId;
  final String? contentTitle;

  const StoriesReviewQueuePage({
    super.key,
    this.learningContentId,
    this.contentTitle,
  });

  @override
  State<StoriesReviewQueuePage> createState() => _StoriesReviewQueuePageState();
}

class _StoriesReviewQueuePageState extends State<StoriesReviewQueuePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _stories = [];
  dynamic _selectedStory;
  bool _isLoading = true;
  bool _isUpdating = false;
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
      final String url = widget.learningContentId != null
          ? '$baseUrl/courses_stories/${widget.learningContentId}?status=reviewed'
          : '$baseUrl/stories-review-queue';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final stories = decoded is Map<String, dynamic>
            ? (decoded['data'] as List? ?? [])
            : (decoded as List? ?? []);

        setState(() {
          _stories = stories;
          if (_stories.isEmpty) {
            _selectedStory = null;
          } else {
            final selectedId = _selectedStory?['id'];
            _selectedStory = _stories.firstWhereOrNull(
                  (story) => story['id'] == selectedId,
                ) ??
                _stories.first;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _loadError = 'فشل تحميل القصص (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _loadError = 'تعذر الاتصال بالسيرفر';
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredStories {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _stories;

    return _stories.where((story) {
      final title = (story['title'] ?? '').toString().toLowerCase();
      final description = (story['description'] ?? '').toString().toLowerCase();
      final courseTitle = (story['learning_content']?['title'] ??
              story['learning_content']?['course_name'] ??
              '')
          .toString()
          .toLowerCase();
      return title.contains(query) ||
          description.contains(query) ||
          courseTitle.contains(query);
    }).toList(growable: false);
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

  Future<void> _reviewStory(int storyId, String status) async {
    setState(() => _isUpdating = true);
    try {
      final token = GetStorage().read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/stories/$storyId/review'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _stories = _stories
                .where((story) => story['id'] != storyId)
                .toList(growable: false);
            if (_selectedStory != null && _selectedStory['id'] == storyId) {
              _selectedStory = _stories.isEmpty ? null : _stories.first;
            }
          });
        }
        await _fetchStories();
        Get.snackbar(
          'تم',
          status == 'published' ? 'تم قبول القصة' : 'تم رفض القصة',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'خطأ',
          'فشل تحديث حالة القصة',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      Get.snackbar(
        'خطأ',
        'تعذر الاتصال بالسيرفر',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
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
    final isNarrow = MediaQuery.of(context).size.width < 1180;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        body: Padding(
          padding: EdgeInsets.all(18.w),
          child: isNarrow
              ? Column(
                  children: [
                    SizedBox(height: 370.h, child: _buildStoriesPanel(cs)),
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
    final title = widget.contentTitle == null ? 'قصص بانتظار المراجعة' : 'قصص المحتوى';
    final subtitle = widget.contentTitle ?? 'راجع القصص ثم اقبلها أو ارفضها بعد الاطلاع على التفاصيل.';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.sp,
                    height: 1.5,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'بحث بعنوان القصة أو اسم المحتوى...',
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
                Row(
                  children: [
                    _pill(cs, Icons.pending_actions_outlined, '${_stories.length}'),
                    const Spacer(),
                    IconButton(
                      onPressed: _fetchStories,
                      tooltip: 'تحديث',
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
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
                    icon: Icons.auto_stories_outlined,
                    title: 'لا توجد قصص جاهزة للمراجعة',
                    subtitle: 'ستظهر هنا القصص التي يرسلها صانع المحتوى للمراجعة.',
                    buttonLabel: 'تحديث',
                    onPressed: _fetchStories,
                  );
                }

                final items = _filteredStories;
                if (items.isEmpty) {
                  return _stateCard(
                    icon: Icons.search_off,
                    title: 'لا توجد نتائج',
                    subtitle: 'عدّل كلمات البحث ثم حاول مرة أخرى.',
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
    final courseTitle =
        (story['learning_content']?['title'] ?? story['learning_content']?['course_name'] ?? 'محتوى غير معروف')
            .toString();
    final pathTitle =
        (story['learning_content']?['learning_path']?['title'] ?? 'مسار غير محدد').toString();
    final isSelected = _selectedStory?['id'] == story['id'];

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12.r),
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
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    title.isEmpty ? 'بدون عنوان' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _statusChip((story['status'] ?? 'reviewed').toString()),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              courseTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: const Color(0xFF2563EB),
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              pathTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.grey.shade600,
                fontSize: 11.sp,
              ),
            ),
            if (description.trim().isNotEmpty) ...[
              SizedBox(height: 8.h),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewPanel(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
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
              title: 'تفاصيل القصة',
              subtitle: 'اختر قصة من القائمة للاطلاع على المشاهد والأسئلة واتخاذ قرار المراجعة.',
              buttonLabel: 'تحديث',
              onPressed: _fetchStories,
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(cs, _selectedStory),
                  SizedBox(height: 18.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isUpdating
                              ? null
                              : () => _reviewStory(_selectedStory['id'], 'published'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'قبول ونشر القصة',
                            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUpdating
                              ? null
                              : () => _reviewStory(_selectedStory['id'], 'draft'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB91C1C),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                          icon: const Icon(Icons.close_rounded),
                          label: const Text(
                            'رفض وإعادة للمسودة',
                            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    'تسلسل القصة',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  ..._buildStoryContent(cs, _selectedStory),
                  SizedBox(height: 24.h),
                  _buildQuestionsSection(_selectedStory),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(ColorScheme cs, dynamic story) {
    final creatorName =
        '${story['creator']?['first_name'] ?? ''} ${story['creator']?['last_name'] ?? ''}'.trim();
    final courseTitle =
        (story['learning_content']?['title'] ?? story['learning_content']?['course_name'] ?? '')
            .toString();

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
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          if ((story['description'] ?? '').toString().trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              story['description'].toString(),
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.white.withValues(alpha: 0.92),
                height: 1.6,
                fontSize: 13.sp,
              ),
            ),
          ],
          SizedBox(height: 14.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _headerChip(Icons.menu_book_outlined, courseTitle.isEmpty ? 'محتوى غير معروف' : courseTitle),
              if (creatorName.isNotEmpty) _headerChip(Icons.person_outline, creatorName),
              _headerChip(
                Icons.flag_outlined,
                _statusLabel((story['status'] ?? 'reviewed').toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStoryContent(ColorScheme cs, dynamic story) {
    final items = List<dynamic>.from(story['contents'] ?? []);
    items.sort((a, b) {
      final orderA = int.tryParse(a['order']?.toString() ?? '0') ?? 0;
      final orderB = int.tryParse(b['order']?.toString() ?? '0') ?? 0;
      return orderA.compareTo(orderB);
    });

    if (items.isEmpty) return [_emptyBlock('لا يوجد محتوى لهذه القصة')];

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
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: cs.primary.withValues(alpha: 0.10),
                  foregroundColor: cs.primary,
                  child: Text('${index + 1}'),
                ),
                SizedBox(width: 10.w),
                Text(
                  type == 'image' ? 'صورة' : type == 'audio' ? 'صوت' : 'نص',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w900,
                    fontSize: 15.sp,
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
                ),
              )
            else if (type == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: fileUrl.isEmpty
                    ? _emptyBlock('تعذر عرض الصورة')
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
                        fileUrl.isEmpty ? 'لا يوجد ملف صوت صالح' : 'تشغيل المقطع الصوتي',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.sp,
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
    final questions = List<dynamic>.from(story['questions'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأسئلة المرفقة',
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

  String _statusLabel(String status) {
    switch (status) {
      case 'published':
        return 'منشورة';
      case 'draft':
        return 'مسودة';
      case 'reviewed':
      default:
        return 'قيد المراجعة';
    }
  }

  ({Color bg, Color fg}) _statusColors(String status) {
    switch (status) {
      case 'published':
        return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF15803D));
      case 'draft':
        return (bg: const Color(0xFFFEE2E2), fg: const Color(0xFFB91C1C));
      case 'reviewed':
      default:
        return (bg: const Color(0xFFE0F2FE), fg: const Color(0xFF0369A1));
    }
  }

  Widget _statusChip(String status) {
    final colors = _statusColors(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontFamily: 'Tajawal',
          color: colors.fg,
          fontWeight: FontWeight.w900,
          fontSize: 11.sp,
        ),
      ),
    );
  }

  Widget _pill(ColorScheme cs, IconData icon, String text) {
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
