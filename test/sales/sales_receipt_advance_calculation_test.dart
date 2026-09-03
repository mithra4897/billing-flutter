import 'package:billing/controller/sales/sales_receipt_management_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'received amount remains independent and only invoice rows reduce advance',
    (tester) async {
      final controller = SalesReceiptManagementController();
      addTearDown(controller.onClose);
      controller.paidAmountController.text = '10000';
      controller.allocations = <SalesReceiptAllocationDraft>[
        SalesReceiptAllocationDraft(
          salesInvoiceId: 10,
          allocatedAmount: '6000',
        ),
        SalesReceiptAllocationDraft(
          allocationType: 'on_account',
          allocatedAmount: '4000',
        ),
      ];

      controller.refreshAllocationTotals(notify: false);

      expect(controller.paidAmountController.text, '10000');
      expect(controller.totalAllocatedAmount(), 6000);
      expect(controller.displayedCustomerAdvance, 4000);
    },
  );
}
