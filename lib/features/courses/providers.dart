import 'package:riverpod/riverpod.dart';
import 'package:wordpractice_admin/features/courses/state/course_details_state.dart';
import 'package:wordpractice_admin/features/courses/state/courses_state.dart';
import 'package:wordpractice_admin/features/courses/viewmodel/course_details_view_model.dart';
import 'package:wordpractice_admin/features/courses/viewmodel/courses_view_model.dart';
import 'package:wordpractice_admin/services/course_service.dart';

/// Provides singleton instance of CourseService.
/// Used by view models for data access.
final courseServiceProvider = Provider<CourseService>((ref) {
  return CourseService();
});

/// Provides CoursesViewModel with CoursesState for list screen.
/// Subscribes to courses collection and exposes CRUD actions.
final coursesViewModelProvider =
    StateNotifierProvider<CoursesViewModel, CoursesState>((ref) {
  final service = ref.watch(courseServiceProvider);
  return CoursesViewModel(service);
});

/// Family provider for CourseDetailsViewModel and CourseDetailsState.
/// Accepts courseId for scoped details screen.
final courseDetailsViewModelProvider = StateNotifierProvider.family<
    CourseDetailsViewModel, CourseDetailsState, String>((ref, courseId) {
  final service = ref.watch(courseServiceProvider);
  return CourseDetailsViewModel(service: service, courseId: courseId);
});

