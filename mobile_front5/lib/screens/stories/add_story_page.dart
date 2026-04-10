import 'package:flutter/material.dart';

class StoryFormPage extends StatefulWidget {
  @override
  _StoryFormPageState createState() => _StoryFormPageState();
}

class _StoryFormPageState extends State<StoryFormPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  List<Map<String, dynamic>> contents = [];
  List<Map<String, dynamic>> questions = [];

  void addContent() {
    setState(() {
      contents.add({"type": "text", "content": "", "file": null});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("إضافة قصة")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: "عنوان القصة"),
            ),
            SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "الوصف"),
              maxLines: 3,
            ),

            SizedBox(height: 20),
            Text("المحتوى", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            ...contents.asMap().entries.map((entry) {
              int i = entry.key;
              var c = entry.value;

              return Card(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      DropdownButton<String>(
                        value: c['type'],
                        items: [
                          DropdownMenuItem(value: 'text', child: Text('نص')),
                          DropdownMenuItem(value: 'image', child: Text('صورة')),
                          DropdownMenuItem(value: 'audio', child: Text('صوت')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            contents[i]['type'] = val;
                          });
                        },
                      ),

                      if (c['type'] == 'text')
                        TextField(
                          onChanged: (val) => contents[i]['content'] = val,
                          decoration: InputDecoration(labelText: "النص"),
                        )
                      else
                        ElevatedButton(
                          onPressed: () {
                            // TODO: file picker
                          },
                          child: Text("اختيار ملف"),
                        ),

                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() => contents.removeAt(i));
                        },
                      )
                    ],
                  ),
                ),
              );
            }),

            ElevatedButton(onPressed: addContent, child: Text("إضافة محتوى")),

            SizedBox(height: 20),
            Text("الأسئلة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            ...questions.asMap().entries.map((entry) {
              int qi = entry.key;
              var q = entry.value;

              return Card(
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (val) => questions[qi]['question'] = val,
                        decoration: InputDecoration(labelText: "السؤال"),
                      ),

                      ...q['answers'].asMap().entries.map<Widget>((ansEntry) {
                        int ai = ansEntry.key;
                        var a = ansEntry.value;

                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (val) => questions[qi]['answers'][ai]['answer'] = val,
                                decoration: InputDecoration(labelText: "جواب"),
                              ),
                            ),
                            Checkbox(
                              value: a['is_correct'],
                              onChanged: (val) {
                                setState(() {
                                  questions[qi]['answers'][ai]['is_correct'] = val;
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                setState(() => questions[qi]['answers'].removeAt(ai));
                              },
                            )
                          ],
                        );
                      }).toList(),

                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            questions[qi]['answers'].add({"answer": "", "is_correct": false});
                          });
                        },
                        child: Text("إضافة جواب"),
                      ),

                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() => questions.removeAt(qi));
                        },
                      )
                    ],
                  ),
                ),
              );
            }),

            ElevatedButton(onPressed: addQuestion, child: Text("إضافة سؤال")),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: send to API
              },
              child: Text("إرسال القصة"),
            )
          ],
        ),
      ),
    );
  }
}
