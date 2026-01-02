import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Screen for displaying course details
/// Accepts courseId to fetch and display course information
class CourseDetailScreen extends StatelessWidget {
  final String courseId;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали курса'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Курс не найден'));
          }

          final course = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(course),
                const SizedBox(height: 16),
                _buildDescription(course),
                const SizedBox(height: 16),
                _buildDisplayedStatus(course),
                const SizedBox(height: 24),
                _buildWordsList(course),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds title section
  Widget _buildTitle(Map<String, dynamic> course) {
    return Text(
      course['title'] ?? 'Без названия',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Builds description section
  Widget _buildDescription(Map<String, dynamic> course) {
    return Text(
      course['description'] ?? '',
      style: const TextStyle(fontSize: 16),
    );
  }

  /// Builds displayed status section
  Widget _buildDisplayedStatus(Map<String, dynamic> course) {
    final displayed = course['displayed'] ?? false;
    return Row(
      children: [
        const Text(
          'Отображается: ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Chip(
          label: Text(displayed ? 'Да' : 'Нет'),
          backgroundColor: displayed ? Colors.green.shade100 : Colors.red.shade100,
        ),
      ],
    );
  }

  /// Builds words list section
  Widget _buildWordsList(Map<String, dynamic> course) {
    final words = course['words'] as List<dynamic>? ?? [];

    if (words.isEmpty) {
      return const Text(
        'Слов нет',
        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Слова (${words.length}):',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: words.length,
          itemBuilder: (context, index) {
            final word = words[index] as Map<String, dynamic>;
            return _buildWordCard(word, index);
          },
        ),
      ],
    );
  }

  /// Builds word card with all word information
  Widget _buildWordCard(Map<String, dynamic> word, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWordHeader(index),
            const SizedBox(height: 8),
            _buildWordField('Арабский', word['arabic'] ?? ''),
            _buildWordField('Перевод', word['translation'] ?? ''),
            _buildWordField('Аудио URL', word['audioUrl'] ?? ''),
            _buildWordField('Изображение URL', word['imageUrl'] ?? ''),
          ],
        ),
      ),
    );
  }

  /// Builds word header with index
  Widget _buildWordHeader(int index) {
    return Text(
      'Слово ${index + 1}',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Builds single word field row
  Widget _buildWordField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '(пусто)' : value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

