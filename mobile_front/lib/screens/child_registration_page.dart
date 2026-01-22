import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/parent_controller.dart';
import '../models/child_model.dart';
import 'parent_dashboard_page.dart';

class ChildRegisterPage extends StatefulWidget {
  final Child? childToEdit;

  const ChildRegisterPage({super.key, this.childToEdit});

  @override
  State<ChildRegisterPage> createState() => _ChildRegisterPageState();
}

class _ChildRegisterPageState extends State<ChildRegisterPage> {
  final ParentController parentController = Get.put(ParentController());
  
  late TextEditingController nameController;
  late TextEditingController nicknameController;
  late TextEditingController ageController;
  
  final selectedInterests = <String>[].obs;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.childToEdit?.name ?? '');
    nicknameController = TextEditingController(text: widget.childToEdit?.nickname ?? '');
    ageController = TextEditingController(text: widget.childToEdit?.age ?? '');
    
    if (widget.childToEdit != null) {
      selectedInterests.addAll(widget.childToEdit!.interests);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.childToEdit == null ? 'Add Child Account' : 'Edit Child Account'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Child Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    border: Border.all(
                      color: const Color(0xFFFF9800),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.child_care,
                    size: 40,
                    color: const Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(height: 30),

                // Child Registration Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.childToEdit == null ? 'Child Information' : 'Edit Child Information',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Child Full Name *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nicknameController,
                        decoration: const InputDecoration(
                          labelText: 'Nickname *',
                          prefixIcon: Icon(Icons.face),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: ageController,
                        decoration: const InputDecoration(
                          labelText: 'Age *',
                          prefixIcon: Icon(Icons.cake),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      // Interests
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Interests (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Obx(() => Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'Reading',
                              'Drawing',
                              'Music',
                              'Sports',
                              'Science',
                              'Math',
                              'Art',
                              'Dancing',
                              'Animals',
                              'Cooking',
                            ].map((interest) {
                              return FilterChip(
                                label: Text(interest),
                                selected: selectedInterests.contains(interest),
                                onSelected: (selected) {
                                  if (selected) {
                                    selectedInterests.add(interest);
                                  } else {
                                    selectedInterests.remove(interest);
                                  }
                                },
                              );
                            }).toList(),
                          )),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameController.text.isEmpty ||
                                nicknameController.text.isEmpty ||
                                ageController.text.isEmpty) {
                              Get.snackbar(
                                'Error',
                                'Please fill all required fields',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                              return;
                            }

                            final child = Child(
                              id: widget.childToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              name: nameController.text,
                              nickname: nicknameController.text,
                              age: ageController.text,
                              interests: selectedInterests.toList(),
                            );

                            if (widget.childToEdit == null) {
                              parentController.addChild(child);
                              Get.snackbar(
                                'Success',
                                'Child account added successfully',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            } else {
                              parentController.updateChild(widget.childToEdit!.id, child);
                              Get.snackbar(
                                'Success',
                                'Child account updated successfully',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            }

                            Get.offAll(() => ParentDashboardPage());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9800),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            widget.childToEdit == null ? 'Add Child Account' : 'Update Child Account',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
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