import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get_storage/get_storage.dart';

class StoryFormPage extends StatefulWidget {
  final int pathId;
  final int? learningContentId;
  final bool closeOnSuccess;

  const StoryFormPage({
    super.key,
    required this.pathId,
    this.learningContentId,
    this.closeOnSuccess = false,
  });

  @override
  State<StoryFormPage> createState() => _StoryFormPageState();
}

class _StoryFormPageState extends State<StoryFormPage> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  final List<Map<String, dynamic>> contents = [];
  final List<Map<String, dynamic>> questions = [];

  final AudioPlayer player = AudioPlayer();

  bool isSending = false;

  String get baseUrl {
    if (kIsWeb && Uri.base.host.isNotEmpty) {
      return '${Uri.base.scheme}://${Uri.base.host}:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.6),
      ),
    );
  }

  void addContent() {
    setState(() {
      contents.add({
        "type": "text",
        "content": "",
        "fileBytes": null,
        "fileName": null,
      });
    });
  }

  void addQuestion() {
    setState(() {
      questions.add({
        "question": "",
        "answers": [
          {"answer": "", "is_correct": false}
        ]
      });
    });
  }

  Future<void> pickFile(int index) async {
    final type = contents[index]['type'] as String? ?? 'text';
    final result = await FilePicker.platform.pickFiles(
      type: type == 'image'
          ? FileType.image
          : type == 'audio'
              ? FileType.audio
              : FileType.any,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      if (file.bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر قراءة الملف المحدد')),
        );
        return;
      }

      setState(() {
        contents[index]['fileBytes'] = file.bytes;
        contents[index]['fileName'] = file.name;
      });
    }
  }

  String _extractErrorMessage(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return 'تعذر إكمال العملية، تحقق من البيانات ثم حاول مرة أخرى.';
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstEntry = errors.entries.first;
          final value = firstEntry.value;
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
          return value.toString();
        }

        if (decoded['error'] != null) return decoded['error'].toString();
        if (decoded['message'] != null) return decoded['message'].toString();
      }
    } catch (_) {}

    return responseBody;
  }

  bool _validateForm() {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال عنوان القصة')),
      );
      return false;
    }

    if (contents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف محتوى واحدًا على الأقل')),
      );
      return false;
    }

    for (final content in contents) {
      final type = content['type'] as String? ?? 'text';
      final text = (content['content'] ?? '').toString().trim();
      final bytes = content['fileBytes'] as Uint8List?;

      if (type == 'text' && text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يوجد عنصر نصي بدون محتوى')),
        );
        return false;
      }

      if ((type == 'image' || type == 'audio') && bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اختر ملفًا لكل صورة أو مقطع صوتي')),
        );
        return false;
      }
    }

    for (final question in questions) {
      final questionText = (question['question'] ?? '').toString().trim();
      final answers = (question['answers'] as List?) ?? [];

      if (questionText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يوجد سؤال بدون نص')),
        );
        return false;
      }

      if (answers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كل سؤال يجب أن يحتوي على إجابة واحدة على الأقل')),
        );
        return false;
      }

      final hasCorrectAnswer =
          answers.any((answer) => answer['is_correct'] == true);
      if (!hasCorrectAnswer) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدد إجابة صحيحة لكل سؤال')),
        );
        return false;
      }

      for (final answer in answers) {
        if ((answer['answer'] ?? '').toString().trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يوجد جواب فارغ ضمن الأسئلة')),
          );
          return false;
        }
      }
    }

    return true;
  }

  Future<void> _playAudio(Uint8List bytes) async {
    await player.stop();
    await player.play(BytesSource(bytes));
  }

  void _clearForm() {
    titleController.clear();
    descController.clear();
    setState(() {
      contents.clear();
      questions.clear();
    });
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    if (!_validateForm()) {
      return;
    }

    setState(() => isSending = true);

    try {
      final token = GetStorage().read('token');
      final formData = FormData();

      final headers = <String, dynamic>{
        'Accept': 'application/json',
      };
      if (token != null && token.toString().isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      formData.fields.addAll([
        MapEntry('title', titleController.text.trim()),
        MapEntry('description', descController.text.trim()),
        MapEntry('learning_path_id', widget.pathId.toString()),
      ]);
      if (widget.learningContentId != null) {
        formData.fields.add(
          MapEntry(
            'learning_content_id',
            widget.learningContentId.toString(),
          ),
        );
      }

      for (int i = 0; i < contents.length; i++) {
        final c = contents[i];
        final type = c['type'] as String;
        formData.fields.add(MapEntry('contents[$i][type]', type));

        if (type == 'text') {
          formData.fields.add(
            MapEntry(
              'contents[$i][content]',
              (c['content'] ?? '').toString().trim(),
            ),
          );
        } else {
          final bytes = c['fileBytes'] as Uint8List;
          final fileName = (c['fileName'] ?? 'story_file_$i').toString();
          formData.files.add(
            MapEntry(
              'contents[$i][file]',
              MultipartFile.fromBytes(
                bytes,
                filename: fileName,
              ),
            ),
          );
        }
      }

      for (int qi = 0; qi < questions.length; qi++) {
        formData.fields.add(
          MapEntry(
            'questions[$qi][question]',
            (questions[qi]['question'] ?? '').toString().trim(),
          ),
        );

        for (int ai = 0; ai < questions[qi]['answers'].length; ai++) {
          final a = questions[qi]['answers'][ai];
          formData.fields.add(
            MapEntry(
              'questions[$qi][answers][$ai][answer]',
              (a['answer'] ?? '').toString().trim(),
            ),
          );
          formData.fields.add(
            MapEntry(
              'questions[$qi][answers][$ai][is_correct]',
              a['is_correct'] == true ? '1' : '0',
            ),
          );
        }
      }

      final response = await Dio().post(
        '$baseUrl/stories/full',
        data: formData,
        options: Options(
          headers: headers,
          validateStatus: (_) => true,
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (widget.closeOnSuccess) {
          Navigator.of(context).pop(true);
          return;
        }

        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال القصة بنجاح')),
        );
      } else {
        final responseText = response.data is String
            ? response.data as String
            : jsonEncode(response.data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _extractErrorMessage(responseText),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاتصال بالسيرفر: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text('إضافة قصة'),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'أنشئ قصة تعليمية بطريقة احترافية',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'أضف النصوص والصور والمقاطع الصوتية، ثم اربطها بأسئلة تفاعلية لرفع جودة المحتوى.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    title: 'بيانات القصة',
                    subtitle: 'أدخل المعلومات الأساسية التي ستظهر للمستخدم.',
                    child: Column(
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: _inputDecoration(
                            'عنوان القصة',
                            hint: 'مثال: رحلة إلى الغابة',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descController,
                          maxLines: 4,
                          decoration: _inputDecoration(
                            'وصف مختصر',
                            hint: 'أدخل نبذة تعريفية عن القصة ومحتواها',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'محتوى القصة',
                    subtitle: 'رتّب المشاهد النصية أو أضف صورًا وملفات صوتية.',
                    action: FilledButton.icon(
                      onPressed: addContent,
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة عنصر محتوى'),
                    ),
                    child: contents.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.auto_stories_outlined,
                            title: 'لم تتم إضافة أي عناصر بعد',
                            subtitle: 'ابدأ بإضافة نص أو صورة أو ملف صوتي.',
                          )
                        : Column(
                            children: contents.asMap().entries.map((entry) {
                              final i = entry.key;
                              final c = entry.value;
                              final selectedType = c['type'] as String? ?? 'text';
                              final fileName = c['fileName'] as String?;
                              final fileBytes = c['fileBytes'] as Uint8List?;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: const Color(0xFFDBEAFE),
                                          foregroundColor: const Color(0xFF1D4ED8),
                                          child: Text('${i + 1}'),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'عنصر المحتوى ${i + 1}',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'حذف العنصر',
                                          onPressed: () {
                                            setState(() => contents.removeAt(i));
                                          },
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      initialValue: selectedType,
                                      decoration: _inputDecoration('نوع المحتوى'),
                                      items: const [
                                        DropdownMenuItem(value: 'text', child: Text('نص')),
                                        DropdownMenuItem(value: 'image', child: Text('صورة')),
                                        DropdownMenuItem(value: 'audio', child: Text('صوت')),
                                      ],
                                      onChanged: (value) {
                                        if (value == null) return;
                                        setState(() {
                                          contents[i]['type'] = value;
                                          contents[i]['content'] = '';
                                          contents[i]['fileBytes'] = null;
                                          contents[i]['fileName'] = null;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    if (selectedType == 'text')
                                      TextField(
                                        minLines: 4,
                                        maxLines: 6,
                                        onChanged: (value) => contents[i]['content'] = value,
                                        decoration: _inputDecoration(
                                          'نص المحتوى',
                                          hint: 'اكتب النص الذي سيظهر داخل القصة',
                                        ),
                                      )
                                    else
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: const Color(0xFFCBD5E1),
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Wrap(
                                              spacing: 12,
                                              runSpacing: 12,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                FilledButton.icon(
                                                  onPressed: () => pickFile(i),
                                                  icon: const Icon(Icons.upload_file),
                                                  label: Text(
                                                    selectedType == 'image'
                                                        ? 'اختيار صورة'
                                                        : 'اختيار ملف صوتي',
                                                  ),
                                                ),
                                                if (fileName != null)
                                                  Chip(
                                                    avatar: const Icon(Icons.attach_file, size: 18),
                                                    label: Text(fileName),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            if (fileBytes == null)
                                              _buildEmptyState(
                                                icon: selectedType == 'image'
                                                    ? Icons.image_outlined
                                                    : Icons.audio_file_outlined,
                                                title: selectedType == 'image'
                                                    ? 'لم يتم اختيار صورة بعد'
                                                    : 'لم يتم اختيار ملف صوتي بعد',
                                                subtitle: selectedType == 'image'
                                                    ? 'بعد اختيار الصورة ستظهر معاينتها هنا مباشرة.'
                                                    : 'بعد اختيار الملف ستظهر أدوات التشغيل هنا.',
                                              )
                                            else if (selectedType == 'image')
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(18),
                                                child: Image.memory(
                                                  fileBytes,
                                                  height: 240,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF8FAFC),
                                                  borderRadius: BorderRadius.circular(18),
                                                ),
                                                child: Row(
                                                  children: [
                                                    IconButton.filled(
                                                      onPressed: () => _playAudio(fileBytes),
                                                      icon: const Icon(Icons.play_arrow),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    const Expanded(
                                                      child: Text(
                                                        'يمكنك الآن تشغيل الملف الصوتي قبل الإرسال.',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    TextButton.icon(
                                                      onPressed: () => player.stop(),
                                                      icon: const Icon(Icons.stop),
                                                      label: const Text('إيقاف'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'الأسئلة التفاعلية',
                    subtitle: 'أضف أسئلة وأجوبة مرتبطة بالقصة لتحسين تجربة التعلم.',
                    action: FilledButton.icon(
                      onPressed: addQuestion,
                      icon: const Icon(Icons.quiz_outlined),
                      label: const Text('إضافة سؤال'),
                    ),
                    child: questions.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.help_outline,
                            title: 'لا توجد أسئلة مضافة',
                            subtitle: 'يمكنك ترك هذا القسم فارغًا أو إضافة أسئلة الآن.',
                          )
                        : Column(
                            children: questions.asMap().entries.map((entry) {
                              final qi = entry.key;
                              final q = entry.value;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'السؤال ${qi + 1}',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'حذف السؤال',
                                          onPressed: () {
                                            setState(() => questions.removeAt(qi));
                                          },
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      onChanged: (value) => questions[qi]['question'] = value,
                                      decoration: _inputDecoration(
                                        'نص السؤال',
                                        hint: 'اكتب السؤال الذي سيظهر بعد القصة',
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...q['answers'].asMap().entries.map<Widget>((ans) {
                                      final ai = ans.key;
                                      final a = ans.value;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                onChanged: (value) {
                                                  questions[qi]['answers'][ai]['answer'] = value;
                                                },
                                                decoration: _inputDecoration(
                                                  'الإجابة ${ai + 1}',
                                                  hint: 'أدخل نص الإجابة',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              children: [
                                                Checkbox(
                                                  value: a['is_correct'] == true,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      questions[qi]['answers'][ai]['is_correct'] =
                                                          value == true;
                                                    });
                                                  },
                                                ),
                                                const Text('صحيحة'),
                                              ],
                                            ),
                                            IconButton(
                                              tooltip: 'حذف الإجابة',
                                              onPressed: q['answers'].length == 1
                                                  ? null
                                                  : () {
                                                      setState(() {
                                                        questions[qi]['answers'].removeAt(ai);
                                                      });
                                                    },
                                              icon: const Icon(Icons.remove_circle_outline),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            questions[qi]['answers'].add({
                                              "answer": "",
                                              "is_correct": false,
                                            });
                                          });
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('إضافة إجابة'),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isSending ? null : submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: isSending
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'إرسال القصة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 16),
                action,
              ],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: const Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
