import 'package:untitled1/screens/child_registration_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/parent_controller.dart';
import '../models/child_model.dart';
import '../widgets/child_card.dart';
import 'login_page.dart';

class ParentDashboardPage extends StatelessWidget {
  ParentDashboardPage({super.key});

  final ParentController parentController = Get.put(ParentController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children Accounts'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Get.offAll(() => LoginPage());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => ChildRegisterPage());
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Welcome Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFFFF9800),
                      child: Icon(Icons.family_restroom, size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Parent!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Obx(() => Text(
                                'You have ${parentController.children.length} children accounts',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Children List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Children Accounts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Obx(() => Text(
                      'Total: ${parentController.children.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 16),

            // Children List
            Expanded(
              child: Obx(() => parentController.children.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.child_care,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No children accounts yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap the + button to add a child',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: parentController.children.length,
                      itemBuilder: (context, index) {
                        final child = parentController.children[index];
                        return ChildCard(
                          child: child,
                          onView: () {
                            _showChildDetails(context, child);
                          },
                          onEdit: () {
                            Get.to(() => ChildRegisterPage(
                                  childToEdit: child,
                                ));
                          },
                          onDelete: () {
                            _showDeleteDialog(context, child);
                          },
                        );
                      },
                    )),
            ),
          ],
        ),
      ),
    );
  }

  void _showChildDetails(BuildContext context, Child child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${child.name}\'s Account'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.shade100,
                  ),
                  child: Icon(
                    Icons.child_care,
                    size: 40,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailItem('Full Name:', child.name),
              _buildDetailItem('Nickname:', child.nickname),
              _buildDetailItem('Age:', '${child.age} years'),
              if (child.interests.isNotEmpty) ...[
                _buildDetailItem('Interests:', child.interests.join(", ")),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.to(() => ChildRegisterPage(childToEdit: child));
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Child child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Child Account'),
        content: Text('Are you sure you want to delete ${child.name}\'s account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              parentController.deleteChild(child.id);
              Get.back();
              Get.snackbar(
                'Success',
                '${child.name}\'s account has been deleted',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}