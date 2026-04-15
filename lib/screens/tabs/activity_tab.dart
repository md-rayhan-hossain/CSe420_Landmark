import 'package:flutter/material.dart';
import 'package:geo_entities_app/models/visit_record.dart';
import 'package:geo_entities_app/utils/formatters.dart';
import 'package:geo_entities_app/widgets/empty_state.dart';

class ActivityTab extends StatelessWidget {
  final List<VisitRecord> visits;
  final bool isSyncing;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onSync;

  const ActivityTab({
    super.key,
    required this.visits,
    required this.isSyncing,
    required this.onRefresh,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Recent landmark visits and offline sync status.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  isSyncing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: 'Sync queued visits',
                          onPressed: onSync,
                          icon: const Icon(Icons.sync),
                        ),
                ],
              ),
            ),
          ),
          if (visits.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.history_outlined,
                title: 'No visits yet',
                message:
                    'Visit a landmark from the map or list to start activity history.',
                actionLabel: 'Sync now',
                onAction: onSync,
              ),
            )
          else
            SliverList.builder(
              itemCount: visits.length,
              itemBuilder: (context, index) => _VisitTile(visit: visits[index]),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _VisitTile extends StatelessWidget {
  final VisitRecord visit;

  const _VisitTile({required this.visit});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (visit.status) {
      VisitStatus.synced => const Color(0xFF15803D),
      VisitStatus.failed => const Color(0xFFB45309),
      _ => const Color(0xFF0F766E),
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(
            visit.isSynced ? Icons.check : Icons.schedule,
            color: statusColor,
          ),
        ),
        title: Text(visit.landmarkTitle),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatDateTime(visit.visitedAt)),
              Text('Distance: ${formatDistance(visit.distanceMeters)}'),
              Text(
                  'GPS: ${formatCoordinate(visit.userLat)}, ${formatCoordinate(visit.userLon)}'),
              if (visit.errorMessage != null && visit.errorMessage!.isNotEmpty)
                Text(
                  visit.errorMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFB45309)),
                ),
            ],
          ),
        ),
        trailing: _StatusPill(status: visit.status, color: statusColor),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusPill({
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
