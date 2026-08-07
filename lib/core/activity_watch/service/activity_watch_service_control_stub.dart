final class ActivityWatchServiceControl {
  const ActivityWatchServiceControl._();

  static Future<void> configure({
    required String executablePath,
    required String configurationPath,
  }) async {
    throw UnsupportedError(
      'Activity Watch background services are unavailable on this platform.',
    );
  }

  static Future<void> clearConfiguration() async {}

  static Future<bool> applyEnrollment({
    required String deviceId,
    required String credential,
  }) async => false;

  static Future<void> signalLogoutIfConfigured() async {}
}
