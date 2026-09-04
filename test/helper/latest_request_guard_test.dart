import 'package:billing/helper/latest_request_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LatestRequestGuard', () {
    test('only the newest request remains current', () {
      final guard = LatestRequestGuard();
      final first = guard.begin();
      final second = guard.begin();

      expect(guard.isCurrent(first), isFalse);
      expect(guard.isCurrent(second), isTrue);
    });

    test('invalidate makes an in-flight request stale', () {
      final guard = LatestRequestGuard();
      final request = guard.begin();

      guard.invalidate();

      expect(guard.isCurrent(request), isFalse);
    });
  });
}
