import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordpractice_admin/course_detail_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Курсы'),
        actions: [
          _buildAddCourseButton(context),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .where('description', isEqualTo: 'Базовый арабский')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Нет курсов'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final course = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(course['title'] ?? 'Без названия'),
                subtitle: Text(course['description'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(
                        courseId: doc.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Builds add course button in app bar
  Widget _buildAddCourseButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton.icon(
        onPressed: () => _showAddCourseDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Добавить курс',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  /// Shows dialog for adding a new course
  Future<void> _showAddCourseDialog(BuildContext context) async {
    final titleController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить курс'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Название курса',
            hintText: 'Введите название курса',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                Navigator.pop(context, title);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _createCourse(context, result);
    }
  }

  /// Creates a new course in Firestore
  Future<void> _createCourse(BuildContext context, String title) async {
    try {
      // Generate courseId
      final courseRef = FirebaseFirestore.instance.collection('courses').doc();
      final courseId = courseRef.id;

      // Prepare course data
      final courseData = {
        'description': 'Базовый арабский',
        'displayed': false,
        'icon': '',
        'id': courseId,
        'imagePath':
            'https://firebasestorage.googleapis.com/v0/b/manara-41e79.firebasestorage.app/o/manara_logo.png?alt=media&token=221a09a8-4c77-4d79-aebe-906b18568244',
        'instagram': 'https://www.instagram.com/arabic_osman/',
        'male_test': false,
        'title': title,
        'youtube': 'https://youtube.com/@arabic_osman',
        'words': [],
      };

      // Create course document
      await courseRef.set(courseData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Курс успешно создан'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при создании курса: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
