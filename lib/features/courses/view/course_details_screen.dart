import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordpractice_admin/features/courses/providers.dart';
import 'package:wordpractice_admin/features/courses/state/course_models.dart';
import 'package:wordpractice_admin/features/courses/widgets/word_card_widget.dart';
import 'package:wordpractice_admin/features/courses/widgets/word_form_dialog_widget.dart';

/// Screen for displaying and managing single course details.
/// Uses Riverpod-powered view model and respects feature specification.
class CourseDetailsScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailsScreen({
    super.key,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildScaffold(context, ref);
  }

  /// Builds main scaffold with app bar and body.
  /// Connects state from view model family provider.
  Widget _buildScaffold(BuildContext context, WidgetRef ref) {
    final state = ref.watch(courseDetailsViewModelProvider(courseId));

    return Scaffold(
      appBar: _buildAppBar(context, state.course),
      floatingActionButton: _buildFab(context, ref),
      body: _buildBody(context, state),
    );
  }

  /// Builds app bar with static title and optional course title subtitle.
  /// Shows course name when available.
  PreferredSizeWidget _buildAppBar(BuildContext context, Course? course) {
    return AppBar(
      title: Text(course?.title ?? 'Детали курса'),
    );
  }

  /// Builds floating action button for adding new word.
  /// Delegates handling to dialog and view model.
  Widget _buildFab(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _onAddWordPressed(context, ref),
      icon: const Icon(Icons.add),
      label: const Text('Добавить слово'),
    );
  }

  /// Builds main body with loading, error and course content states.
  /// Respects feature behavior for missing course.
  Widget _buildBody(BuildContext context, dynamic state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Text('Ошибка загрузки курса: ${state.error}'),
      );
    }

    final course = state.course;
    if (course == null) {
      return const Center(child: Text('Курс не найден'));
    }

    return _buildCourseContent(context, course, state.isSavingWord);
  }

  /// Builds scrollable course content including title, description and words.
  /// Composes separate sections according to user rules.
  Widget _buildCourseContent(
    BuildContext context,
    Course course,
    bool isSavingWord,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleSection(course),
          const SizedBox(height: 16),
          _buildDescriptionSection(course),
          const SizedBox(height: 16),
          _buildDisplayedStatusSection(course),
          const SizedBox(height: 24),
          if (isSavingWord) _buildSavingIndicator(),
          _buildWordsListSection(course),
        ],
      ),
    );
  }

  /// Builds title text section for course.
  /// Shows generic placeholder when title is empty.
  Widget _buildTitleSection(Course course) {
    return Text(
      course.title.isEmpty ? 'Без названия' : course.title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Builds description text section for course.
  /// Uses standard body text styling.
  Widget _buildDescriptionSection(Course course) {
    return Text(
      course.description,
      style: const TextStyle(fontSize: 16),
    );
  }

  /// Builds displayed status row with label and chip.
  /// Uses green and red backgrounds for boolean state.
  Widget _buildDisplayedStatusSection(Course course) {
    return Row(
      children: [
        const Text(
          'Отображается: ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Chip(
          label: Text(course.displayed ? 'Да' : 'Нет'),
          backgroundColor:
              course.displayed ? Colors.green.shade100 : Colors.red.shade100,
        ),
      ],
    );
  }

  /// Builds indicator shown while saving or updating word.
  /// Helps admin understand background operations.
  Widget _buildSavingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: const [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Сохранение слова...'),
        ],
      ),
    );
  }

  /// Builds list of words for course.
  /// Shows appropriate message when no words available.
  Widget _buildWordsListSection(Course course) {
    final words = course.words;

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
            final word = words[index];
            return Consumer(
              builder: (context, ref, _) {
                return WordCardWidget(
                  word: word,
                  index: index,
                  onEdit: () =>
                      _onEditWordPressed(context, ref, index, word),
                  onDelete: () =>
                      _onDeleteWordPressed(context, ref, index, word),
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// Handles FAB press for adding new word.
  /// Shows word form dialog and passes result to view model.
  Future<void> _onAddWordPressed(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDialog<WordFormResult>(
      context: context,
      builder: (context) => const WordFormDialogWidget(),
    );

    if (result == null) return;

    try {
      final notifier =
          ref.read(courseDetailsViewModelProvider(courseId).notifier);
      await notifier.addWord(
        arabic: result.arabic,
        translation: result.translation,
        audioBytes: result.audioBytes,
        audioContentType: result.audioContentType,
        imageBytes: result.imageBytes,
        imageContentType: result.imageContentType,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Слово успешно добавлено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при добавлении слова: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles edit action for existing word.
  /// Shows simple text-only dialog without media change.
  Future<void> _onEditWordPressed(
    BuildContext context,
    WidgetRef ref,
    int index,
    CourseWord word,
  ) async {
    final arabicController = TextEditingController(text: word.arabic);
    final translationController =
        TextEditingController(text: word.translation);
    String? arabicError;
    String? translationError;

    final result = await showDialog<({String arabic, String translation})>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Редактировать слово'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: arabicController,
                    decoration: InputDecoration(
                      labelText: 'Арабский',
                      border: const OutlineInputBorder(),
                      errorText: arabicError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: translationController,
                    decoration: InputDecoration(
                      labelText: 'Перевод',
                      border: const OutlineInputBorder(),
                      errorText: translationError,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final arabic = arabicController.text.trim();
                    final translation = translationController.text.trim();
                    var hasError = false;
                    if (arabic.isEmpty) {
                      arabicError = 'Обязательно';
                      hasError = true;
                    }
                    if (translation.isEmpty) {
                      translationError = 'Обязательно';
                      hasError = true;
                    }
                    if (hasError) {
                      setState(() {});
                      return;
                    }
                    Navigator.pop(
                      context,
                      (arabic: arabic, translation: translation),
                    );
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      final notifier =
          ref.read(courseDetailsViewModelProvider(courseId).notifier);
      await notifier.updateWord(
        index: index,
        arabic: result.arabic,
        translation: result.translation,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Слово успешно обновлено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при обновлении слова: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles delete action for existing word.
  /// Shows confirmation dialog and delegates to view model.
  Future<void> _onDeleteWordPressed(
    BuildContext context,
    WidgetRef ref,
    int index,
    CourseWord word,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить слово'),
        content: Text(
          'Вы действительно хотите удалить слово "${word.arabic}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final notifier =
          ref.read(courseDetailsViewModelProvider(courseId).notifier);
      await notifier.deleteWord(index);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Слово удалено'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при удалении слова: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

