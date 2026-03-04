import 'package:flutter/material.dart';
import 'package:wordpractice_admin/features/courses/state/course_models.dart';

/// Widget for displaying single course item in list.
/// Accepts course model and callbacks for actions.
class CourseListItemWidget extends StatelessWidget {
  final Course course;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CourseListItemWidget({
    super.key,
    required this.course,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(course.title.isEmpty ? 'Без названия' : course.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(course.description),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Отображается: '),
                Chip(
                  label: Text(course.displayed ? 'Да' : 'Нет'),
                  backgroundColor:
                      course.displayed ? Colors.green.shade100 : Colors.red.shade100,
                ),
              ],
            ),
          ],
        ),
        onTap: onOpen,
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Редактировать курс',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Удалить курс',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

