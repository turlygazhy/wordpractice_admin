import 'package:meta/meta.dart';
import 'package:wordpractice_admin/features/courses/state/course_models.dart';

/// Immutable state for courses list screen.
/// Holds list of courses, loading flag and optional error.
@immutable
class CoursesState {
  final List<Course> courses;
  final bool isLoading;
  final Object? error;

  const CoursesState({
    required this.courses,
    required this.isLoading,
    required this.error,
  });

  /// Returns initial empty state with loading enabled.
  factory CoursesState.initial() {
    return const CoursesState(
      courses: <Course>[],
      isLoading: true,
      error: null,
    );
  }

  /// Creates a copy with updated fields.
  /// Returns new immutable instance.
  CoursesState copyWith({
    List<Course>? courses,
    bool? isLoading,
    Object? error,
  }) {
    return CoursesState(
      courses: courses ?? this.courses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

