import 'package:billing/screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'restores a valid authenticated shell route with its query parameters',
    () async {
      await SessionStorage.saveLastShellRoute('/sales/invoices?status=draft');

      expect(
        await SessionStorage.getLastShellRoute(),
        '/sales/invoices?status=draft',
      );
    },
  );

  test(
    'does not save public or malformed routes as a shell destination',
    () async {
      await SessionStorage.saveLastShellRoute('/login?redirect=%2Fsales');
      await SessionStorage.saveLastShellRoute('https://example.com/sales');
      await SessionStorage.saveLastShellRoute('/not-a-real-page');

      expect(await SessionStorage.getLastShellRoute(), isNull);
    },
  );

  test('clearing a session also removes the saved shell route', () async {
    await SessionStorage.saveLastShellRoute('/inventory/items');
    await SessionStorage.clearSessionOnly();

    expect(await SessionStorage.getLastShellRoute(), isNull);
  });
}
