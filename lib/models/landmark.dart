class Landmark {
  final int? id;
  final String title;
  final double lat;
  final double lon;
  final String? image;
  final bool isActive;
  final int visitCount;
  final double avgDistance;
  final double score;

  const Landmark({
    this.id,
    required this.title,
    required this.lat,
    required this.lon,
    this.image,
    this.isActive = true,
    this.visitCount = 0,
    this.avgDistance = 0,
    this.score = 0,
  });

  factory Landmark.fromJson(Map<String, dynamic> json) {
    return Landmark(
      id: _parseInt(json['id']),
      title: json['title']?.toString().trim() ?? '',
      lat: _parseDouble(json['lat']),
      lon: _parseDouble(json['lon']),
      image: _emptyToNull(json['image']?.toString()),
      isActive: _parseBool(json['is_active'], fallback: true),
      visitCount: _parseInt(json['visit_count']) ?? 0,
      avgDistance: _parseDouble(json['avg_distance']),
      score: _parseDouble(json['score']),
    );
  }

  factory Landmark.fromMap(Map<String, Object?> map) {
    return Landmark(
      id: _parseInt(map['id']),
      title: map['title']?.toString() ?? '',
      lat: _parseDouble(map['lat']),
      lon: _parseDouble(map['lon']),
      image: _emptyToNull(map['image']?.toString()),
      isActive: _parseBool(map['is_active'], fallback: true),
      visitCount: _parseInt(map['visit_count']) ?? 0,
      avgDistance: _parseDouble(map['avg_distance']),
      score: _parseDouble(map['score']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lon': lon,
      'image': image,
      'is_active': isActive ? 1 : 0,
      'visit_count': visitCount,
      'avg_distance': avgDistance,
      'score': score,
    };
  }

  Landmark copyWith({
    int? id,
    String? title,
    double? lat,
    double? lon,
    String? image,
    bool? isActive,
    int? visitCount,
    double? avgDistance,
    double? score,
  }) {
    return Landmark(
      id: id ?? this.id,
      title: title ?? this.title,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      image: image ?? this.image,
      isActive: isActive ?? this.isActive,
      visitCount: visitCount ?? this.visitCount,
      avgDistance: avgDistance ?? this.avgDistance,
      score: score ?? this.score,
    );
  }

  bool get hasLocation => lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;

  bool get canUseInApp => id != null && title.isNotEmpty && hasLocation;

  static int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _parseDouble(Object? value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static bool _parseBool(Object? value, {required bool fallback}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (text == '1' || text == 'true' || text == 'yes') return true;
    if (text == '0' || text == 'false' || text == 'no') return false;
    return fallback;
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
