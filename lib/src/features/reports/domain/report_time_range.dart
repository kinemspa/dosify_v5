class UtcTimeRange {
  const UtcTimeRange({
    required this.startInclusiveUtc,
    required this.endExclusiveUtc,
  });

  final DateTime startInclusiveUtc;
  final DateTime endExclusiveUtc;

  bool contains(DateTime dt) {
    final utc = dt.toUtc();
    return !utc.isBefore(startInclusiveUtc) && utc.isBefore(endExclusiveUtc);
  }
}

enum ReportTimeRangePreset {
  allTime,
  last7Days,
  last30Days,
  last90Days,
  last365Days,
}

class ReportTimeRange {
  const ReportTimeRange(this.preset);

  final ReportTimeRangePreset preset;

  String get label {
    return switch (preset) {
      ReportTimeRangePreset.allTime => 'All time',
      ReportTimeRangePreset.last7Days => 'Last 7 days',
      ReportTimeRangePreset.last30Days => 'Last 30 days',
      ReportTimeRangePreset.last90Days => 'Last 90 days',
      ReportTimeRangePreset.last365Days => 'Last 365 days',
    };
  }

  UtcTimeRange? toUtcTimeRange({DateTime? nowUtc}) {
    if (preset == ReportTimeRangePreset.allTime) return null;

    final end = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final duration = switch (preset) {
      ReportTimeRangePreset.allTime => Duration.zero,
      ReportTimeRangePreset.last7Days => const Duration(days: 7),
      ReportTimeRangePreset.last30Days => const Duration(days: 30),
      ReportTimeRangePreset.last90Days => const Duration(days: 90),
      ReportTimeRangePreset.last365Days => const Duration(days: 365),
    };

    final start = end.subtract(duration);
    return UtcTimeRange(startInclusiveUtc: start, endExclusiveUtc: end);
  }
}
