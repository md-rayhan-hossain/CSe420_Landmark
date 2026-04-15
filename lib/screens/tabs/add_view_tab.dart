import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geo_entities_app/models/landmark.dart';
import 'package:geo_entities_app/screens/select_location_screen.dart';
import 'package:geo_entities_app/services/location_service.dart';
import 'package:geo_entities_app/utils/formatters.dart';
import 'package:geo_entities_app/widgets/empty_state.dart';
import 'package:geo_entities_app/widgets/landmark_summary_card.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AddViewTab extends StatefulWidget {
  final List<Landmark> deletedLandmarks;
  final bool isActive;
  final bool autoFetchLocation;
  final Future<void> Function({
    required String title,
    required double lat,
    required double lon,
    required File imageFile,
  }) onCreate;
  final Future<void> Function(Landmark landmark) onRestore;
  final Future<void> Function() onRefresh;

  const AddViewTab({
    super.key,
    required this.deletedLandmarks,
    required this.isActive,
    this.autoFetchLocation = true,
    required this.onCreate,
    required this.onRestore,
    required this.onRefresh,
  });

  @override
  State<AddViewTab> createState() => _AddViewTabState();
}

class _AddViewTabState extends State<AddViewTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _imagePicker = ImagePicker();

  File? _imageFile;
  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  bool _didAutoFetchLocation = false;

  @override
  void initState() {
    super.initState();
    _maybeAutoFetchLocation();
  }

  @override
  void didUpdateWidget(covariant AddViewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeAutoFetchLocation();
  }

  void _maybeAutoFetchLocation() {
    if (!widget.autoFetchLocation ||
        !widget.isActive ||
        _didAutoFetchLocation) {
      return;
    }
    _didAutoFetchLocation = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fillCurrentLocation(showFailure: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildFormCard()),
          SliverToBoxAdapter(
              child:
                  _buildDeletedHeader(count: widget.deletedLandmarks.length)),
          if (widget.deletedLandmarks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.restore_outlined,
                title: 'No deleted landmarks',
                message:
                    'Soft-deleted landmarks you know about will appear here for restore.',
                actionLabel: 'Refresh',
                onAction: widget.onRefresh,
              ),
            )
          else
            SliverList.builder(
              itemCount: widget.deletedLandmarks.length,
              itemBuilder: (context, index) {
                final landmark = widget.deletedLandmarks[index];
                return LandmarkSummaryCard(
                  landmark: landmark,
                  onRestore: () => widget.onRestore(landmark),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Create a landmark with GPS and image, or restore a soft-deleted one.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New landmark',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                textInputAction: TextInputAction.next,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: _validateLatitude,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lonController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: _validateLongitude,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isGettingLocation
                        ? null
                        : () => _fillCurrentLocation(),
                    icon: _isGettingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location_outlined),
                    label: const Text('Use current GPS'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _chooseLocationOnMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Choose on map'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Pick image'),
                  ),
                ],
              ),
              if (_imageFile != null) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      Image.file(_imageFile!, height: 180, fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_location_alt_outlined),
                label: Text(_isSubmitting ? 'Creating...' : 'Create landmark'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeletedHeader({required int count}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Deleted landmarks',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text('$count saved',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black54)),
        ],
      ),
    );
  }

  Future<void> _fillCurrentLocation({bool showFailure = true}) async {
    setState(() => _isGettingLocation = true);
    final locationData = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isGettingLocation = false);

    if (locationData?.latitude == null || locationData?.longitude == null) {
      if (showFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current location is not available')),
        );
      }
      return;
    }

    _latController.text = formatCoordinate(locationData!.latitude!);
    _lonController.text = formatCoordinate(locationData.longitude!);
  }

  Future<void> _chooseLocationOnMap() async {
    final initialLat = double.tryParse(_latController.text.trim());
    final initialLon = double.tryParse(_lonController.text.trim());
    final initial = initialLat != null && initialLon != null
        ? LatLng(initialLat, initialLon)
        : null;

    final selected = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
          builder: (context) => SelectLocationScreen(initialPosition: initial)),
    );
    if (selected == null) return;

    _latController.text = formatCoordinate(selected.latitude);
    _lonController.text = formatCoordinate(selected.longitude);
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please pick an image before creating the landmark')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final resizedImage = await _resizeImage(_imageFile!);
      await widget.onCreate(
        title: _titleController.text.trim(),
        lat: double.parse(_latController.text.trim()),
        lon: double.parse(_lonController.text.trim()),
        imageFile: resizedImage,
      );
      if (!mounted) return;
      _formKey.currentState?.reset();
      _titleController.clear();
      _latController.clear();
      _lonController.clear();
      setState(() => _imageFile = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Landmark created successfully')),
      );
      _didAutoFetchLocation = false;
      _maybeAutoFetchLocation();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Create failed: $error')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<File> _resizeImage(File originalFile) async {
    try {
      final bytes = await originalFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return originalFile;

      final resized = img.copyResize(decoded, width: 900);
      final tempDir = await getTemporaryDirectory();
      final resizedPath = path.join(tempDir.path,
          'landmark_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final resizedFile = File(resizedPath);
      await resizedFile.writeAsBytes(img.encodeJpg(resized, quality: 85));
      return resizedFile;
    } catch (_) {
      return originalFile;
    }
  }

  String? _validateLatitude(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Required';
    if (parsed < -90 || parsed > 90) return 'Invalid latitude';
    return null;
  }

  String? _validateLongitude(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null) return 'Required';
    if (parsed < -180 || parsed > 180) return 'Invalid longitude';
    return null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }
}
