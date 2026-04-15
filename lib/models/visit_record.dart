class VisitRecord {
  final int? id;
  final int landmarkId;
  final String landmarkTitle;
  final double userLat;
  final double userLon;
  final DateTime visitedAt;
  final double? distanceMeters;
  final String status;
  final String? errorMessage;

  const VisitRecord({
    this.id,
    required this.landmarkId,
    required this.landmarkTitle,
    required this.userLat,
    required this.userLon,
    required this.visitedAt,
    this.distanceMeters,
    required this.status,
    this.errorMessage,
  });

  bool get isPending => status == VisitStatus.pending;

  bool get isSynced => status == VisitStatus.synced;

  factory VisitRecord.fromMap(Map<String, Object?> map) {
    return VisitRecord(
      id: _parseInt(map['id']),
      landmarkId: _parseInt(map['landmark_id']) ?? 0,
      landmarkTitle: map['landmark_title']?.toString() ?? 'Landmark',
      userLat: _parseDouble(map['user_lat']),
      userLon: _parseDouble(map['user_lon']),
      visitedAt: DateTime.tryParse(map['visited_at']?.toString() ?? '') ??
          DateTime.now(),
      distanceMeters: _parseNullableDouble(map['distance_meters']),
      status: map['status']?.toString() ?? VisitStatus.pending,
      errorMessage: map['error_message']?.toString(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'landmark_id': landmarkId,
      'landmark_title': landmarkTitle,
      'user_lat': userLat,
      'user_lon': userLon,
      'visited_at': visitedAt.toIso8601String(),
      'distance_meters': distanceMeters,
      'status': status,
      'error_message': errorMessage,
    };
  }

  VisitRecord copyWith({
    int? id,
    int? landmarkId,
    String? landmarkTitle,
    double? userLat,
    double? userLon,
    DateTime? visitedAt,
    double? distanceMeters,
    String? status,
    String? errorMessage,
  }) {
    return VisitRecord(
      id: id ?? this.id,
      landmarkId: landmarkId ?? this.landmarkId,
      landmarkTitle: landmarkTitle ?? this.landmarkTitle,
      userLat: userLat ?? this.userLat,
      userLon: userLon ?? this.userLon,
      visitedAt: visitedAt ?? this.visitedAt,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

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

  static double? _parseNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class VisitStatus {
  static const pending = 'pending';
  static const synced = 'synced';
  static const failed = 'failed';
}
