import 'package:flutter_test/flutter_test.dart';
import 'package:geo_entities_app/models/landmark.dart';
import 'package:geo_entities_app/models/visit_record.dart';
import 'package:geo_entities_app/services/local_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late LocalDatabase database;

  setUp(() {
    sqfliteFfiInit();
    database = LocalDatabase(
      databasePath: inMemoryDatabasePath,
      databaseFactoryOverride: databaseFactoryFfi,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('caches active and deleted landmarks', () async {
    await database.saveLandmarks(const [
      Landmark(
          id: 1,
          title: 'Active',
          lat: 23.7,
          lon: 90.4,
          isActive: true,
          score: 4),
      Landmark(
          id: 2,
          title: 'Deleted',
          lat: 24.0,
          lon: 91.0,
          isActive: false,
          score: 1),
    ]);

    final active = await database.getLandmarks(activeOnly: true);
    final deleted = await database.getDeletedLandmarks();

    expect(active.map((item) => item.title), ['Active']);
    expect(deleted.map((item) => item.title), ['Deleted']);
  });

  test('stores queued visits and updates synced status', () async {
    final visitId = await database.insertVisit(
      VisitRecord(
        landmarkId: 1,
        landmarkTitle: 'Jaflong',
        userLat: 23.7,
        userLon: 90.4,
        visitedAt: DateTime.utc(2026, 4, 13),
        status: VisitStatus.pending,
      ),
    );

    var pending = await database.getPendingVisits();
    expect(pending, hasLength(1));

    await database.updateVisit(
      pending.single.copyWith(
        id: visitId,
        status: VisitStatus.synced,
        distanceMeters: 42.5,
      ),
    );

    pending = await database.getPendingVisits();
    final allVisits = await database.getVisits();

    expect(pending, isEmpty);
    expect(allVisits.single.status, VisitStatus.synced);
    expect(allVisits.single.distanceMeters, 42.5);
  });
}
