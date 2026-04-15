import 'package:flutter/material.dart';
import 'package:geo_entities_app/models/landmark.dart';
import 'package:geo_entities_app/widgets/empty_state.dart';
import 'package:geo_entities_app/widgets/landmark_summary_card.dart';

enum LandmarkSortMode { scoreHigh, scoreLow, title }

class LandmarksTab extends StatefulWidget {
  final List<Landmark> landmarks;
  final bool isLoading;
  final bool fromCache;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Landmark landmark) onVisit;
  final Future<void> Function(Landmark landmark) onDelete;

  const LandmarksTab({
    super.key,
    required this.landmarks,
    required this.isLoading,
    required this.fromCache,
    required this.onRefresh,
    required this.onVisit,
    required this.onDelete,
  });

  @override
  State<LandmarksTab> createState() => _LandmarksTabState();
}

class _LandmarksTabState extends State<LandmarksTab> {
  final TextEditingController _minScoreController = TextEditingController();
  LandmarkSortMode _sortMode = LandmarkSortMode.scoreHigh;

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLandmarks();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(fromCache: widget.fromCache)),
          SliverToBoxAdapter(child: _buildControls()),
          if (widget.isLoading && widget.landmarks.isEmpty)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: 'No landmarks match',
                message: 'Clear the minimum score or refresh while online.',
                actionLabel: 'Refresh',
                onAction: widget.onRefresh,
              ),
            )
          else
            SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final landmark = filtered[index];
                return LandmarkSummaryCard(
                  landmark: landmark,
                  onVisit: () => widget.onVisit(landmark),
                  onDelete: () => widget.onDelete(landmark),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<LandmarkSortMode>(
            value: _sortMode,
            decoration: const InputDecoration(labelText: 'Sort landmarks'),
            items: const [
              DropdownMenuItem(
                  value: LandmarkSortMode.scoreHigh,
                  child: Text('Score: high to low')),
              DropdownMenuItem(
                  value: LandmarkSortMode.scoreLow,
                  child: Text('Score: low to high')),
              DropdownMenuItem(
                  value: LandmarkSortMode.title, child: Text('Title: A to Z')),
            ],
            onChanged: (value) =>
                setState(() => _sortMode = value ?? LandmarkSortMode.scoreHigh),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _minScoreController,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            decoration: InputDecoration(
              labelText: 'Minimum score filter',
              hintText: 'Example: 0',
              suffixIcon: _minScoreController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear score filter',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _minScoreController.clear();
                        setState(() {});
                      },
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  List<Landmark> _filteredLandmarks() {
    final minScore = double.tryParse(_minScoreController.text.trim());
    final filtered = widget.landmarks.where((landmark) {
      if (minScore == null) return true;
      return landmark.score >= minScore;
    }).toList();

    switch (_sortMode) {
      case LandmarkSortMode.scoreHigh:
        filtered.sort((a, b) => b.score.compareTo(a.score));
        break;
      case LandmarkSortMode.scoreLow:
        filtered.sort((a, b) => a.score.compareTo(b.score));
        break;
      case LandmarkSortMode.title:
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return filtered;
  }

  @override
  void dispose() {
    _minScoreController.dispose();
    super.dispose();
  }
}

class _Header extends StatelessWidget {
  final bool fromCache;

  const _Header({required this.fromCache});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
            fromCache
                ? 'Showing saved data due to being offline.'
                : 'Live landmarks.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
