import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordpractice_admin/features/courses/providers.dart';
import 'package:wordpractice_admin/features/courses/state/course_models.dart';
import 'package:wordpractice_admin/features/courses/widgets/course_list_item_widget.dart';
import 'package:wordpractice_admin/features/courses/view/course_details_screen.dart';
import 'package:wordpractice_admin/services/course_service.dart';

/// Screen for displaying and managing list of courses.
/// Uses MVVM with Riverpod and CourseService as data source.
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildScaffold(context, ref);
  }

  /// Builds main scaffold for courses list screen.
  /// Composes app bar and body sections.
  Widget _buildScaffold(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(context, ref),
      body: _buildBody(context, ref),
    );
  }

  /// Builds app bar with title and add button.
  /// Uses view model for creating new course.
  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const Text('Курсы'),
      actions: [
        _buildAddCourseButton(context, ref),
      ],
    );
  }

  /// Builds main body with courses list and loading or error states.
  /// Subscribes to courses state from Riverpod provider.
  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coursesViewModelProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Text('Ошибка загрузки курсов: ${state.error}'),
      );
    }

    if (state.courses.isEmpty) {
      return const Center(child: Text('Нет курсов'));
    }

    return _buildCoursesList(context, state.courses, ref);
  }

  /// Builds list of courses as scrollable ListView.
  /// Uses dedicated widget for single course item.
  Widget _buildCoursesList(
    BuildContext context,
    List<Course> courses,
    WidgetRef ref,
  ) {
    return ListView.builder(
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseListItemWidget(
          course: course,
          onOpen: () => _openCourseDetails(context, course.id),
          onEdit: () => _showEditCourseDialog(context, ref, course),
          onDelete: () => _confirmDeleteCourse(context, ref, course),
        );
      },
    );
  }

  /// Builds add course button placed in app bar.
  /// Shows dialog for entering new course title.
  Widget _buildAddCourseButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton.icon(
        onPressed: () => _showAddCourseDialog(context, ref),
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

  /// Opens details screen for selected course.
  /// Uses Navigator with MaterialPageRoute.
  void _openCourseDetails(BuildContext context, String courseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailsScreen(courseId: courseId),
      ),
    );
  }

  /// Shows dialog for adding new course.
  /// On success delegates creation to view model.
  Future<void> _showAddCourseDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final titleController = TextEditingController();
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Добавить курс'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Название курса',
                      hintText: 'Введите название курса',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                    autofocus: true,
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
                        errorText = 'Название обязательно';
                      });
                      return;
                    }
                    Navigator.pop(context, title);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Создать'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      try {
        final notifier = ref.read(coursesViewModelProvider.notifier);
        await notifier.createCourse(result);
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
          final message = e is DuplicateCourseTitleException
              ? e.toString()
              : 'Ошибка при создании курса: $e';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Shows dialog for editing existing course.
  /// Allows changing title and displayed flag.
  Future<void> _showEditCourseDialog(
    BuildContext context,
    WidgetRef ref,
    Course course,
  ) async {
    final titleController = TextEditingController(text: course.title);
    var displayed = course.displayed;
    String? errorText;

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
                      hintText: 'Введите название курса',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
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
                        errorText = 'Название обязательно';
                      });
                      return;
                    }
                    Navigator.pop(
                      context,
                      (title: title, displayed: displayed),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      try {
        final notifier = ref.read(coursesViewModelProvider.notifier);
        await notifier.updateCourseTitle(course.id, result.title);
        await notifier.updateCourseDisplayed(course.id, result.displayed);
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
  }

  /// Shows confirmation dialog for deleting course.
  /// On confirm, asks view model to remove document.
  Future<void> _confirmDeleteCourse(
    BuildContext context,
    WidgetRef ref,
    Course course,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить курс'),
        content: Text('Вы действительно хотите удалить курс "${course.title}"?'),
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

    if (confirmed == true) {
      try {
        final notifier = ref.read(coursesViewModelProvider.notifier);
        await notifier.deleteCourse(course.id);
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
}

