import 'package:flutter/material.dart';
import 'package:geo_entities_app/models/landmark.dart';
import 'package:geo_entities_app/utils/formatters.dart';
import 'package:geo_entities_app/widgets/landmark_image.dart';
import 'package:geo_entities_app/widgets/score_badge.dart';

class LandmarkSummaryCard extends StatelessWidget {
  final Landmark landmark;
  final VoidCallback? onVisit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

  const LandmarkSummaryCard({
    super.key,
    required this.landmark,
    this.onVisit,
    this.onDelete,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LandmarkImage(imagePath: landmark.image),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    landmark.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ScoreBadge(score: landmark.score),
                      _MetaChip(
                          icon: Icons.route_outlined,
                          label: formatDistance(landmark.avgDistance)),
                      _MetaChip(
                          icon: Icons.how_to_reg_outlined,
                          label: '${landmark.visitCount} visits'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatCoordinate(landmark.lat)}, ${formatCoordinate(landmark.lon)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black54),
                  ),
                  if (onVisit != null ||
                      onDelete != null ||
                      onRestore != null) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (onVisit != null)
                          FilledButton.icon(
                            onPressed: onVisit,
                            icon: const Icon(Icons.near_me_outlined),
                            label: const Text('Visit'),
                          ),
                        if (onRestore != null)
                          OutlinedButton.icon(
                            onPressed: onRestore,
                            icon: const Icon(Icons.restore_outlined),
                            label: const Text('Restore'),
                          ),
                        if (onDelete != null)
                          TextButton.icon(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
