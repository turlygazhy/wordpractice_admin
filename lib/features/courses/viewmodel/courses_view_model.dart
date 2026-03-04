import 'dart:async';

import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';
import 'package:wordpractice_admin/features/courses/state/courses_state.dart';
import 'package:wordpractice_admin/services/course_service.dart';

/// ViewModel for courses list screen.
/// Subscribes to courses stream and exposes async operations.
@immutable
class CoursesViewModel extends StateNotifier<CoursesState> {
  final CourseService _service;
  StreamSubscription? _subscription;

  CoursesViewModel(this._service) : super(CoursesState.initial()) {
    _listenToCourses();
  }

  /// Starts listening to courses changes from service.
  /// Updates state on each event.
  void _listenToCourses() {
    state = state.copyWith(isLoading: true, error: null);

    _subscription?.cancel();
    _subscription = _service.watchCourses().listen(
      (courses) {
        state = state.copyWith(
          courses: courses,
          isLoading: false,
          error: null,
        );
      },
      onError: (Object e, StackTrace _) {
        state = state.copyWith(
          isLoading: false,
          error: e,
        );
      },
    );
  }

  /// Creates new course with provided title.
  /// Throws error when title is empty.
  Future<void> createCourse(String title) async {
    if (title.trim().isEmpty) {
      throw ArgumentError('Title must not be empty');
    }
    try {
      await _service.createCourse(title.trim());
    } catch (e) {
      state = state.copyWith(error: e);
      rethrow;
    }
  }

  /// Updates displayed flag for course by id.
  /// Accepts new displayed value.
  Future<void> updateCourseDisplayed(String id, bool displayed) async {
    try {
      await _service.updateCourseMeta(id: id, displayed: displayed);
    } catch (e) {
      state = state.copyWith(error: e);
      rethrow;
    }
  }

  /// Updates course title by id.
  /// Accepts new non-empty title.
  Future<void> updateCourseTitle(String id, String title) async {
    if (title.trim().isEmpty) {
      throw ArgumentError('Title must not be empty');
    }
    try {
      await _service.updateCourseMeta(id: id, title: title.trim());
    } catch (e) {
      state = state.copyWith(error: e);
      rethrow;
    }
  }

  /// Deletes course by id.
  /// Removes document from Firestore.
  Future<void> deleteCourse(String id) async {
    try {
      await _service.deleteCourse(id);
    } catch (e) {
      state = state.copyWith(error: e);
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

