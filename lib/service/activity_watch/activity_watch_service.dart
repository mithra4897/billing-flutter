import '../../core/api/api_client.dart';
import '../../model/activity_watch_enrollment.dart';

final class ActivityWatchService {
  ActivityWatchService({ApiClient? apiClient})
    : _client = apiClient ?? ApiClient();

  final ApiClient _client;

  Future<ActivityWatchEnrollment> enroll({
    required String deviceLabel,
    required String platform,
    required int consentVersion,
  }) async {
    final response = await _client.post<ActivityWatchEnrollment>(
      '/activity-watch/enroll',
      body: <String, dynamic>{
        'consent_accepted': true,
        'consent_version': consentVersion,
        'device_label': deviceLabel.trim(),
        'platform': platform,
      },
      fromData: (json) =>
          ActivityWatchEnrollment.fromJson(json as Map<String, dynamic>),
    );
    final enrollment = response.data;
    if (enrollment == null ||
        enrollment.deviceId.isEmpty ||
        enrollment.credential.isEmpty) {
      throw StateError(
        'Activity Watch enrollment returned invalid credentials.',
      );
    }
    return enrollment;
  }
}
