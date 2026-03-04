import 'package:meta/meta.dart';
import 'package:wordpractice_admin/features/courses/state/course_models.dart';

/// Immutable state for course details screen.
/// Holds single course, loading flag, error and progress flags.
@immutable
class CourseDetailsState {
  final Course? course;
  final bool isLoading;
  final Object? error;
  final bool isSavingWord;

  const CourseDetailsState({
    required this.course,
    required this.isLoading,
    required this.error,
    required this.isSavingWord,
  });

  /// Returns initial state with loading enabled and no course.
  factory CourseDetailsState.initial() {
    return const CourseDetailsState(
      course: null,
      isLoading: true,
      error: null,
      isSavingWord: false,
    );
  }

  /// Creates a copy with updated fields.
  /// Returns new immutable instance.
  CourseDetailsState copyWith({
    Course? course,
    bool? isLoading,
    Object? error,
    bool? isSavingWord,
  }) {
    return CourseDetailsState(
      course: course ?? this.course,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSavingWord: isSavingWord ?? this.isSavingWord,
    );
  }
}

