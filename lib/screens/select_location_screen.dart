// lib/screens/select_location_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geo_entities_app/services/location_service.dart';
import 'package:location/location.dart' as loc;

class SelectLocationScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const SelectLocationScreen({super.key, this.initialPosition});

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  static const LatLng _bangladeshCenter = LatLng(23.6850, 90.3563);
  LatLng? _selected;
  LatLng _cameraTarget = _bangladeshCenter;
  GoogleMapController? _controller;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _cameraTarget = widget.initialPosition!;
      _selected = widget.initialPosition;
    } else {
      _tryUseCurrentLocation();
    }
  }

  Future<void> _tryUseCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    final loc.LocationData? locData =
        await LocationService.getCurrentLocation();
    if (!mounted) return;
    if (locData != null &&
        locData.latitude != null &&
        locData.longitude != null) {
      setState(() {
        _cameraTarget = LatLng(locData.latitude!, locData.longitude!);
      });
    }
    setState(() => _isGettingLocation = false);
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _selected = latLng;
    });
    // optionally animate to the selected location
    _controller?.animateCamera(CameraUpdate.newLatLng(latLng));
  }

  void _onConfirm() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tap on the map to choose a location first')));
      return;
    }
    Navigator.of(context).pop(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose landmark location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Confirm location',
            onPressed: _onConfirm,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: _cameraTarget, zoom: 14.0),
            onMapCreated: (controller) => _controller = controller,
            onTap: _onMapTap,
            markers: _selected == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selected!,
                    )
                  },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),

          // small overlay showing coords of currently selected pin (if any)
          if (_selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          'Selected: ${_selected!.latitude.toStringAsFixed(6)}, ${_selected!.longitude.toStringAsFixed(6)}'),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _selected = null),
                            child: const Text('Clear'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _onConfirm,
                            child: const Text('Use this location'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // quick center-to-current-location FAB
          Positioned(
            left: 12,
            top: 12,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'center_here',
                onPressed: () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  setState(() => _isGettingLocation = true);
                  final loc.LocationData? cur =
                      await LocationService.getCurrentLocation();
                  if (!mounted) return;
                  setState(() => _isGettingLocation = false);
                  if (cur != null &&
                      cur.latitude != null &&
                      cur.longitude != null) {
                    final LatLng p = LatLng(cur.latitude!, cur.longitude!);
                    _controller
                        ?.animateCamera(CameraUpdate.newLatLngZoom(p, 16.0));
                  } else {
                    scaffoldMessenger.showSnackBar(const SnackBar(
                        content: Text('Current location not available')));
                  }
                },
                child: _isGettingLocation
                    ? const CircularProgressIndicator.adaptive()
                    : const Icon(Icons.my_location),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
