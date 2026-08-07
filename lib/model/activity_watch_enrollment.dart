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
      seconds: (json['seconds'] as num?)?.toInt() ?? 0,
    );
  }
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
  });

  final String deviceId;
  final String deviceLabel;
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

  factory ActivityWatchSummary.fromJson(Map<String, dynamic> json) {
    final applications = json['applications'];
    return ActivityWatchSummary(
      deviceId: json['device_id']?.toString() ?? '',
      deviceLabel: json['device_label']?.toString() ?? '',
      workDate:
          DateTime.tryParse(json['work_date_local']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      activeSeconds: (json['active_seconds'] as num?)?.toInt() ?? 0,
      idleSeconds: (json['idle_seconds'] as num?)?.toInt() ?? 0,
      lockedSeconds: (json['locked_seconds'] as num?)?.toInt() ?? 0,
      offlineSeconds: (json['offline_seconds'] as num?)?.toInt() ?? 0,
      unknownSeconds: (json['unknown_seconds'] as num?)?.toInt() ?? 0,
      inputSeconds: (json['input_seconds'] as num?)?.toInt() ?? 0,
      browserSeconds: (json['browser_seconds'] as num?)?.toInt() ?? 0,
      trackedSeconds: (json['tracked_seconds'] as num?)?.toInt() ?? 0,
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
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      lastPage: (pagination['last_page'] as num?)?.toInt() ?? 1,
      total: (pagination['total'] as num?)?.toInt() ?? 0,
    );
  }
}
