import 'package:billing/controller/settings/master/document_term_settings_controller.dart';
import 'package:billing/model/masters/document_term_setting_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new terms only offers document types without a stored record', () {
    final controller = DocumentTermSettingsController();
    controller.initialLoading = false;
    controller.records = const <DocumentTermSettingModel>[
      DocumentTermSettingModel(
        id: 10,
        documentType: 'sales_invoice',
        documentLabel: 'Sales Invoice',
        termsConditions: 'Stored terms',
      ),
      DocumentTermSettingModel(
        documentType: 'purchase_order',
        documentLabel: 'Purchase Order',
        termsConditions: 'Global terms',
      ),
    ];

    expect(controller.documentTypeItems.map((item) => item.value), <String>[
      'purchase_order',
    ]);
    expect(controller.canCreate, isTrue);
  });

  test('active switch changes whether the terms apply automatically', () {
    final controller = DocumentTermSettingsController();

    controller.setIsActive(false);
    expect(controller.isActive, isFalse);

    controller.setIsActive(true);
    expect(controller.isActive, isTrue);
  });
}
