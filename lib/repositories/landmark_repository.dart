import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geo_entities_app/models/landmark.dart';
import 'package:geo_entities_app/models/visit_record.dart';
import 'package:geo_entities_app/services/landmark_api_service.dart';
import 'package:geo_entities_app/services/local_database.dart';

class LandmarkRepository {
  LandmarkRepository({
    required LandmarkApiService apiService,
    required LocalDatabase localDatabase,
    Connectivity? connectivity,
  })  : _apiService = apiService,
        _localDatabase = localDatabase,
        _connectivity = connectivity ?? Connectivity();

  final LandmarkApiService _apiService;
  final LocalDatabase _localDatabase;
  final Connectivity _connectivity;

  Future<LandmarkLoadResult> loadLandmarks() async {
    try {
      final landmarks = await _apiService.getLandmarks();
      final locallyDeleted = await _localDatabase.getDeletedLandmarks();
      final locallyDeletedIds =
          locallyDeleted.map((landmark) => landmark.id).toSet();
      await _localDatabase.saveLandmarks(
        landmarks
            .where((landmark) =>
                !locallyDeletedIds.contains(landmark.id) || !landmark.isActive)
            .toList(),
      );
      final apiDeleted =
          landmarks.where((landmark) => !landmark.isActive).toList();
      return LandmarkLoadResult(
        landmarks: landmarks
            .where((landmark) =>
                landmark.isActive && !locallyDeletedIds.contains(landmark.id))
            .toList(),
        deletedLandmarks: _uniqueById([...apiDeleted, ...locallyDeleted]),
        fromCache: false,
      );
    } catch (error) {
      final cached = await _localDatabase.getLandmarks();
      return LandmarkLoadResult(
        landmarks: cached.where((landmark) => landmark.isActive).toList(),
        deletedLandmarks:
            cached.where((landmark) => !landmark.isActive).toList(),
        fromCache: true,
        error: error,
      );
    }
  }

  Future<List<VisitRecord>> loadVisits() {
    return _localDatabase.getVisits();
  }

  Future<VisitRecord> visitLandmark({
    required Landmark landmark,
    required double userLat,
    required double userLon,
  }) async {
    if (landmark.id == null) {
      throw Exception('Cannot visit landmark without an ID');
    }

    final visit = VisitRecord(
      landmarkId: landmark.id!,
      landmarkTitle: landmark.title,
      userLat: userLat,
      userLon: userLon,
      visitedAt: DateTime.now(),
      status: VisitStatus.pending,
    );

    final visitId = await _localDatabase.insertVisit(visit);
    final storedVisit = visit.copyWith(id: visitId);

    if (!await hasNetworkConnection()) {
      return storedVisit;
    }

    try {
      return await _sendVisit(storedVisit);
    } catch (_) {
      return storedVisit;
    }
  }

  Future<int> syncQueuedVisits() async {
    if (!await hasNetworkConnection()) return 0;

    final pendingVisits = await _localDatabase.getPendingVisits();
    var syncedCount = 0;
    for (final visit in pendingVisits) {
      final synced = await _sendVisit(visit, convertFailureToStatus: true);
      if (synced.isSynced) syncedCount++;
    }
    if (syncedCount > 0) {
      final latest = await _apiService.getLandmarks();
      await _localDatabase.saveLandmarks(latest);
    }
    return syncedCount;
  }

  Future<void> createLandmark({
    required String title,
    required double lat,
    required double lon,
    required File imageFile,
  }) async {
    if (!await hasNetworkConnection()) {
      throw Exception('Creating landmarks requires an internet connection');
    }
    await _apiService.createLandmark(
      title: title,
      lat: lat,
      lon: lon,
      imageFile: imageFile,
    );
    final latest = await _apiService.getLandmarks();
    await _localDatabase.saveLandmarks(latest);
  }

  Future<void> deleteLandmark(Landmark landmark) async {
    if (landmark.id == null) return;
    if (!await hasNetworkConnection()) {
      throw Exception('Deleting landmarks requires an internet connection');
    }
    await _apiService.deleteLandmark(landmark.id!);
    await _localDatabase.markLandmarkActive(landmark.id!, false);
  }

  Future<void> restoreLandmark(Landmark landmark) async {
    if (landmark.id == null) return;
    if (!await hasNetworkConnection()) {
      throw Exception('Restoring landmarks requires an internet connection');
    }
    await _apiService.restoreLandmark(landmark.id!);
    await _localDatabase.markLandmarkActive(landmark.id!, true);
    final latest = await _apiService.getLandmarks();
    await _localDatabase.saveLandmarks(latest);
  }

  Future<bool> hasNetworkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<VisitRecord> _sendVisit(
    VisitRecord visit, {
    bool convertFailureToStatus = false,
  }) async {
    try {
      final result = await _apiService.visitLandmark(
        landmarkId: visit.landmarkId,
        userLat: visit.userLat,
        userLon: visit.userLon,
      );
      final syncedVisit = visit.copyWith(
        distanceMeters: result.distanceMeters,
        status: VisitStatus.synced,
        errorMessage: null,
      );
      await _localDatabase.updateVisit(syncedVisit);
      return syncedVisit;
    } catch (error) {
      if (!convertFailureToStatus) rethrow;
      final failedVisit = visit.copyWith(
        status: VisitStatus.failed,
        errorMessage: error.toString(),
      );
      await _localDatabase.updateVisit(failedVisit);
      return failedVisit;
    }
  }

  void dispose() {
    _apiService.close();
  }

  List<Landmark> _uniqueById(List<Landmark> landmarks) {
    final byId = <int, Landmark>{};
    final withoutId = <Landmark>[];
    for (final landmark in landmarks) {
      final id = landmark.id;
      if (id == null) {
        withoutId.add(landmark);
      } else {
        byId[id] = landmark;
      }
    }
    return [...byId.values, ...withoutId];
  }
}

class LandmarkLoadResult {
  final List<Landmark> landmarks;
  final List<Landmark> deletedLandmarks;
  final bool fromCache;
  final Object? error;

  const LandmarkLoadResult({
    required this.landmarks,
    required this.deletedLandmarks,
    required this.fromCache,
    this.error,
  });
}
