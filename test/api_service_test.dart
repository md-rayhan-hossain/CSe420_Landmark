import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geo_entities_app/services/landmark_api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('LandmarkApiService', () {
    test('builds exam API URLs with action and student key', () {
      final service = LandmarkApiService(
          client: MockClient((_) async => http.Response('{}', 200)));

      final uri = service.uriFor('get_landmarks');

      expect(uri.toString(),
          startsWith('https://labs.anontech.info/cse489/exm3/api.php'));
      expect(uri.queryParameters['action'], 'get_landmarks');
      expect(uri.queryParameters['key'], '21301481');
    });

    test('parses landmarks from the live response shape', () async {
      final service = LandmarkApiService(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'value': [
                {
                  'id': 4,
                  'title': 'Jaflong',
                  'lat': 25.1644,
                  'lon': 92.0175,
                  'image': 'uploads/sample.jpg',
                  'is_active': 1,
                  'visit_count': 1,
                  'avg_distance': 0,
                  'score': 8,
                }
              ],
              'Count': 1,
            }),
            200,
          );
        }),
      );

      final landmarks = await service.getLandmarks();

      expect(landmarks, hasLength(1));
      expect(landmarks.single.title, 'Jaflong');
      expect(landmarks.single.score, 8);
      expect(landmarks.single.visitCount, 1);
    });

    test('resolves relative and absolute image URLs', () {
      expect(
        LandmarkApiService.imageUrlFor('uploads/photo.jpg'),
        'https://labs.anontech.info/cse489/exm3/uploads/photo.jpg',
      );
      expect(
        LandmarkApiService.imageUrlFor('https://example.com/a.jpg'),
        'https://example.com/a.jpg',
      );
    });
  });
}
