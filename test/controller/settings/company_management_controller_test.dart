import 'package:billing/controller/settings/master/company_management_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('company timezone defaults to Asia/Kolkata and exposes it as an option', () {
    final controller = CompanyManagementController(initialTabIndex: 0);

    expect(controller.timezone, 'Asia/Kolkata');
    expect(
      controller.availableTimezoneItems.any(
        (item) => item.value == 'Asia/Kolkata',
      ),
      isTrue,
    );
  });

  test('company timezone preserves a stored timezone outside the curated list', () {
    final controller = CompanyManagementController(initialTabIndex: 0);

    controller.setTimezone('Antarctica/Troll');

    expect(controller.timezone, 'Antarctica/Troll');
    expect(
      controller.availableTimezoneItems.any(
        (item) => item.value == 'Antarctica/Troll',
      ),
      isTrue,
    );
  });
}
