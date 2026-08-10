import '../../../model/activity_watch_enrollment.dart';

final class ActivityWatchDailyActiveMetric {
  const ActivityWatchDailyActiveMetric({
    required this.date,
    required this.activeSeconds,
  });

  final DateTime date;
  final int activeSeconds;
}

final class ActivityWatchDashboardMetrics {
  const ActivityWatchDashboardMetrics({
    required this.activeSeconds,
    required this.idleSeconds,
    required this.inputSeconds,
    required this.browserSeconds,
    required this.lockedSeconds,
    required this.offlineSeconds,
    required this.unknownSeconds,
    required this.trackedSeconds,
    required this.deviceCount,
    required this.applicationCount,
    required this.dailyActive,
  });

  final int activeSeconds;
  final int idleSeconds;
  final int inputSeconds;
  final int browserSeconds;
  final int lockedSeconds;
  final int offlineSeconds;
  final int unknownSeconds;
  final int trackedSeconds;
  final int deviceCount;
  final int applicationCount;
  final List<ActivityWatchDailyActiveMetric> dailyActive;

  factory ActivityWatchDashboardMetrics.fromSummaries(
    Iterable<ActivityWatchSummary> summaries,
  ) {
    var activeSeconds = 0;
    var idleSeconds = 0;
    var inputSeconds = 0;
    var browserSeconds = 0;
    var lockedSeconds = 0;
    var offlineSeconds = 0;
    var unknownSeconds = 0;
    var trackedSeconds = 0;
    final deviceIds = <String>{};
    final applicationNames = <String>{};
    final activeByDate = <DateTime, int>{};

    for (final summary in summaries) {
      activeSeconds += summary.activeSeconds;
      idleSeconds += summary.idleSeconds;
      inputSeconds += summary.inputSeconds;
      browserSeconds += summary.browserSeconds;
      lockedSeconds += summary.lockedSeconds;
      offlineSeconds += summary.offlineSeconds;
      unknownSeconds += summary.unknownSeconds;
      trackedSeconds += summary.trackedSeconds;

      final deviceId = summary.deviceId.trim();
      if (deviceId.isNotEmpty) deviceIds.add(deviceId);

      for (final application in summary.applications) {
        final name = application.name.trim().toLowerCase();
        if (name.isNotEmpty) applicationNames.add(name);
      }

      final date = DateTime(
        summary.workDate.year,
        summary.workDate.month,
        summary.workDate.day,
      );
      activeByDate.update(
        date,
        (seconds) => seconds + summary.activeSeconds,
        ifAbsent: () => summary.activeSeconds,
      );
    }

    final dailyActive =
        activeByDate.entries
            .map(
              (entry) => ActivityWatchDailyActiveMetric(
                date: entry.key,
                activeSeconds: entry.value,
              ),
            )
            .toList(growable: false)
          ..sort((left, right) => left.date.compareTo(right.date));

    return ActivityWatchDashboardMetrics(
      activeSeconds: activeSeconds,
      idleSeconds: idleSeconds,
      inputSeconds: inputSeconds,
      browserSeconds: browserSeconds,
      lockedSeconds: lockedSeconds,
      offlineSeconds: offlineSeconds,
      unknownSeconds: unknownSeconds,
      trackedSeconds: trackedSeconds,
      deviceCount: deviceIds.length,
      applicationCount: applicationNames.length,
      dailyActive: List<ActivityWatchDailyActiveMetric>.unmodifiable(
        dailyActive,
      ),
    );
  }
}
