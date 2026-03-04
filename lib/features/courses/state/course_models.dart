import 'package:meta/meta.dart';

/// Immutable model for a single word inside a course.
/// Holds arabic text, translation and media URLs.
@immutable
class CourseWord {
  final String arabic;
  final String translation;
  final String audioUrl;
  final String imageUrl;
  final bool male;

  const CourseWord({
    required this.arabic,
    required this.translation,
    required this.audioUrl,
    required this.imageUrl,
    required this.male,
  });

  /// Creates a new instance from Firestore map.
  /// Accepts dynamic map and normalizes nulls to defaults.
  factory CourseWord.fromMap(Map<String, dynamic>? data) {
    final map = data ?? <String, dynamic>{};
    return CourseWord(
      arabic: map['arabic'] as String? ?? '',
      translation: map['translation'] as String? ?? '',
      audioUrl: map['audioUrl'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      male: map['male'] as bool? ?? false,
    );
  }

  /// Converts current instance to Firestore map.
  /// Returns plain map ready for serialization.
  Map<String, dynamic> toMap() {
    return {
      'arabic': arabic,
      'translation': translation,
      'audioUrl': audioUrl,
      'imageUrl': imageUrl,
      'male': male,
    };
  }

  /// Creates a copy with updated fields.
  /// Returns new immutable instance.
  CourseWord copyWith({
    String? arabic,
    String? translation,
    String? audioUrl,
    String? imageUrl,
    bool? male,
  }) {
    return CourseWord(
      arabic: arabic ?? this.arabic,
      translation: translation ?? this.translation,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      male: male ?? this.male,
    );
  }
}

/// Immutable model for a single course document.
/// Mirrors Firestore structure for collection `courses`.
@immutable
class Course {
  final String id;
  final String title;
  final String description;
  final bool displayed;
  final String icon;
  final String imagePath;
  final String instagram;
  final bool maleTest;
  final String youtube;
  final List<CourseWord> words;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.displayed,
    required this.icon,
    required this.imagePath,
    required this.instagram,
    required this.maleTest,
    required this.youtube,
    required this.words,
  });

  /// Creates a new instance from Firestore map.
  /// Accepts id from document reference and raw data map.
  factory Course.fromMap(String id, Map<String, dynamic>? data) {
    final map = data ?? <String, dynamic>{};
    final rawWords = map['words'] as List<dynamic>? ?? const [];

    return Course(
      id: map['id'] as String? ?? id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      displayed: map['displayed'] as bool? ?? false,
      icon: map['icon'] as String? ?? '',
      imagePath: map['imagePath'] as String? ?? '',
      instagram: map['instagram'] as String? ?? '',
      maleTest: map['male_test'] as bool? ?? false,
      youtube: map['youtube'] as String? ?? '',
      words: rawWords
          .whereType<Map<String, dynamic>>()
          .map(CourseWord.fromMap)
          .toList(growable: false),
    );
  }

  /// Converts current instance to Firestore map.
  /// Returns plain map with all course fields.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'displayed': displayed,
      'icon': icon,
      'imagePath': imagePath,
      'instagram': instagram,
      'male_test': maleTest,
      'youtube': youtube,
      'words': words.map((w) => w.toMap()).toList(growable: false),
    };
  }

  /// Creates a copy with updated fields.
  /// Returns new immutable instance.
  Course copyWith({
    String? id,
    String? title,
    String? description,
    bool? displayed,
    String? icon,
    String? imagePath,
    String? instagram,
    bool? maleTest,
    String? youtube,
    List<CourseWord>? words,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      displayed: displayed ?? this.displayed,
      icon: icon ?? this.icon,
      imagePath: imagePath ?? this.imagePath,
      instagram: instagram ?? this.instagram,
      maleTest: maleTest ?? this.maleTest,
      youtube: youtube ?? this.youtube,
      words: words ?? this.words,
    );
  }
}

