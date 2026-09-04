import 'package:billing/core/models/pagination_meta.dart';
import 'package:billing/model/inventory/stock_movement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses stock movement quantity totals from pagination metadata', () {
    final meta = PaginationMeta.fromJson(const <String, dynamic>{
      'current_page': 2,
      'last_page': 3,
      'per_page': 50,
      'total': 125,
      'qty_in_total': '18.500000',
      'qty_out_total': 7,
      'net_qty_total': '11.5',
    });

    expect(meta.qtyInTotal, 18.5);
    expect(meta.qtyOutTotal, 7);
    expect(meta.netQtyTotal, 11.5);
  });

  test('parses resolved stock movement party details', () {
    final movement = StockMovementModel.fromJson(const <String, dynamic>{
      'id': 10,
      'reference_table': 'sales_invoice',
      'reference_id': 25,
      'customer_party_id': 4,
      'party_name': 'Example Customer',
      'party_role': 'customer',
      'qty_out': '2.000000',
    });

    expect(movement.customerPartyId, 4);
    expect(movement.supplierPartyId, isNull);
    expect(movement.partyName, 'Example Customer');
    expect(movement.partyRole, 'customer');
    expect(movement.qtyOut, 2);
    expect(movement.qty, 2);
  });
}
