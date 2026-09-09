import 'package:billing/helper/document_terms_defaults.dart';
import 'package:billing/helper/master_data_cache.dart';
import 'package:billing/model/masters/document_term_setting_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    MasterDataCache.ensureRegistered();
  });

  tearDown(Get.reset);

  test('uses the cached company-context terms by document type', () {
    MasterDataCache.to.replaceDocumentTerm(
      const DocumentTermSettingModel(
        id: 10,
        companyId: 3,
        documentType: 'sales_invoice',
        documentLabel: 'Sales Invoice',
        termsConditions: 'Company invoice terms',
        isCompanyOverride: true,
      ),
      notify: false,
    );

    expect(documentTermsDefault('sales_invoice'), 'Company invoice terms');
    expect(documentTermsDefault('purchase_invoice'), isEmpty);
  });

  test('preserves an explicitly blank cached override', () {
    MasterDataCache.to.replaceDocumentTerm(
      const DocumentTermSettingModel(
        id: 11,
        companyId: 3,
        documentType: 'purchase_order',
        documentLabel: 'Purchase Order',
        termsConditions: '',
        isCompanyOverride: true,
      ),
      notify: false,
    );

    expect(documentTermsDefault('purchase_order'), isEmpty);
    expect(
      documentTermsOrDefault('Document-specific terms', 'purchase_order'),
      'Document-specific terms',
    );
  });

  test('does not apply inactive cached terms', () {
    MasterDataCache.to.replaceDocumentTerm(
      const DocumentTermSettingModel(
        id: 12,
        companyId: 3,
        documentType: 'sales_invoice',
        documentLabel: 'Sales Invoice',
        termsConditions: 'Inactive terms',
        isActive: false,
        isCompanyOverride: true,
      ),
      notify: false,
    );
    expect(documentTermsDefault('sales_invoice'), isEmpty);
  });

  test('parses the typed API response', () {
    final setting = DocumentTermSettingModel.fromJson({
      'id': 12,
      'company_id': 4,
      'document_type': 'sales_quotation',
      'document_label': 'Sales Quotation',
      'terms_conditions': 'Quotation terms',
      'is_active': 1,
      'is_company_override': 1,
    });

    expect(setting.documentLabel, 'Sales Quotation');
    expect(setting.termsConditions, 'Quotation terms');
    expect(setting.isActive, isTrue);
    expect(setting.isCompanyOverride, isTrue);
  });
}
