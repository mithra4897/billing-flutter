import 'common/json_model.dart';

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
      retentionDays: JsonModel.intOf(json['retention_days'], fallback: 90),
    );
  }
}

final class ActivityWatchPairingSession {
  const ActivityWatchPairingSession({
    required this.deviceId,
    required this.pairingToken,
    required this.pairingUrl,
    required this.expiresAt,
    this.installerUrl,
  });

  final String deviceId;
  final String pairingToken;
  final String pairingUrl;
  final DateTime expiresAt;
  final String? installerUrl;

  factory ActivityWatchPairingSession.fromJson(Map<String, dynamic> json) {
    return ActivityWatchPairingSession(
      deviceId: json['device_id']?.toString() ?? '',
      pairingToken: json['pairing_token']?.toString() ?? '',
      pairingUrl: json['pairing_url']?.toString() ?? '',
      expiresAt:
          DateTime.tryParse(json['expires_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      installerUrl: json['installer_url']?.toString(),
    );
  }

  Map<String, dynamic> toBundleJson({required String platform}) =>
      <String, dynamic>{
        'version': 1,
        'pairing_url': pairingUrl,
        'pairing_token': pairingToken,
        'platform': platform,
      };
}

final class ActivityWatchDevice {
  const ActivityWatchDevice({
    required this.id,
    required this.label,
    required this.platform,
    required this.consentedAt,
    this.lastSeenAt,
    this.revokedAt,
    this.pairingExpiresAt,
    this.pairedAt,
  });

  final String id;
  final String label;
  final String platform;
  final DateTime consentedAt;
  final DateTime? lastSeenAt;
  final DateTime? revokedAt;
  final DateTime? pairingExpiresAt;
  final DateTime? pairedAt;

  bool get isActive => revokedAt == null;
  bool get isPaired => pairedAt != null || lastSeenAt != null;
  bool get isPairingExpired =>
      !isPaired &&
      pairingExpiresAt != null &&
      pairingExpiresAt!.isBefore(DateTime.now());

  String get connectionStatus {
    if (!isActive) return 'Revoked';
    if (isPaired) return 'Connected';
    if (isPairingExpired) return 'Pairing expired';
    return 'Waiting for agent';
  }

  factory ActivityWatchDevice.fromJson(Map<String, dynamic> json) {
    return ActivityWatchDevice(
      id: json['id']?.toString() ?? '',
      label: json['device_label']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      consentedAt:
          DateTime.tryParse(json['consented_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lastSeenAt: DateTime.tryParse(json['last_seen_at']?.toString() ?? ''),
      revokedAt: DateTime.tryParse(json['revoked_at']?.toString() ?? ''),
      pairingExpiresAt: DateTime.tryParse(
        json['pairing_expires_at']?.toString() ?? '',
      ),
      pairedAt: DateTime.tryParse(json['paired_at']?.toString() ?? ''),
    );
  }

  @override
  String toString() => label.isEmpty ? id : label;
}

final class ActivityWatchApplicationTotal {
  const ActivityWatchApplicationTotal({
    required this.name,
    required this.classification,
    required this.seconds,
  });

  final String name;
  final String classification;
  final int seconds;

  factory ActivityWatchApplicationTotal.fromJson(Map<String, dynamic> json) {
    return ActivityWatchApplicationTotal(
      name: json['name']?.toString() ?? '',
      classification: json['classification']?.toString() ?? 'unclassified',
      seconds: JsonModel.intOf(json['seconds']),
    );
  }
}

final class ActivityWatchBrowserTitleTotal {
  const ActivityWatchBrowserTitleTotal({
    required this.title,
    required this.seconds,
  });
  final String title;
  final int seconds;

  factory ActivityWatchBrowserTitleTotal.fromJson(Map<String, dynamic> json) =>
      ActivityWatchBrowserTitleTotal(
        title: json['title']?.toString() ?? '',
        seconds: JsonModel.intOf(json['seconds']),
      );
}

final class ActivityWatchBackgroundApplication {
  const ActivityWatchBackgroundApplication({required this.name, this.state});
  final String name;
  final String? state;

  factory ActivityWatchBackgroundApplication.fromJson(
    Map<String, dynamic> json,
  ) => ActivityWatchBackgroundApplication(
    name: json['name']?.toString() ?? '',
    state: json['state']?.toString(),
  );
}

final class ActivityWatchSummary {
  const ActivityWatchSummary({
    required this.deviceId,
    required this.deviceLabel,
    required this.workDate,
    required this.activeSeconds,
    required this.idleSeconds,
    required this.lockedSeconds,
    required this.offlineSeconds,
    required this.unknownSeconds,
    required this.inputSeconds,
    required this.browserSeconds,
    required this.trackedSeconds,
    required this.applications,
    this.employeeId,
    this.employeeName,
    this.employeeCode,
    this.keyboardActiveSeconds = 0,
    this.keyboardIdleSeconds = 0,
    this.mouseActiveSeconds = 0,
    this.mouseIdleSeconds = 0,
    this.browserTitles = const <ActivityWatchBrowserTitleTotal>[],
    this.backgroundApplications = const <ActivityWatchBackgroundApplication>[],
  });

  final String deviceId;
  final String deviceLabel;
  final int? employeeId;
  final String? employeeName;
  final String? employeeCode;
  final DateTime workDate;
  final int activeSeconds;
  final int idleSeconds;
  final int lockedSeconds;
  final int offlineSeconds;
  final int unknownSeconds;
  final int inputSeconds;
  final int browserSeconds;
  final int trackedSeconds;
  final List<ActivityWatchApplicationTotal> applications;
  final int keyboardActiveSeconds;
  final int keyboardIdleSeconds;
  final int mouseActiveSeconds;
  final int mouseIdleSeconds;
  final List<ActivityWatchBrowserTitleTotal> browserTitles;
  final List<ActivityWatchBackgroundApplication> backgroundApplications;

  factory ActivityWatchSummary.fromJson(Map<String, dynamic> json) {
    final applications = json['applications'];
    final browserTitles = json['browser_titles'];
    final backgroundApplications = json['background_applications'];
    return ActivityWatchSummary(
      deviceId: json['device_id']?.toString() ?? '',
      deviceLabel: json['device_label']?.toString() ?? '',
      employeeId: JsonModel.nullableInt(json['employee_id']),
      employeeName: json['employee_name']?.toString(),
      employeeCode: json['employee_code']?.toString(),
      workDate:
          DateTime.tryParse(json['work_date_local']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      activeSeconds: JsonModel.intOf(json['active_seconds']),
      idleSeconds: JsonModel.intOf(json['idle_seconds']),
      lockedSeconds: JsonModel.intOf(json['locked_seconds']),
      offlineSeconds: JsonModel.intOf(json['offline_seconds']),
      unknownSeconds: JsonModel.intOf(json['unknown_seconds']),
      inputSeconds: JsonModel.intOf(json['input_seconds']),
      browserSeconds: JsonModel.intOf(json['browser_seconds']),
      keyboardActiveSeconds: JsonModel.intOf(json['keyboard_active_seconds']),
      keyboardIdleSeconds: JsonModel.intOf(json['keyboard_idle_seconds']),
      mouseActiveSeconds: JsonModel.intOf(json['mouse_active_seconds']),
      mouseIdleSeconds: JsonModel.intOf(json['mouse_idle_seconds']),
      trackedSeconds: JsonModel.intOf(json['tracked_seconds']),
      applications: applications is List
          ? applications
                .whereType<Map>()
                .map(
                  (item) => ActivityWatchApplicationTotal.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <ActivityWatchApplicationTotal>[],
      browserTitles: browserTitles is List
          ? browserTitles
                .whereType<Map>()
                .map(
                  (item) => ActivityWatchBrowserTitleTotal.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <ActivityWatchBrowserTitleTotal>[],
      backgroundApplications: backgroundApplications is List
          ? backgroundApplications
                .whereType<Map>()
                .map(
                  (item) => ActivityWatchBackgroundApplication.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <ActivityWatchBackgroundApplication>[],
    );
  }
}

final class ActivityWatchSummaryPage {
  const ActivityWatchSummaryPage({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.total,
  });

  final List<ActivityWatchSummary> items;
  final int page;
  final int lastPage;
  final int total;

  factory ActivityWatchSummaryPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final pagination = json['pagination'] is Map
        ? Map<String, dynamic>.from(json['pagination'] as Map)
        : const <String, dynamic>{};
    return ActivityWatchSummaryPage(
      items: items is List
          ? items
                .whereType<Map>()
                .map(
                  (item) => ActivityWatchSummary.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <ActivityWatchSummary>[],
      page: JsonModel.intOf(pagination['page'], fallback: 1),
      lastPage: JsonModel.intOf(pagination['last_page'], fallback: 1),
      total: JsonModel.intOf(pagination['total']),
    );
  }
}
