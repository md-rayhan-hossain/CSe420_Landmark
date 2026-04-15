import 'package:flutter/material.dart';
import 'package:geo_entities_app/utils/formatters.dart';

class ScoreBadge extends StatelessWidget {
  final double score;

  const ScoreBadge({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        'Score ${formatScore(score)}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

Color _scoreColor(double score) {
  if (score >= 20) return const Color(0xFF15803D);
  if (score >= 1) return const Color(0xFF0F766E);
  if (score >= -1000) return const Color(0xFFB45309);
  return const Color(0xFFB91C1C);
}
