import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:meta/meta.dart';
import 'package:wordpractice_admin/features/courses/state/course_models.dart';

/// Thrown when creating a course whose title already exists in the collection.
/// Used to show "нельзя дублировать названия курсов" in UI.
class DuplicateCourseTitleException implements Exception {
  @override
  String toString() => 'Нельзя дублировать названия курсов';
}

/// Immutable value object for word media payload.
/// Each side is optional; when [audioBytes] is set, [audioContentType] must be
/// set (same for image). Callers enforce this.
@immutable
class WordMediaData {
  final Uint8List? audioBytes;
  final String? audioContentType;
  final Uint8List? imageBytes;
  final String? imageContentType;

  const WordMediaData({
    this.audioBytes,
    this.audioContentType,
    this.imageBytes,
    this.imageContentType,
  });
}

/// Service responsible for Firestore and Storage operations for courses.
/// Does not know about UI or Riverpod and exposes pure async methods.
class CourseService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CourseService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _coursesRef =>
      _firestore.collection('courses');

  /// Watches list of courses with description "Базовый арабский".
  /// Returns stream of immutable Course list.
  Stream<List<Course>> watchCourses() {
    return _coursesRef
        .where('description', isEqualTo: 'Базовый арабский')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Course.fromMap(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  /// Creates a new course document with generated id and default fields.
  /// Uses Firestore generated id as both document id and field `id`.
  /// Throws [DuplicateCourseTitleException] if a course with the same title already exists.
  Future<void> createCourse(String title) async {
    final snapshot = await _coursesRef
        .where('description', isEqualTo: 'Базовый арабский')
        .get();

    final normalizedTitle = title.trim();
    final duplicate = snapshot.docs.any((doc) =>
        (doc.data()['title'] as String? ?? '').trim() == normalizedTitle);
    if (duplicate) {
      throw DuplicateCourseTitleException();
    }

    final docRef = _coursesRef.doc();
    final courseId = docRef.id;

    final data = Course(
      id: courseId,
      title: normalizedTitle,
      description: 'Базовый арабский',
      displayed: false,
      icon: '',
      imagePath:
          'https://firebasestorage.googleapis.com/v0/b/manara-41e79.firebasestorage.app/o/manara_logo.png?alt=media&token=221a09a8-4c77-4d79-aebe-906b18568244',
      instagram: 'https://www.instagram.com/arabic_osman/',
      maleTest: false,
      youtube: 'https://youtube.com/@arabic_osman',
      words: const [],
    ).toMap();

    await docRef.set(data);
  }

  /// Updates course metadata fields title and displayed.
  /// Leaves all other document fields unchanged.
  Future<void> updateCourseMeta({
    required String id,
    String? title,
    bool? displayed,
  }) async {
    final updateData = <String, dynamic>{};
    if (title != null) {
      updateData['title'] = title;
    }
    if (displayed != null) {
      updateData['displayed'] = displayed;
    }
    if (updateData.isEmpty) return;

    await _coursesRef.doc(id).update(updateData);
  }

  /// Deletes course document by id.
  /// Does not remove any files from storage.
  Future<void> deleteCourse(String id) async {
    await _coursesRef.doc(id).delete();
  }

  /// Watches single course by id.
  /// Returns stream of Course or null if document does not exist.
  Stream<Course?> watchCourse(String id) {
    return _coursesRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Course.fromMap(doc.id, doc.data());
    });
  }

  /// Adds new word to words array of specific course.
  /// Uploads media to storage and persists full word object.
  Future<void> addWord({
    required String courseId,
    required String arabic,
    required String translation,
    required WordMediaData media,
  }) async {
    final docRef = _coursesRef.doc(courseId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw StateError('Course not found for id: $courseId');
      }

      final existingData =
          snapshot.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      final existingWords =
          (existingData['words'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList();

      final mediaUrls = await _uploadWordMedia(
        courseId: courseId,
        wordIndex: existingWords.length,
        media: media,
        fallbackAudioUrl: '',
        fallbackImageUrl: '',
      );

      final newWord = CourseWord(
        arabic: arabic,
        translation: translation,
        audioUrl: mediaUrls.$1,
        imageUrl: mediaUrls.$2,
        male: false,
      ).toMap();

      existingWords.add(newWord);

      transaction.update(docRef, {'words': existingWords});
    });
  }

  /// Updates existing word by index in words array.
  /// Optionally replaces media when media is provided.
  Future<void> updateWord({
    required String courseId,
    required int index,
    required String arabic,
    required String translation,
    WordMediaData? media,
  }) async {
    final docRef = _coursesRef.doc(courseId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw StateError('Course not found for id: $courseId');
      }

      final existingData =
          snapshot.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      final existingWords =
          (existingData['words'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList();

      if (index < 0 || index >= existingWords.length) {
        throw RangeError.index(index, existingWords, 'index');
      }

      final currentWord = CourseWord.fromMap(
        existingWords[index] as Map<String, dynamic>?,
      );

      String audioUrl = currentWord.audioUrl;
      String imageUrl = currentWord.imageUrl;

      if (media != null) {
        final hasUpload = (media.audioBytes != null &&
                media.audioContentType != null) ||
            (media.imageBytes != null && media.imageContentType != null);
        if (hasUpload) {
          final mediaUrls = await _uploadWordMedia(
            courseId: courseId,
            wordIndex: index,
            media: media,
            fallbackAudioUrl: audioUrl,
            fallbackImageUrl: imageUrl,
          );
          audioUrl = mediaUrls.$1;
          imageUrl = mediaUrls.$2;
        }
      }

      final updatedWord = currentWord
          .copyWith(
            arabic: arabic,
            translation: translation,
            audioUrl: audioUrl,
            imageUrl: imageUrl,
          )
          .toMap();

      existingWords[index] = updatedWord;

      transaction.update(docRef, {'words': existingWords});
    });
  }

  /// Deletes word by index from words array of specific course.
  /// Does not delete any media files from storage.
  Future<void> deleteWord({
    required String courseId,
    required int index,
  }) async {
    final docRef = _coursesRef.doc(courseId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        throw StateError('Course not found for id: $courseId');
      }

      final existingData =
          snapshot.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      final existingWords =
          (existingData['words'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList();

      if (index < 0 || index >= existingWords.length) {
        throw RangeError.index(index, existingWords, 'index');
      }

      existingWords.removeAt(index);
      transaction.update(docRef, {'words': existingWords});
    });
  }

  /// Uploads optional audio/image; missing sides use [fallbackAudioUrl] /
  /// [fallbackImageUrl] (empty strings for new words, existing URLs when updating).
  Future<(String, String)> _uploadWordMedia({
    required String courseId,
    required int wordIndex,
    required WordMediaData media,
    required String fallbackAudioUrl,
    required String fallbackImageUrl,
  }) async {
    final hasAudio =
        media.audioBytes != null && media.audioContentType != null;
    final hasImage =
        media.imageBytes != null && media.imageContentType != null;

    if (hasAudio && hasImage) {
      final results = await Future.wait([
        _uploadWordAudio(
          courseId: courseId,
          wordIndex: wordIndex,
          bytes: media.audioBytes!,
          contentType: media.audioContentType!,
        ),
        _uploadWordImage(
          courseId: courseId,
          wordIndex: wordIndex,
          bytes: media.imageBytes!,
          contentType: media.imageContentType!,
        ),
      ]);
      return (results[0], results[1]);
    }
    if (hasAudio) {
      final audioUrl = await _uploadWordAudio(
        courseId: courseId,
        wordIndex: wordIndex,
        bytes: media.audioBytes!,
        contentType: media.audioContentType!,
      );
      return (audioUrl, fallbackImageUrl);
    }
    if (hasImage) {
      final imageUrl = await _uploadWordImage(
        courseId: courseId,
        wordIndex: wordIndex,
        bytes: media.imageBytes!,
        contentType: media.imageContentType!,
      );
      return (fallbackAudioUrl, imageUrl);
    }
    return (fallbackAudioUrl, fallbackImageUrl);
  }

  Reference _wordMediaBaseRef(String courseId) {
    return _storage
        .ref()
        .child('courses')
        .child(courseId)
        .child('words');
  }

  Future<String> _uploadWordAudio({
    required String courseId,
    required int wordIndex,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final audioRef = _wordMediaBaseRef(courseId)
        .child('word_${wordIndex}_$timestamp.mp3');
    final metadata = SettableMetadata(contentType: contentType);
    await audioRef.putData(bytes, metadata);
    return audioRef.getDownloadURL();
  }

  Future<String> _uploadWordImage({
    required String courseId,
    required int wordIndex,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final imageRef = _wordMediaBaseRef(courseId)
        .child('word_${wordIndex}_$timestamp.jpg');
    final metadata = SettableMetadata(contentType: contentType);
    await imageRef.putData(bytes, metadata);
    return imageRef.getDownloadURL();
  }
}
