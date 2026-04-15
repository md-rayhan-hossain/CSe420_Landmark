import 'package:intl/intl.dart';

final _dateFormat = DateFormat('MMM d, yyyy h:mm a');

String formatScore(double score) {
  if (score.abs() >= 1000) return score.toStringAsFixed(0);
  return score.toStringAsFixed(score.truncateToDouble() == score ? 0 : 1);
}

String formatDistance(double? meters) {
  if (meters == null) return 'Waiting for sync';
  if (meters.abs() >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
  return '${meters.toStringAsFixed(1)} m';
}

String formatCoordinate(double value) {
  return value.toStringAsFixed(6);
}

String formatDateTime(DateTime value) {
  return _dateFormat.format(value.toLocal());
}
