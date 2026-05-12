import 'dart:developer' show log;
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

String _wordCrudUrlPreview(String url, [int max = 120]) {
  if (url.isEmpty) return '(empty)';
  if (url.length <= max) return url;
  return '${url.substring(0, max)}…';
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
    log(
      'addWord: enter courseId=$courseId arabicLen=${arabic.length} '
      'translationLen=${translation.length} '
      'media audioBytes=${media.audioBytes?.length ?? 0} '
      'audioContentType=${media.audioContentType} '
      'imageBytes=${media.imageBytes?.length ?? 0} '
      'imageContentType=${media.imageContentType}',
      name: 'WordCRUD.service',
    );
    final docRef = _coursesRef.doc(courseId);

    await _firestore.runTransaction((transaction) async {
      log('addWord: transaction start courseId=$courseId', name: 'WordCRUD.service');
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        log('addWord: transaction abort course not found courseId=$courseId', name: 'WordCRUD.service');
        throw StateError('Course not found for id: $courseId');
      }

      final existingData =
          snapshot.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      final existingWords =
          (existingData['words'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList();

      final newIndex = existingWords.length;
      log(
        'addWord: transaction read OK wordsCount=$newIndex (new word index=$newIndex)',
        name: 'WordCRUD.service',
      );

      log(
        'addWord: uploading media wordIndex=$newIndex fallbacks audio="" image=""',
        name: 'WordCRUD.service',
      );
      final mediaUrls = await _uploadWordMedia(
        courseId: courseId,
        wordIndex: newIndex,
        media: media,
        fallbackAudioUrl: '',
        fallbackImageUrl: '',
      );
      log(
        'addWord: upload done audioUrl=${_wordCrudUrlPreview(mediaUrls.$1)} '
        'imageUrl=${_wordCrudUrlPreview(mediaUrls.$2)}',
        name: 'WordCRUD.service',
      );

      final newWord = CourseWord(
        arabic: arabic,
        translation: translation,
        audioUrl: mediaUrls.$1,
        imageUrl: mediaUrls.$2,
        male: false,
      ).toMap();

      existingWords.add(newWord);

      log(
        'addWord: transaction.update words len=${existingWords.length}',
        name: 'WordCRUD.service',
      );
      transaction.update(docRef, {'words': existingWords});
    });
    log('addWord: transaction committed courseId=$courseId', name: 'WordCRUD.service');
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
    log(
      'updateWord: enter courseId=$courseId index=$index arabicLen=${arabic.length} '
      'translationLen=${translation.length} mediaNull=${media == null}',
      name: 'WordCRUD.service',
    );
    if (media != null) {
      log(
        'updateWord: media payload audioBytes=${media.audioBytes?.length ?? 0} '
        'audioContentType=${media.audioContentType} '
        'imageBytes=${media.imageBytes?.length ?? 0} '
        'imageContentType=${media.imageContentType}',
        name: 'WordCRUD.service',
      );
    }
    final docRef = _coursesRef.doc(courseId);

    await _firestore.runTransaction((transaction) async {
      log(
        'updateWord: transaction start courseId=$courseId index=$index',
        name: 'WordCRUD.service',
      );
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        log('updateWord: transaction abort course not found', name: 'WordCRUD.service');
        throw StateError('Course not found for id: $courseId');
      }

      final existingData =
          snapshot.data() as Map<String, dynamic>? ?? <String, dynamic>{};
      final existingWords =
          (existingData['words'] as List<dynamic>? ?? <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList();

      if (index < 0 || index >= existingWords.length) {
        log(
          'updateWord: transaction abort bad index=$index wordsLen=${existingWords.length}',
          name: 'WordCRUD.service',
        );
        throw RangeError.index(index, existingWords, 'index');
      }

      final currentWord = CourseWord.fromMap(
        existingWords[index] as Map<String, dynamic>?,
      );

      String audioUrl = currentWord.audioUrl;
      String imageUrl = currentWord.imageUrl;
      log(
        'updateWord: current urls audio=${_wordCrudUrlPreview(audioUrl)} '
        'image=${_wordCrudUrlPreview(imageUrl)}',
        name: 'WordCRUD.service',
      );

      if (media != null) {
        final hasUpload = (media.audioBytes != null &&
                media.audioContentType != null) ||
            (media.imageBytes != null && media.imageContentType != null);
        log('updateWord: hasUpload=$hasUpload', name: 'WordCRUD.service');
        if (hasUpload) {
          log(
            'updateWord: calling _uploadWordMedia index=$index '
            'fallbackAudioLen=${audioUrl.length} fallbackImageLen=${imageUrl.length}',
            name: 'WordCRUD.service',
          );
          final mediaUrls = await _uploadWordMedia(
            courseId: courseId,
            wordIndex: index,
            media: media,
            fallbackAudioUrl: audioUrl,
            fallbackImageUrl: imageUrl,
          );
          audioUrl = mediaUrls.$1;
          imageUrl = mediaUrls.$2;
          log(
            'updateWord: upload done new audio=${_wordCrudUrlPreview(audioUrl)} '
            'new image=${_wordCrudUrlPreview(imageUrl)}',
            name: 'WordCRUD.service',
          );
        } else {
          log(
            'updateWord: media object present but hasUpload=false (no bytes)',
            name: 'WordCRUD.service',
          );
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

      log('updateWord: transaction.update index=$index', name: 'WordCRUD.service');
      transaction.update(docRef, {'words': existingWords});
    });
    log(
      'updateWord: transaction committed courseId=$courseId index=$index',
      name: 'WordCRUD.service',
    );
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
    log(
      '_uploadWordMedia: courseId=$courseId wordIndex=$wordIndex '
      'hasAudio=$hasAudio hasImage=$hasImage '
      'fallbackAudioLen=${fallbackAudioUrl.length} fallbackImageLen=${fallbackImageUrl.length}',
      name: 'WordCRUD.service',
    );

    if (hasAudio && hasImage) {
      log('_uploadWordMedia: parallel audio+image', name: 'WordCRUD.service');
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
      log(
        '_uploadWordMedia: parallel done audio=${_wordCrudUrlPreview(results[0])} '
        'image=${_wordCrudUrlPreview(results[1])}',
        name: 'WordCRUD.service',
      );
      return (results[0], results[1]);
    }
    if (hasAudio) {
      log('_uploadWordMedia: audio only', name: 'WordCRUD.service');
      final audioUrl = await _uploadWordAudio(
        courseId: courseId,
        wordIndex: wordIndex,
        bytes: media.audioBytes!,
        contentType: media.audioContentType!,
      );
      log(
        '_uploadWordMedia: audio only done audio=${_wordCrudUrlPreview(audioUrl)} '
        'imageFallback=${_wordCrudUrlPreview(fallbackImageUrl)}',
        name: 'WordCRUD.service',
      );
      return (audioUrl, fallbackImageUrl);
    }
    if (hasImage) {
      log('_uploadWordMedia: image only', name: 'WordCRUD.service');
      final imageUrl = await _uploadWordImage(
        courseId: courseId,
        wordIndex: wordIndex,
        bytes: media.imageBytes!,
        contentType: media.imageContentType!,
      );
      log(
        '_uploadWordMedia: image only done audioFallback=${_wordCrudUrlPreview(fallbackAudioUrl)} '
        'image=${_wordCrudUrlPreview(imageUrl)}',
        name: 'WordCRUD.service',
      );
      return (fallbackAudioUrl, imageUrl);
    }
    log(
      '_uploadWordMedia: no uploads, return fallbacks',
      name: 'WordCRUD.service',
    );
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
    final path = 'courses/$courseId/words/word_${wordIndex}_$timestamp.mp3';
    log(
      '_uploadWordAudio: path=$path bytes=${bytes.length} contentType=$contentType',
      name: 'WordCRUD.service',
    );
    final metadata = SettableMetadata(contentType: contentType);
    log('_uploadWordAudio: putData start', name: 'WordCRUD.service');
    await audioRef.putData(bytes, metadata);
    log('_uploadWordAudio: putData done, getDownloadURL', name: 'WordCRUD.service');
    final url = await audioRef.getDownloadURL();
    log('_uploadWordAudio: OK url=${_wordCrudUrlPreview(url)}', name: 'WordCRUD.service');
    return url;
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
    final path = 'courses/$courseId/words/word_${wordIndex}_$timestamp.jpg';
    log(
      '_uploadWordImage: path=$path bytes=${bytes.length} contentType=$contentType',
      name: 'WordCRUD.service',
    );
    final metadata = SettableMetadata(contentType: contentType);
    log('_uploadWordImage: putData start', name: 'WordCRUD.service');
    await imageRef.putData(bytes, metadata);
    log('_uploadWordImage: putData done, getDownloadURL', name: 'WordCRUD.service');
    final url = await imageRef.getDownloadURL();
    log('_uploadWordImage: OK url=${_wordCrudUrlPreview(url)}', name: 'WordCRUD.service');
    return url;
  }
}
