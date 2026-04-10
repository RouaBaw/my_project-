import 'package:flutter/material.dart';
import '../models/child_model.dart';

class ChildCard extends StatelessWidget {
  final Child child;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ChildCard({
    super.key,
    required this.child,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Child Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getAvatarColor(child.id),
              ),
              child: Icon(
                Icons.child_care,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),

            // Child Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nickname: ${child.nickname}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Age: ${child.age} years',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (child.interests.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: child.interests
                          .map((interest) => Chip(
                                label: Text(
                                  interest,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                backgroundColor: Colors.blue.shade50,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Action Buttons
            Column(
              children: [
                // View Button
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: onView,
                  tooltip: 'View Details',
                ),
                // More Options
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(String id) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    return colors[int.parse(id) % colors.length];
  }
}