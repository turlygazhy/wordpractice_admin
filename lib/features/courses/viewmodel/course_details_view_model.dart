import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:riverpod/riverpod.dart';
import 'package:wordpractice_admin/features/courses/state/course_details_state.dart';
import 'package:wordpractice_admin/services/course_service.dart';

/// ViewModel for course details screen.
/// Manages single course stream and words operations.
@immutable
class CourseDetailsViewModel extends StateNotifier<CourseDetailsState> {
  final CourseService _service;
  final String _courseId;
  StreamSubscription? _subscription;

  CourseDetailsViewModel({
    required CourseService service,
    required String courseId,
  })  : _service = service,
        _courseId = courseId,
        super(CourseDetailsState.initial()) {
    _listenToCourse();
  }

  /// Starts listening to single course changes.
  /// Updates state on each event.
  void _listenToCourse() {
    state = state.copyWith(isLoading: true, error: null);

    _subscription?.cancel();
    _subscription = _service.watchCourse(_courseId).listen(
      (course) {
        state = state.copyWith(
          course: course,
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

  /// Adds new word with media to current course.
  /// Accepts texts and raw media bytes with content types.
  Future<void> addWord({
    required String arabic,
    required String translation,
    required Uint8List audioBytes,
    required String audioContentType,
    required Uint8List imageBytes,
    required String imageContentType,
  }) async {
    if (arabic.trim().isEmpty || translation.trim().isEmpty) {
      throw ArgumentError('Arabic and translation must not be empty');
    }

    state = state.copyWith(isSavingWord: true, error: null);

    try {
      await _service.addWord(
        courseId: _courseId,
        arabic: arabic.trim(),
        translation: translation.trim(),
        media: WordMediaData(
          audioBytes: audioBytes,
          audioContentType: audioContentType,
          imageBytes: imageBytes,
          imageContentType: imageContentType,
        ),
      );
    } catch (e) {
      state = state.copyWith(isSavingWord: false, error: e);
      rethrow;
    }

    state = state.copyWith(isSavingWord: false);
  }

  /// Updates existing word by index.
  /// Optionally accepts new media bytes to replace previous media.
  Future<void> updateWord({
    required int index,
    required String arabic,
    required String translation,
    Uint8List? audioBytes,
    String? audioContentType,
    Uint8List? imageBytes,
    String? imageContentType,
  }) async {
    if (arabic.trim().isEmpty || translation.trim().isEmpty) {
      throw ArgumentError('Arabic and translation must not be empty');
    }

    state = state.copyWith(isSavingWord: true, error: null);

    try {
      WordMediaData? media;
      if (audioBytes != null &&
          audioContentType != null &&
          imageBytes != null &&
          imageContentType != null) {
        media = WordMediaData(
          audioBytes: audioBytes,
          audioContentType: audioContentType,
          imageBytes: imageBytes,
          imageContentType: imageContentType,
        );
      }

      await _service.updateWord(
        courseId: _courseId,
        index: index,
        arabic: arabic.trim(),
        translation: translation.trim(),
        media: media,
      );
    } catch (e) {
      state = state.copyWith(isSavingWord: false, error: e);
      rethrow;
    }

    state = state.copyWith(isSavingWord: false);
  }

  /// Deletes word by index from current course.
  /// Delegates removal to service.
  Future<void> deleteWord(int index) async {
    try {
      await _service.deleteWord(
        courseId: _courseId,
        index: index,
      );
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

