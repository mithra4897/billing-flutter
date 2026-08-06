final class ActivityWatchEnrollment {
  const ActivityWatchEnrollment({
    required this.deviceId,
    required this.credential,
    required this.retentionDays,
  });

  final String deviceId;
  final String credential;
  final int retentionDays;

  factory ActivityWatchEnrollment.fromJson(Map<String, dynamic> json) {
    return ActivityWatchEnrollment(
      deviceId: json['device_id']?.toString() ?? '',
      credential: json['credential']?.toString() ?? '',
      retentionDays: (json['retention_days'] as num?)?.toInt() ?? 90,
    );
  }
}
