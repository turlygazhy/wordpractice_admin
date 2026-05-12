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
      body: _buildBody(context, state),
    );
  }

  /// Builds app bar with static title and optional course title subtitle.
  /// Shows course name when available.
  PreferredSizeWidget _buildAppBar(BuildContext context, Course? course) {
    return AppBar(
      title: Text(course?.title.isNotEmpty == true
          ? course!.title
          : 'Детали курса'),
      actions: [
        if (course != null) _buildDeleteCourseButton(context),
      ],
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
          _buildTitleSection(context, course),
          const SizedBox(height: 16),
          _buildDescriptionSection(course),
          const SizedBox(height: 16),
          _buildDisplayedStatusSection(context, course),
          const SizedBox(height: 24),
          if (isSavingWord) _buildSavingIndicator(),
          _buildAddWordButton(),
          const SizedBox(height: 8),
          _buildWordsListSection(course),
        ],
      ),
    );
  }

  /// Builds title text section for course.
  /// Shows generic placeholder when title is empty.
  Widget _buildTitleSection(BuildContext context, Course course) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            course.title.isEmpty ? 'Без названия' : course.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: () => _onEditCourseMetaPressed(
            context,
            initialTitle: course.title,
            initialDisplayed: course.displayed,
          ),
          child: const Text('Редактировать'),
        ),
      ],
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
  Widget _buildDisplayedStatusSection(BuildContext context, Course course) {
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
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _onEditCourseDisplayedPressed(
            context,
            currentDisplayed: course.displayed,
          ),
          child: const Text('Редактировать'),
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

  /// Builds "add word" button inside words block.
  /// Uses Consumer to access Riverpod ref for action handler.
  Widget _buildAddWordButton() {
    return Consumer(
      builder: (context, ref, _) {
        return Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: () => _onAddWordPressed(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Добавить слово'),
          ),
        );
      },
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

  /// Handles add word button press.
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
  /// Shows dialog that allows changing text and optionally media.
  Future<void> _onEditWordPressed(
    BuildContext context,
    WidgetRef ref,
    int index,
    CourseWord word,
  ) async {
    final result = await showDialog<WordFormResult>(
      context: context,
      builder: (context) => WordFormDialogWidget(
        initialArabic: word.arabic,
        initialTranslation: word.translation,
      ),
    );

    if (result == null) return;

    try {
      final notifier =
          ref.read(courseDetailsViewModelProvider(courseId).notifier);
      await notifier.updateWord(
        index: index,
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

  /// Builds delete course button for app bar actions.
  /// Shows confirmation dialog before deletion.
  Widget _buildDeleteCourseButton(BuildContext context) {
    return TextButton(
      onPressed: () => _onDeleteCoursePressed(context),
      child: const Text(
        'Удалить курс',
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  /// Handles edit of both title and displayed flag in a single dialog.
  /// Uses view model to persist changes to Firestore.
  Future<void> _onEditCourseMetaPressed(
    BuildContext context, {
    required String initialTitle,
    required bool initialDisplayed,
  }) async {
    final titleController = TextEditingController(text: initialTitle);
    var displayed = initialDisplayed;
    String? titleError;

    final result = await showDialog<({String title, bool displayed})>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Редактировать курс'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Название курса',
                      border: const OutlineInputBorder(),
                      errorText: titleError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Отображать курс'),
                      const SizedBox(width: 8),
                      Switch(
                        value: displayed,
                        onChanged: (value) {
                          setState(() {
                            displayed = value;
                          });
                        },
                      ),
                    ],
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
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      setState(() {
                        titleError = 'Название обязательно';
                      });
                      return;
                    }
                    Navigator.pop(
                      context,
                      (title: title, displayed: displayed),
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

    final ref = ProviderScope.containerOf(context).read;
    try {
      final notifier =
          ref(courseDetailsViewModelProvider(courseId).notifier);
      await notifier.updateCourseMeta(
        title: result.title,
        displayed: result.displayed,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Курс обновлён'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при обновлении курса: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles quick edit for displayed flag only.
  /// Keeps title unchanged.
  Future<void> _onEditCourseDisplayedPressed(
    BuildContext context, {
    required bool currentDisplayed,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        var displayed = currentDisplayed;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Статус отображения'),
              content: Row(
                children: [
                  const Text('Отображать курс'),
                  const SizedBox(width: 8),
                  Switch(
                    value: displayed,
                    onChanged: (value) {
                      setState(() {
                        displayed = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, displayed),
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final ref = ProviderScope.containerOf(context).read;
    try {
      final notifier =
          ref(courseDetailsViewModelProvider(courseId).notifier);
      await notifier.updateCourseMeta(displayed: result);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при обновлении статуса: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles deletion of entire course from details screen.
  /// On success navigates back to courses list.
  Future<void> _onDeleteCoursePressed(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить курс'),
        content: const Text(
          'Вы действительно хотите удалить этот курс? Это действие нельзя отменить.',
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

    final ref = ProviderScope.containerOf(context).read;
    try {
      final notifier =
          ref(courseDetailsViewModelProvider(courseId).notifier);
      await notifier.deleteCourse();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при удалении курса: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

