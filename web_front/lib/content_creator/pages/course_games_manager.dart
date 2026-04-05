import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_front1/content_creator/pages/GamePreviewSheet.dart';

class CourseGamesManager extends StatefulWidget {
  final int learningContentId;
  final String contentTitle;

  const CourseGamesManager({super.key, required this.learningContentId, required this.contentTitle});

  @override
  State<CourseGamesManager> createState() => _CourseGamesManagerState();
}

class _CourseGamesManagerState extends State<CourseGamesManager> {
  List<dynamic> gamesList = [];
  bool isLoading = true;
  bool isSaving = false;
  String? loadError;
  final String baseUrl = 'http://127.0.0.1:8000/api';

  final TextEditingController _searchCtrl = TextEditingController();

  // الحقول العامة
  final _titleController = TextEditingController();
  String _selectedType = 'reorder';

  // حقول Reorder
  final _wordController = TextEditingController();
  final _hintController = TextEditingController();
  String? _reorderImageUrl;

  // حقول Select Image
  final _questionController = TextEditingController();
  List<Map<String, dynamic>> _options = [];

  // حقول Match
  List<Map<String, dynamic>> _pairs = [];

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  // --- دالات الـ API (Fetch, Upload, Save, Delete) ---
  // (تبقى كما هي في كودكِ السابق مع التأكد من روابط الـ URL)

  Future<void> _fetchGames() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final token = GetStorage().read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/courses_games/${widget.learningContentId}'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
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

  List<dynamic> get _filteredGames {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return gamesList;
    return gamesList.where((g) {
      final title = (g['title'] ?? '').toString().toLowerCase();
      final type = (g['type'] ?? '').toString().toLowerCase();
      return title.contains(q) || type.contains(q);
    }).toList(growable: false);
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'reorder':
        return 'ترتيب كلمات';
      case 'select_image':
        return 'اختيار صورة';
      case 'match':
        return 'توصيل';
      default:
        return t;
    }
  }

  Future<String?> _uploadFile() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    try {
      final token = GetStorage().read('token');
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/media/upload'));
      request.headers.addAll({'Authorization': 'Bearer $token', 'Accept': 'application/json'});
      var bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: image.name));
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);
      if (response.statusCode == 201 || response.statusCode == 200) return jsonResponse['url'];
    } catch (e) { Get.snackbar("خطأ", "فشل رفع الصورة"); }
    return null;
  }

  Future<void> _saveNewGame() async {
    if (_titleController.text.isEmpty) { Get.snackbar("تنبيه", "العنوان مطلوب"); return; }
    setState(() => isSaving = true);

    Map<String, dynamic> gameContent = {};
    if (_selectedType == 'reorder') {
      gameContent = {"word": _wordController.text, "hint": _hintController.text, "image": _reorderImageUrl ?? ""};
    } else if (_selectedType == 'select_image') {
      gameContent = {"question": _questionController.text, "options": _options};
    } else if (_selectedType == 'match') {
      gameContent = {"pairs": _pairs};
    }

    try {
      final token = GetStorage().read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/games'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'learning_content_id': widget.learningContentId,
          'title': _titleController.text,
          'type': _selectedType,
          'content': gameContent,
          'settings': {"points": 10},
          'status': 'published'
        }),
      );
      if (response.statusCode == 201) { _clearForm(); _fetchGames(); Get.snackbar("نجاح", "تم الحفظ"); }
    } finally { setState(() => isSaving = false); }
  }

  void _clearForm() {
    _titleController.clear(); _wordController.clear(); _hintController.clear();
    _questionController.clear(); _reorderImageUrl = null; _options = []; _pairs = [];
    setState(() {});
  }

  // --- بناء الواجهة ---

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = MediaQuery.of(context).size.width;
    final isNarrow = w < 950;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إدارة الألعاب',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 18.sp, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 2.h),
              Text(
                widget.contentTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 12.sp, color: Colors.grey.shade700),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _fetchGames,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(18.w),
          child: isNarrow
              ? Column(
                  children: [
                    Expanded(child: _buildGamesPanel(cs)),
                    SizedBox(height: 14.h),
                    SizedBox(height: 420.h, child: _buildCreatePanel(cs)),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 3, child: _buildGamesPanel(cs)),
                    SizedBox(width: 16.w),
                    SizedBox(width: 460.w, child: _buildCreatePanel(cs)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildGamesPanel(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Expanded(child: _buildSearchField(cs)),
                SizedBox(width: 10.w),
                _pill(
                  cs,
                  icon: Icons.videogame_asset_outlined,
                  text: '${gamesList.length}',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Builder(
              builder: (context) {
                if (isLoading) {
                  return Center(
                    child: SizedBox(
                      width: 40.w,
                      height: 40.w,
                      child: CircularProgressIndicator(color: cs.primary),
                    ),
                  );
                }

                if (loadError != null) {
                  return _stateCard(
                    title: 'حدث خطأ',
                    subtitle: loadError!,
                    primaryLabel: 'إعادة المحاولة',
                    onPrimary: _fetchGames,
                  );
                }

                final items = _filteredGames;
                if (gamesList.isEmpty) {
                  return _stateCard(
                    title: 'لا توجد ألعاب بعد',
                    subtitle: 'أضف لعبة جديدة من لوحة الإنشاء على اليمين.',
                    primaryLabel: 'تحديث',
                    onPrimary: _fetchGames,
                  );
                }
                if (items.isEmpty) {
                  return _stateCard(
                    title: 'لا توجد نتائج',
                    subtitle: 'جرّب تعديل كلمات البحث.',
                    primaryLabel: 'مسح البحث',
                    onPrimary: () => _searchCtrl.clear(),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.all(14.w),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) => _buildGameCard(items[index], index, cs),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePanel(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _panelHeader(cs),
            SizedBox(height: 14.h),
            _buildFormHeader(cs),
            SizedBox(height: 14.h),
            const Divider(height: 1),
            SizedBox(height: 14.h),
            _buildDynamicForm(cs),
            SizedBox(height: 18.h),
            _buildSaveButton(cs),
          ],
        ),
      ),
    );
  }

  Widget _panelHeader(ColorScheme cs) {
    return Row(
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(Icons.add, color: cs.primary, size: 24.w),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إنشاء لعبة جديدة',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 16.sp, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
              ),
              SizedBox(height: 2.h),
              Text(
                'اختر النوع ثم املأ البيانات واحفظ اللعبة.',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 12.sp, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: _clearForm,
          icon: const Icon(Icons.restart_alt),
          label: const Text('تفريغ', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _buildGameCard(dynamic game, int index, ColorScheme cs) {
    final title = (game['title'] ?? '').toString();
    final type = (game['type'] ?? '').toString();
    final status = (game['status'] ?? 'draft').toString();

    return InkWell(
      onTap: () => _showGamePreview(game),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w900, color: cs.primary),
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
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), fontSize: 14.sp),
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      _badge(cs, _typeLabel(type)),
                      _statusBadge(status),
                      Icon(Icons.visibility_outlined, size: 16.w, color: Colors.grey.shade600),
                      Text('معاينة', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12.sp, color: Colors.grey.shade700)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'حذف',
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(game['id']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormHeader(ColorScheme cs) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedType,
          decoration: InputDecoration(
            labelText: "نوع اللعبة",
            labelStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
          items: const [
            DropdownMenuItem(value: 'reorder', child: Text("ترتيب كلمات")),
            DropdownMenuItem(value: 'select_image', child: Text("اختيار صورة")),
            DropdownMenuItem(value: 'match', child: Text("توصيل")),
          ],
          onChanged: (val) => setState(() => _selectedType = val!),
        ),
        SizedBox(height: 15.h),
        TextField(
          controller: _titleController,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(
            labelText: "عنوان اللعبة",
            labelStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800),
            hintText: 'مثال: رتّب الحروف',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicForm(ColorScheme cs) {
    if (_selectedType == 'reorder') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _wordController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: "الكلمة المراد ترتيبها",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          SizedBox(height: 10.h),
          TextField(
            controller: _hintController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: "تلميح (اختياري)",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          SizedBox(height: 10.h),
          if (_reorderImageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Image.network(_reorderImageUrl!, height: 140.h, fit: BoxFit.cover),
            ),
            SizedBox(height: 10.h),
          ],
          OutlinedButton.icon(
            onPressed: () async {
              var url = await _uploadFile();
              if (url != null) setState(() => _reorderImageUrl = url);
            },
            icon: const Icon(Icons.image_outlined),
            label: const Text("رفع صورة توضيحية", style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
          ),
        ],
      );
    } else if (_selectedType == 'select_image') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _questionController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: "نص السؤال",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          const Divider(),
          ..._options.asMap().entries.map((entry) {
            int idx = entry.key;
            var opt = entry.value;
            return ListTile(
              leading: Image.network(opt['image'], width: 40.w),
              title: Text("خيار ${idx + 1}", style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
              trailing: Checkbox(
                value: opt['is_correct'],
                onChanged: (val) => setState(() => _options[idx]['is_correct'] = val),
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: () async {
              var url = await _uploadFile();
              if (url != null) setState(() => _options.add({"image": url, "is_correct": false}));
            },
            icon: const Icon(Icons.add_a_photo),
            label: const Text("إضافة خيار صورة", style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._pairs.asMap().entries.map((entry) {
            int idx = entry.key;
            return Row(
              children: [
                Expanded(child: TextField(
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: "الكلمة",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                  onChanged: (v) => _pairs[idx]['text'] = v,
                )),
                IconButton(onPressed: () async {
                  var url = await _uploadFile();
                  if (url != null) setState(() => _pairs[idx]['image'] = url);
                }, icon: Icon(Icons.image, color: _pairs[idx]['image'] != "" ? Colors.green : Colors.grey)),
              ],
            );
          }),
          TextButton(
            onPressed: () => setState(() => _pairs.add({"text": "", "image": ""})),
            child: const Text("+ إضافة زوج جديد", style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800)),
          ),
        ],
      );
    }
  }

  Widget _buildSaveButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: isSaving ? null : _saveNewGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        ),
        child: isSaving
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text("حفظ ونشر اللعبة", style: TextStyle(color: Colors.white, fontFamily: 'Tajawal', fontWeight: FontWeight.w900)),
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

  void _confirmDelete(int id) {
    Get.defaultDialog(
        title: "حذف", middleText: "هل تريد حذف هذه اللعبة؟",
        onConfirm: () { Get.back(); _deleteGame(id); },
        textConfirm: "حذف", textCancel: "إلغاء", confirmTextColor: Colors.white
    );
  }

  Future<void> _deleteGame(int id) async {
    final token = GetStorage().read('token');
    await http.delete(Uri.parse('$baseUrl/games/$id'), headers: {'Authorization': 'Bearer $token'});
    _fetchGames();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _titleController.dispose();
    _wordController.dispose();
    _hintController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Widget _buildSearchField(ColorScheme cs) {
    return TextField(
      controller: _searchCtrl,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: 'بحث في الألعاب بالعنوان أو النوع...',
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
        suffixIcon: _searchCtrl.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'مسح',
                onPressed: () => _searchCtrl.clear(),
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
      ),
    );
  }

  Widget _badge(ColorScheme cs, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: cs.primary.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800, fontSize: 12.sp, color: const Color(0xFF0F172A)),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final s = status.toLowerCase().trim();

    Color bg;
    Color border;
    Color text;
    IconData icon;
    String label;

    switch (s) {
      case 'reviewed':
        bg = const Color(0xFFE0F2FE); // sky
        border = const Color(0xFF93C5FD);
        text = const Color(0xFF1D4ED8);
        icon = Icons.verified_rounded;
        label = 'تمت المراجعة';
        break;
      case 'published':
        bg = const Color(0xECFDF3); // green-50-ish
        border = const Color(0xFF86EFAC);
        text = const Color(0xFF047857);
        icon = Icons.public_rounded;
        label = 'منشورة';
        break;
      case 'draft':
      default:
        bg = const Color(0xFFFEF3C7); // amber-50-ish
        border = const Color(0xFFF59E0B);
        text = const Color(0xFF92400E);
        icon = Icons.edit;
        label = 'مسودة';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: text),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w900,
              fontSize: 12.sp,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(ColorScheme cs, {required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.w, color: cs.primary),
          SizedBox(width: 6.w),
          Text(text, style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _stateCard({
    required String title,
    required String subtitle,
    required String primaryLabel,
    required VoidCallback onPrimary,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 520.w),
          child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: const Icon(Icons.extension, color: Color(0xFF4F46E5), size: 34),
                ),
                SizedBox(height: 12.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w900, fontSize: 18.sp, color: const Color(0xFF0F172A)),
                ),
                SizedBox(height: 8.h),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey.shade700, height: 1.35),
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPrimary,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(primaryLabel, style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w900)),
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

// --- واجهة العرض التجريبي للطفل ---
