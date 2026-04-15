import 'package:flutter/material.dart';
import 'package:geo_entities_app/models/landmark.dart';
import 'package:geo_entities_app/utils/formatters.dart';
import 'package:geo_entities_app/widgets/empty_state.dart';
import 'package:geo_entities_app/widgets/landmark_image.dart';
import 'package:geo_entities_app/widgets/score_badge.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapTab extends StatefulWidget {
  final List<Landmark> landmarks;
  final bool isLoading;
  final bool enableMap;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Landmark landmark) onVisit;
  final Future<void> Function(Landmark landmark) onDelete;

  const MapTab({
    super.key,
    required this.landmarks,
    required this.isLoading,
    required this.enableMap,
    required this.onRefresh,
    required this.onVisit,
    required this.onDelete,
  });

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  static const LatLng _bangladeshCenter = LatLng(23.6850, 90.3563);
  static const double _defaultZoom = 6.95;

  GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.landmarks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!widget.enableMap) {
      return EmptyState(
        icon: Icons.map_outlined,
        title: 'Map disabled for this run',
        message: 'The production app opens this tab with Google Maps enabled.',
        actionLabel: 'Refresh landmarks',
        onAction: widget.onRefresh,
      );
    }

    if (widget.landmarks.isEmpty) {
      return EmptyState(
        icon: Icons.travel_explore_outlined,
        title: 'No active landmarks',
        message: 'Refresh when you are online or add a new landmark.',
        actionLabel: 'Refresh',
        onAction: widget.onRefresh,
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _bangladeshCenter,
            zoom: _defaultZoom,
          ),
          onMapCreated: (controller) => _controller = controller,
          markers: _markersFor(context),
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'map_refresh',
                  tooltip: 'Refresh landmarks',
                  onPressed: widget.onRefresh,
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'map_bangladesh',
                  tooltip: 'Center on Bangladesh',
                  onPressed: _centerBangladesh,
                  child: const Icon(Icons.public),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Set<Marker> _markersFor(BuildContext context) {
    final scores = widget.landmarks.map((landmark) => landmark.score).toList();
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final maxScore = scores.reduce((a, b) => a > b ? a : b);

    return widget.landmarks.map((landmark) {
      return Marker(
        markerId: MarkerId('landmark_${landmark.id}'),
        position: LatLng(landmark.lat, landmark.lon),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            _hueForScore(landmark.score, minScore, maxScore)),
        infoWindow: InfoWindow(
          title: landmark.title,
          snippet: 'Score ${formatScore(landmark.score)}',
        ),
        onTap: () => _showLandmarkSheet(context, landmark),
      );
    }).toSet();
  }

  double _hueForScore(double score, double minScore, double maxScore) {
    if (maxScore == minScore) return BitmapDescriptor.hueAzure;
    final ratio = ((score - minScore) / (maxScore - minScore)).clamp(0.0, 1.0);
    return BitmapDescriptor.hueRed +
        (BitmapDescriptor.hueGreen - BitmapDescriptor.hueRed) * ratio;
  }

  void _centerBangladesh() {
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(target: _bangladeshCenter, zoom: _defaultZoom),
      ),
    );
  }

  void _showLandmarkSheet(BuildContext context, Landmark landmark) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LandmarkImage(
                        imagePath: landmark.image, width: 112, height: 112),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            landmark.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          ScoreBadge(score: landmark.score),
                          const SizedBox(height: 8),
                          Text('${landmark.visitCount} visits'),
                          Text(
                              'Average distance ${formatDistance(landmark.avgDistance)}'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                    'Location ${formatCoordinate(landmark.lat)}, ${formatCoordinate(landmark.lon)}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onVisit(landmark);
                        },
                        icon: const Icon(Icons.near_me_outlined),
                        label: const Text('Visit landmark'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onDelete(landmark);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
