import 'package:billing/controller/sales/sales_proforma_invoice_management_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quotation prefill keeps source identity and commercial values', () {
    final draft = ProformaInvoiceLineDraft.fromQuotationPrefill({
      'id': 41,
      'item_id': 7,
      'uom_id': 3,
      'tax_code_id': 5,
      'description': 'Control panel',
      'qty': '2.000000',
      'rate': '1250.0000',
      'discount_percent': '10.0000',
      'discount_mode': 'percent',
      'remarks': 'Quotation line',
    });

    expect(draft.id, isNull);
    expect(draft.salesQuotationLineId, 41);
    expect(draft.itemId, 7);
    expect(draft.uomId, 3);
    expect(draft.taxCodeId, 5);
    expect(draft.qtyController.text, '2.000000');
    expect(draft.rateController.text, '1250.0000');
    expect(draft.discountController.text, '10.0000');

    draft.dispose();
  });

  test('quotation prefill accepts the explicit source line field', () {
    final draft = ProformaInvoiceLineDraft.fromQuotationPrefill({
      'id': 999,
      'sales_quotation_line_id': 52,
      'item_id': 8,
      'uom_id': 4,
      'qty': 1,
      'rate': 500,
    });

    expect(draft.id, isNull);
    expect(draft.salesQuotationLineId, 52);

    draft.dispose();
  });
}
