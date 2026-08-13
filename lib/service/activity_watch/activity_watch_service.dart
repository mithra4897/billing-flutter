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

  Future<ActivityWatchPairingSession> createPairingSession({
    required String deviceLabel,
    required String platform,
    required int consentVersion,
  }) async {
    final response = await _client.post<ActivityWatchPairingSession>(
      '/activity-watch/pairing-sessions',
      body: <String, dynamic>{
        'consent_accepted': true,
        'consent_version': consentVersion,
        'device_label': deviceLabel.trim(),
        'platform': platform,
      },
      fromData: (json) => ActivityWatchPairingSession.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
    final pairing = response.data;
    if (pairing == null ||
        pairing.deviceId.isEmpty ||
        pairing.pairingToken.length != 64 ||
        pairing.pairingUrl.isEmpty) {
      throw StateError('Activity Watch returned an invalid pairing session.');
    }
    return pairing;
  }

  Future<List<ActivityWatchDevice>> devices({
    bool companyScope = false,
    int? companyId,
  }) async {
    final response = await _client.get<List<ActivityWatchDevice>>(
      '/activity-watch/devices',
      queryParameters: _viewerScopeParameters(
        companyScope: companyScope,
        companyId: companyId,
      ),
      headerOverrides: companyScope ? _companyWideHeaderOverrides : null,
      fromData: (json) => json is List
          ? json
                .whereType<Map>()
                .map(
                  (item) => ActivityWatchDevice.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <ActivityWatchDevice>[],
    );
    return response.data ?? const <ActivityWatchDevice>[];
  }

  Future<ActivityWatchSummaryPage> summaries({
    required DateTime from,
    required DateTime to,
    int page = 1,
    int limit = 31,
    bool companyScope = false,
    int? companyId,
  }) async {
    final response = await _client.get<ActivityWatchSummaryPage>(
      '/activity-watch/summaries',
      queryParameters: <String, dynamic>{
        'from': _dateOnly(from),
        'to': _dateOnly(to),
        'page': page,
        'limit': limit,
        ..._viewerScopeParameters(
          companyScope: companyScope,
          companyId: companyId,
        ),
      },
      headerOverrides: companyScope ? _companyWideHeaderOverrides : null,
      fromData: (json) => ActivityWatchSummaryPage.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
    return response.data ??
        const ActivityWatchSummaryPage(
          items: <ActivityWatchSummary>[],
          page: 1,
          lastPage: 1,
          total: 0,
        );
  }

  Future<void> revoke(String deviceId) async {
    await _client.post<void>('/activity-watch/devices/$deviceId/revoke');
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _viewerScopeParameters({
    required bool companyScope,
    required int? companyId,
  }) => <String, dynamic>{
    if (companyScope) 'scope': 'company',
  };
  static const Map<String, String?> _companyWideHeaderOverrides =
      <String, String?>{
        'X-Company-Id': null,
        'X-Branch-Id': null,
        'X-Location-Id': null,
        'X-Financial-Year-Id': null,
      };
}
