/// Available course filters on the courses screen.
/// Each value maps to Firestore `description` used for filtering and creation.
enum CourseFilter {
  basicArabic,
  arabicByEar,
}

extension CourseFilterX on CourseFilter {
  String get description {
    switch (this) {
      case CourseFilter.basicArabic:
        return 'Базовый арабский';
      case CourseFilter.arabicByEar:
        return 'Арабский на слух';
    }
  }

  String get label => description;
}

