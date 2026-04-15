import 'dart:convert';
import 'dart:io';

import 'package:geo_entities_app/models/landmark.dart';
import 'package:http/http.dart' as http;

class LandmarkApiService {
  LandmarkApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String studentKey = '21301481';
  static const String apiUrl = 'https://labs.anontech.info/cse489/exm3/api.php';
  static const String assetBaseUrl = 'https://labs.anontech.info/cse489/exm3/';

  final http.Client _client;

  Uri uriFor(String action) {
    return Uri.parse(apiUrl).replace(
      queryParameters: {
        'action': action,
        'key': studentKey,
      },
    );
  }

  Future<List<Landmark>> getLandmarks() async {
    final response = await _client.get(uriFor('get_landmarks'));
    _ensureHttpSuccess(response, 'load landmarks');

    final decoded = _decodeJson(response.body);
    final listData = _extractList(decoded);

    return listData
        .whereType<Map>()
        .map((item) => Landmark.fromJson(Map<String, dynamic>.from(item)))
        .where((landmark) => landmark.canUseInApp)
        .toList();
  }

  Future<VisitResult> visitLandmark({
    required int landmarkId,
    required double userLat,
    required double userLon,
  }) async {
    final response = await _client.post(
      uriFor('visit_landmark'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'landmark_id': landmarkId,
        'user_lat': userLat,
        'user_lon': userLon,
      }),
    );
    _ensureHttpSuccess(response, 'visit landmark');

    final decoded = response.body.trim().isEmpty
        ? <String, dynamic>{}
        : _decodeJson(response.body);
    _ensureApiSuccess(decoded, 'visit landmark');

    return VisitResult(
      distanceMeters: _findFirstNumber(
        decoded,
        const [
          'distance',
          'distance_meters',
          'distance_meter',
          'distanceInMeters'
        ],
      ),
      message: _findFirstString(decoded, const ['message', 'status']),
      rawBody: response.body,
    );
  }

  Future<int?> createLandmark({
    required String title,
    required double lat,
    required double lon,
    required File imageFile,
  }) async {
    final request = http.MultipartRequest('POST', uriFor('create_landmark'));
    request.fields['title'] = title;
    request.fields['lat'] = lat.toString();
    request.fields['lon'] = lon.toString();
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await http.Response.fromStream(await request.send());
    _ensureHttpSuccess(response, 'create landmark');

    if (response.body.trim().isEmpty) return null;
    final decoded = _decodeJson(response.body);
    _ensureApiSuccess(decoded, 'create landmark');
    return _findFirstNumber(decoded, const ['id', 'landmark_id'])?.toInt();
  }

  Future<void> deleteLandmark(int id) async {
    final request = http.MultipartRequest('POST', uriFor('delete_landmark'));
    request.fields['id'] = id.toString();
    final response = await http.Response.fromStream(await request.send());
    _ensureHttpSuccess(response, 'delete landmark');
    if (response.body.trim().isNotEmpty) {
      _ensureApiSuccess(_decodeJson(response.body), 'delete landmark');
    }
  }

  Future<void> restoreLandmark(int id) async {
    final request = http.MultipartRequest('POST', uriFor('restore_landmark'));
    request.fields['id'] = id.toString();
    final response = await http.Response.fromStream(await request.send());
    _ensureHttpSuccess(response, 'restore landmark');
    if (response.body.trim().isNotEmpty) {
      _ensureApiSuccess(_decodeJson(response.body), 'restore landmark');
    }
  }

  String resolveImageUrl(String? imagePath) {
    return imageUrlFor(imagePath);
  }

  static String imageUrlFor(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) return '';
    final raw = imagePath.trim().replaceAll('\\', '/');
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return Uri.parse(assetBaseUrl).resolve(raw).toString();
  }

  void close() {
    _client.close();
  }

  static dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (error) {
      throw Exception('API returned invalid JSON: $error');
    }
  }

  static List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in const [
        'value',
        'data',
        'landmarks',
        'items',
        'results'
      ]) {
        final value = decoded[key];
        if (value is List) return value;
      }
      for (final value in decoded.values) {
        if (value is List) return value;
      }
    }
    return const [];
  }

  static void _ensureHttpSuccess(http.Response response, String actionName) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(
        'Failed to $actionName: ${response.statusCode} ${response.body}');
  }

  static void _ensureApiSuccess(dynamic decoded, String actionName) {
    if (decoded is! Map) return;
    final success = decoded['success'] ?? decoded['ok'];
    if (success == false ||
        success == 0 ||
        success?.toString().toLowerCase() == 'false') {
      final message =
          decoded['message'] ?? decoded['error'] ?? 'API rejected the request';
      throw Exception('Failed to $actionName: $message');
    }
    final error = decoded['error'];
    if (error != null && error.toString().trim().isNotEmpty) {
      throw Exception('Failed to $actionName: $error');
    }
  }

  static double? _findFirstNumber(dynamic source, List<String> keys) {
    if (source is Map) {
      for (final key in keys) {
        if (source.containsKey(key)) {
          final parsed = _parseDouble(source[key]);
          if (parsed != null) return parsed;
        }
      }
      for (final value in source.values) {
        final found = _findFirstNumber(value, keys);
        if (found != null) return found;
      }
    } else if (source is List) {
      for (final value in source) {
        final found = _findFirstNumber(value, keys);
        if (found != null) return found;
      }
    }
    return null;
  }

  static String? _findFirstString(dynamic source, List<String> keys) {
    if (source is Map) {
      for (final key in keys) {
        final value = source[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      for (final value in source.values) {
        final found = _findFirstString(value, keys);
        if (found != null) return found;
      }
    } else if (source is List) {
      for (final value in source) {
        final found = _findFirstString(value, keys);
        if (found != null) return found;
      }
    }
    return null;
  }

  static double? _parseDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class VisitResult {
  final double? distanceMeters;
  final String? message;
  final String rawBody;

  const VisitResult({
    required this.distanceMeters,
    required this.message,
    required this.rawBody,
  });
}
