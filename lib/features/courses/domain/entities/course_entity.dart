/// Domain entity representing a real database-backed course from TrueLern.
/// Source: GET /api/public/courses
class CourseEntity {
  const CourseEntity({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.slug,
    this.shortDescription = '',
    this.categoryName,
    this.level = 'all',
    this.duration,
    this.durationUnit,
    this.deliveryMode,
    this.certificateAvailable = false,
    this.featured = false,
    this.price,
    this.discountPrice,
    this.displayPrice,
    this.currency = 'USD',
    this.isEnrollmentOpen = true,
  });

  final String id;
  final String courseCode;
  final String courseName;
  final String slug;
  final String shortDescription;
  final String? categoryName;
  final String level;
  final int? duration;
  final String? durationUnit;
  final String? deliveryMode;
  final bool certificateAvailable;
  final bool featured;
  final num? price;
  final num? discountPrice;
  final num? displayPrice;
  final String currency;
  final bool isEnrollmentOpen;

  /// Formatted duration string, e.g. "12 weeks" or "8 weeks".
  String get formattedDuration {
    if (duration == null) return '';
    final unit = durationUnit ?? 'weeks';
    return '$duration $unit';
  }

  /// Parses course object from backend JSON representation.
  factory CourseEntity.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] is Map<String, dynamic>
        ? json['pricing'] as Map<String, dynamic>
        : <String, dynamic>{};

    final category = json['category'] is Map<String, dynamic>
        ? json['category'] as Map<String, dynamic>
        : null;

    final name =
        (json['courseName'] ??
                json['programName'] ??
                json['course_name'] ??
                json['title'] ??
                json['name'] ??
                json['program'] ??
                '')
            .toString()
            .trim();
    final rawId =
        (json['_id'] ??
                json['id'] ??
                json['courseId'] ??
                json['course_id'] ??
                json['programId'] ??
                '')
            .toString()
            .trim();
    final slug = (json['slug'] ?? '').toString().trim();
    final id = rawId.isNotEmpty ? rawId : (slug.isNotEmpty ? slug : name);
    final code = (json['courseCode'] ?? json['code'] ?? '').toString().trim();

    return CourseEntity(
      id: id,
      courseCode: code,
      courseName: name,
      slug: (json['slug'] ?? '').toString(),
      shortDescription: (json['shortDescription'] ?? json['description'] ?? '')
          .toString(),
      categoryName: category?['name'] as String?,
      level: (json['level'] ?? 'all').toString(),
      duration: json['duration'] is int
          ? json['duration'] as int
          : int.tryParse(json['duration']?.toString() ?? ''),
      durationUnit: json['durationUnit']?.toString(),
      deliveryMode: json['deliveryMode']?.toString(),
      certificateAvailable: json['certificateAvailable'] == true,
      featured: json['featured'] == true,
      price: pricing['price'] as num?,
      discountPrice: pricing['discountPrice'] as num?,
      displayPrice: pricing['displayPrice'] as num?,
      currency: (pricing['currency'] ?? 'USD').toString(),
      isEnrollmentOpen:
          json['isEnrollmentOpen'] == true ||
          (json['openCohortsCount'] is int &&
              (json['openCohortsCount'] as int) > 0),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'courseCode': courseCode,
    'courseName': courseName,
    'slug': slug,
    'shortDescription': shortDescription,
    'level': level,
    'duration': duration,
    'durationUnit': durationUnit,
    'deliveryMode': deliveryMode,
    'certificateAvailable': certificateAvailable,
    'featured': featured,
    'pricing': {
      'price': price,
      'discountPrice': discountPrice,
      'displayPrice': displayPrice,
      'currency': currency,
    },
    'isEnrollmentOpen': isEnrollmentOpen,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CourseEntity(id: $id, code: $courseCode, name: $courseName)';
}
