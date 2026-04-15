import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geo_entities_app/models/landmark.dart';
import 'package:geo_entities_app/models/visit_record.dart';
import 'package:geo_entities_app/repositories/landmark_repository.dart';
import 'package:geo_entities_app/screens/tabs/activity_tab.dart';
import 'package:geo_entities_app/screens/tabs/add_view_tab.dart';
import 'package:geo_entities_app/screens/tabs/landmarks_tab.dart';
import 'package:geo_entities_app/screens/tabs/map_tab.dart';
import 'package:geo_entities_app/services/landmark_api_service.dart';
import 'package:geo_entities_app/services/local_database.dart';
import 'package:geo_entities_app/services/location_service.dart';
import 'package:geo_entities_app/utils/formatters.dart';

class SmartLandmarksHome extends StatefulWidget {
  final bool enableMap;
  final bool loadOnStart;

  const SmartLandmarksHome({
    super.key,
    this.enableMap = true,
    this.loadOnStart = true,
  });

  @override
  State<SmartLandmarksHome> createState() => _SmartLandmarksHomeState();
}

class _SmartLandmarksHomeState extends State<SmartLandmarksHome> {
  late final LocalDatabase _localDatabase;
  late final LandmarkRepository _repository;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final List<Landmark> _landmarks = [];
  final List<Landmark> _deletedLandmarks = [];
  final List<VisitRecord> _visits = [];

  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isSyncing = false;
  bool _fromCache = false;

  static const _titles = ['Map', 'Landmarks', 'Activity', 'Add/View'];

  @override
  void initState() {
    super.initState();
    _localDatabase = LocalDatabase();
    _repository = LandmarkRepository(
      apiService: LandmarkApiService(),
      localDatabase: _localDatabase,
    );

    if (widget.loadOnStart) {
      _bootstrap();
      _connectivitySubscription =
          Connectivity().onConnectivityChanged.listen((results) {
        if (results.any((result) => result != ConnectivityResult.none)) {
          _syncQueuedVisits(silent: true);
        }
      });
    }
  }

  Future<void> _bootstrap() async {
    await _refreshLandmarks(showLoading: true);
    await _syncQueuedVisits(silent: true);
    await _loadVisits();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      MapTab(
        landmarks: _landmarks,
        isLoading: _isLoading,
        enableMap: widget.enableMap,
        onRefresh: _refreshLandmarks,
        onVisit: _visitLandmark,
        onDelete: _deleteLandmark,
      ),
      LandmarksTab(
        landmarks: _landmarks,
        isLoading: _isLoading,
        fromCache: _fromCache,
        onRefresh: _refreshLandmarks,
        onVisit: _visitLandmark,
        onDelete: _deleteLandmark,
      ),
      ActivityTab(
        visits: _visits,
        isSyncing: _isSyncing,
        onRefresh: _loadVisits,
        onSync: () => _syncQueuedVisits(silent: false),
      ),
      AddViewTab(
        deletedLandmarks: _deletedLandmarks,
        isActive: _currentIndex == 3,
        autoFetchLocation: widget.loadOnStart,
        onCreate: _createLandmark,
        onRestore: _restoreLandmark,
        onRefresh: _refreshLandmarks,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          if (_currentIndex == 2)
            IconButton(
              tooltip: 'Sync visits',
              onPressed:
                  _isSyncing ? null : () => _syncQueuedVisits(silent: false),
              icon: const Icon(Icons.sync),
            )
          else
            IconButton(
              tooltip: 'Refresh',
              onPressed: _isLoading ? null : _refreshLandmarks,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Map'),
          NavigationDestination(
              icon: Icon(Icons.place_outlined),
              selectedIcon: Icon(Icons.place),
              label: 'Landmarks'),
          NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Activity'),
          NavigationDestination(
              icon: Icon(Icons.add_location_alt_outlined),
              selectedIcon: Icon(Icons.add_location_alt),
              label: 'Add/View'),
        ],
      ),
    );
  }

  Future<void> _refreshLandmarks({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    final result = await _repository.loadLandmarks();
    if (!mounted) return;

    setState(() {
      _landmarks
        ..clear()
        ..addAll(result.landmarks);
      _deletedLandmarks
        ..clear()
        ..addAll(result.deletedLandmarks);
      _fromCache = result.fromCache;
      _isLoading = false;
    });

    if (result.fromCache && result.error != null) {
      _showSnack('Showing cached landmarks. Live API error: ${result.error}');
    }
  }

  Future<void> _loadVisits() async {
    final visits = await _repository.loadVisits();
    if (!mounted) return;
    setState(() {
      _visits
        ..clear()
        ..addAll(visits);
    });
  }

  Future<void> _syncQueuedVisits({required bool silent}) async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      final syncedCount = await _repository.syncQueuedVisits();
      await _loadVisits();
      if (syncedCount > 0) {
        await _refreshLandmarks(showLoading: false);
      }
      if (!silent && mounted) {
        _showSnack(syncedCount == 0
            ? 'No queued visits to sync'
            : 'Synced $syncedCount queued visits');
      }
    } catch (error) {
      if (!silent && mounted) _showSnack('Sync failed: $error');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _visitLandmark(Landmark landmark) async {
    final locationData = await LocationService.getCurrentLocation();
    if (!mounted) return;

    if (locationData?.latitude == null || locationData?.longitude == null) {
      _showSnack('Current GPS location is not available');
      return;
    }

    try {
      final visit = await _repository.visitLandmark(
        landmark: landmark,
        userLat: locationData!.latitude!,
        userLon: locationData.longitude!,
      );
      await _loadVisits();
      if (visit.isSynced) {
        await _refreshLandmarks(showLoading: false);
        _showSnack(
            'Visit recorded. Distance: ${formatDistance(visit.distanceMeters)}');
      } else {
        _showSnack('Visit queued for offline sync');
      }
    } catch (error) {
      _showSnack('Visit failed: $error');
    }
  }

  Future<void> _createLandmark({
    required String title,
    required double lat,
    required double lon,
    required File imageFile,
  }) async {
    await _repository.createLandmark(
      title: title,
      lat: lat,
      lon: lon,
      imageFile: imageFile,
    );
    await _refreshLandmarks(showLoading: false);
  }

  Future<void> _deleteLandmark(Landmark landmark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete landmark'),
        content: Text(
            'Soft delete ${landmark.title}? It can be restored from Add/View.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteLandmark(landmark);
      if (!mounted) return;
      setState(() {
        _landmarks.removeWhere((item) => item.id == landmark.id);
        _deletedLandmarks
          ..removeWhere((item) => item.id == landmark.id)
          ..add(landmark.copyWith(isActive: false));
      });
      _showSnack('Landmark deleted');
    } catch (error) {
      if (mounted) _showSnack('Delete failed: $error');
    }
  }

  Future<void> _restoreLandmark(Landmark landmark) async {
    try {
      await _repository.restoreLandmark(landmark);
      await _refreshLandmarks(showLoading: false);
      if (mounted) _showSnack('Landmark restored');
    } catch (error) {
      if (mounted) _showSnack('Restore failed: $error');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _repository.dispose();
    _localDatabase.close();
    super.dispose();
  }
}
