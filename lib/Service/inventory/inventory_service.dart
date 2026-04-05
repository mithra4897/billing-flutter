import '../base/erp_module_service.dart';

class InventoryService extends ErpModuleService {
  InventoryService({super.apiClient});

  Future itemCategories({Map<String, dynamic>? filters}) =>
      index('/inventory/item-categories', filters: filters);
  Future itemCategoriesDropdown({Map<String, dynamic>? filters}) =>
      list('/inventory/item-categories/dropdown', filters: filters);
  Future itemCategory(int id) => show('/inventory/item-categories/$id');
  Future createItemCategory(Map<String, dynamic> body) =>
      store('/inventory/item-categories', body);
  Future updateItemCategory(int id, Map<String, dynamic> body) =>
      update('/inventory/item-categories/$id', body);
  Future deleteItemCategory(int id) =>
      destroy('/inventory/item-categories/$id');

  Future brands({Map<String, dynamic>? filters}) =>
      index('/inventory/brands', filters: filters);
  Future brandsDropdown({Map<String, dynamic>? filters}) =>
      list('/inventory/brands/dropdown', filters: filters);
  Future brand(int id) => show('/inventory/brands/$id');
  Future createBrand(Map<String, dynamic> body) =>
      store('/inventory/brands', body);
  Future updateBrand(int id, Map<String, dynamic> body) =>
      update('/inventory/brands/$id', body);
  Future deleteBrand(int id) => destroy('/inventory/brands/$id');

  Future uoms({Map<String, dynamic>? filters}) =>
      index('/inventory/uoms', filters: filters);
  Future uomsDropdown({Map<String, dynamic>? filters}) =>
      list('/inventory/uoms/dropdown', filters: filters);
  Future uom(int id) => show('/inventory/uoms/$id');
  Future createUom(Map<String, dynamic> body) => store('/inventory/uoms', body);
  Future updateUom(int id, Map<String, dynamic> body) =>
      update('/inventory/uoms/$id', body);
  Future deleteUom(int id) => destroy('/inventory/uoms/$id');

  Future uomConversions({Map<String, dynamic>? filters}) =>
      index('/inventory/uom-conversions', filters: filters);
  Future uomConversionsAll({Map<String, dynamic>? filters}) =>
      list('/inventory/uom-conversions/all', filters: filters);
  Future uomConversionFactor({Map<String, dynamic>? filters}) =>
      show('/inventory/uom-conversions/factor');
  Future uomConversion(int id) => show('/inventory/uom-conversions/$id');
  Future createUomConversion(Map<String, dynamic> body) =>
      store('/inventory/uom-conversions', body);
  Future updateUomConversion(int id, Map<String, dynamic> body) =>
      update('/inventory/uom-conversions/$id', body);
  Future deleteUomConversion(int id) =>
      destroy('/inventory/uom-conversions/$id');

  Future taxCodes({Map<String, dynamic>? filters}) =>
      index('/inventory/tax-codes', filters: filters);
  Future taxCodesDropdown({Map<String, dynamic>? filters}) =>
      list('/inventory/tax-codes/dropdown', filters: filters);
  Future taxCode(int id) => show('/inventory/tax-codes/$id');
  Future createTaxCode(Map<String, dynamic> body) =>
      store('/inventory/tax-codes', body);
  Future updateTaxCode(int id, Map<String, dynamic> body) =>
      update('/inventory/tax-codes/$id', body);
  Future deleteTaxCode(int id) => destroy('/inventory/tax-codes/$id');

  Future items({Map<String, dynamic>? filters}) =>
      index('/inventory/items', filters: filters);
  Future itemsDropdown({Map<String, dynamic>? filters}) =>
      list('/inventory/items/dropdown', filters: filters);
  Future item(int id) => show('/inventory/items/$id');
  Future createItem(Map<String, dynamic> body) =>
      store('/inventory/items', body);
  Future updateItem(int id, Map<String, dynamic> body) =>
      update('/inventory/items/$id', body);
  Future deleteItem(int id) => destroy('/inventory/items/$id');

  Future itemSupplierMaps({Map<String, dynamic>? filters}) =>
      index('/inventory/item-supplier-maps', filters: filters);
  Future itemSupplierMapsDropdown({Map<String, dynamic>? filters}) =>
      list('/inventory/item-supplier-maps/dropdown', filters: filters);
  Future itemSupplierMap(int id) => show('/inventory/item-supplier-maps/$id');
  Future createItemSupplierMap(Map<String, dynamic> body) =>
      store('/inventory/item-supplier-maps', body);
  Future updateItemSupplierMap(int id, Map<String, dynamic> body) =>
      update('/inventory/item-supplier-maps/$id', body);
  Future deleteItemSupplierMap(int id) =>
      destroy('/inventory/item-supplier-maps/$id');

  Future itemAlternates({Map<String, dynamic>? filters}) =>
      index('/inventory/item-alternates', filters: filters);
  Future itemAlternatesDropdown({Map<String, dynamic>? filters}) =>
      list('/inventory/item-alternates/dropdown', filters: filters);
  Future itemAlternate(int id) => show('/inventory/item-alternates/$id');
  Future createItemAlternate(Map<String, dynamic> body) =>
      store('/inventory/item-alternates', body);
  Future updateItemAlternate(int id, Map<String, dynamic> body) =>
      update('/inventory/item-alternates/$id', body);
  Future deleteItemAlternate(int id) =>
      destroy('/inventory/item-alternates/$id');

  Future itemPrices({Map<String, dynamic>? filters}) =>
      index('/inventory/item-prices', filters: filters);
  Future itemPricesDropdown({Map<String, dynamic>? filters}) =>
      list('/inventory/item-prices/dropdown', filters: filters);
  Future itemPrice(int id) => show('/inventory/item-prices/$id');
  Future createItemPrice(Map<String, dynamic> body) =>
      store('/inventory/item-prices', body);
  Future updateItemPrice(int id, Map<String, dynamic> body) =>
      update('/inventory/item-prices/$id', body);
  Future deleteItemPrice(int id) => destroy('/inventory/item-prices/$id');

  Future stockBatches({Map<String, dynamic>? filters}) =>
      index('/inventory/stock-batches', filters: filters);
  Future stockBatchesDropdown({Map<String, dynamic>? filters}) =>
      list('/inventory/stock-batches/dropdown', filters: filters);
  Future stockBatch(int id) => show('/inventory/stock-batches/$id');
  Future createStockBatch(Map<String, dynamic> body) =>
      store('/inventory/stock-batches', body);
  Future updateStockBatch(int id, Map<String, dynamic> body) =>
      update('/inventory/stock-batches/$id', body);
  Future deleteStockBatch(int id) => destroy('/inventory/stock-batches/$id');

  Future stockSerials({Map<String, dynamic>? filters}) =>
      index('/inventory/stock-serials', filters: filters);
  Future stockSerialsDropdown({Map<String, dynamic>? filters}) =>
      list('/inventory/stock-serials/dropdown', filters: filters);
  Future stockSerial(int id) => show('/inventory/stock-serials/$id');
  Future createStockSerial(Map<String, dynamic> body) =>
      store('/inventory/stock-serials', body);
  Future updateStockSerial(int id, Map<String, dynamic> body) =>
      update('/inventory/stock-serials/$id', body);
  Future deleteStockSerial(int id) => destroy('/inventory/stock-serials/$id');

  Future stockMovements({Map<String, dynamic>? filters}) =>
      index('/inventory/stock-movements', filters: filters);
  Future stockMovementsDropdown({Map<String, dynamic>? filters}) =>
      list('/inventory/stock-movements/dropdown', filters: filters);
  Future stockMovement(int id) => show('/inventory/stock-movements/$id');
  Future createStockMovement(Map<String, dynamic> body) =>
      store('/inventory/stock-movements', body);
  Future updateStockMovement(int id, Map<String, dynamic> body) =>
      update('/inventory/stock-movements/$id', body);
  Future deleteStockMovement(int id) =>
      destroy('/inventory/stock-movements/$id');

  Future stockBalances({Map<String, dynamic>? filters}) =>
      index('/inventory/stock-balances', filters: filters);
  Future stockBalancesDropdown({Map<String, dynamic>? filters}) =>
      list('/inventory/stock-balances/dropdown', filters: filters);
  Future stockBalance(int id) => show('/inventory/stock-balances/$id');
  Future createStockBalance(Map<String, dynamic> body) =>
      store('/inventory/stock-balances', body);
  Future updateStockBalance(int id, Map<String, dynamic> body) =>
      update('/inventory/stock-balances/$id', body);
  Future deleteStockBalance(int id) => destroy('/inventory/stock-balances/$id');

  Future inventoryAdjustments({Map<String, dynamic>? filters}) =>
      index('/inventory/inventory-adjustments', filters: filters);
  Future inventoryAdjustment(int id) =>
      show('/inventory/inventory-adjustments/$id');
  Future createInventoryAdjustment(Map<String, dynamic> body) =>
      store('/inventory/inventory-adjustments', body);
  Future updateInventoryAdjustment(int id, Map<String, dynamic> body) =>
      update('/inventory/inventory-adjustments/$id', body);
  Future postInventoryAdjustment(int id, Map<String, dynamic> body) =>
      action('/inventory/inventory-adjustments/$id/post', body: body);
  Future cancelInventoryAdjustment(int id, Map<String, dynamic> body) =>
      action('/inventory/inventory-adjustments/$id/cancel', body: body);
  Future deleteInventoryAdjustment(int id) =>
      destroy('/inventory/inventory-adjustments/$id');

  Future openingStocks({Map<String, dynamic>? filters}) =>
      index('/inventory/opening-stocks', filters: filters);
  Future openingStock(int id) => show('/inventory/opening-stocks/$id');
  Future createOpeningStock(Map<String, dynamic> body) =>
      store('/inventory/opening-stocks', body);
  Future updateOpeningStock(int id, Map<String, dynamic> body) =>
      update('/inventory/opening-stocks/$id', body);
  Future postOpeningStock(int id, Map<String, dynamic> body) =>
      action('/inventory/opening-stocks/$id/post', body: body);
  Future cancelOpeningStock(int id, Map<String, dynamic> body) =>
      action('/inventory/opening-stocks/$id/cancel', body: body);
  Future deleteOpeningStock(int id) => destroy('/inventory/opening-stocks/$id');

  Future stockTransfers({Map<String, dynamic>? filters}) =>
      index('/inventory/stock-transfers', filters: filters);
  Future stockTransfer(int id) => show('/inventory/stock-transfers/$id');
  Future createStockTransfer(Map<String, dynamic> body) =>
      store('/inventory/stock-transfers', body);
  Future updateStockTransfer(int id, Map<String, dynamic> body) =>
      update('/inventory/stock-transfers/$id', body);
  Future postStockTransfer(int id, Map<String, dynamic> body) =>
      action('/inventory/stock-transfers/$id/post', body: body);
  Future cancelStockTransfer(int id, Map<String, dynamic> body) =>
      action('/inventory/stock-transfers/$id/cancel', body: body);
  Future deleteStockTransfer(int id) =>
      destroy('/inventory/stock-transfers/$id');

  Future stockIssues({Map<String, dynamic>? filters}) =>
      index('/inventory/stock-issues', filters: filters);
  Future stockIssue(int id) => show('/inventory/stock-issues/$id');
  Future createStockIssue(Map<String, dynamic> body) =>
      store('/inventory/stock-issues', body);
  Future updateStockIssue(int id, Map<String, dynamic> body) =>
      update('/inventory/stock-issues/$id', body);
  Future postStockIssue(int id, Map<String, dynamic> body) =>
      action('/inventory/stock-issues/$id/post', body: body);
  Future cancelStockIssue(int id, Map<String, dynamic> body) =>
      action('/inventory/stock-issues/$id/cancel', body: body);
  Future deleteStockIssue(int id) => destroy('/inventory/stock-issues/$id');

  Future internalStockReceipts({Map<String, dynamic>? filters}) =>
      index('/inventory/internal-stock-receipts', filters: filters);
  Future internalStockReceipt(int id) =>
      show('/inventory/internal-stock-receipts/$id');
  Future createInternalStockReceipt(Map<String, dynamic> body) =>
      store('/inventory/internal-stock-receipts', body);
  Future updateInternalStockReceipt(int id, Map<String, dynamic> body) =>
      update('/inventory/internal-stock-receipts/$id', body);
  Future postInternalStockReceipt(int id, Map<String, dynamic> body) =>
      action('/inventory/internal-stock-receipts/$id/post', body: body);
  Future cancelInternalStockReceipt(int id, Map<String, dynamic> body) =>
      action('/inventory/internal-stock-receipts/$id/cancel', body: body);
  Future deleteInternalStockReceipt(int id) =>
      destroy('/inventory/internal-stock-receipts/$id');

  Future stockDamageEntries({Map<String, dynamic>? filters}) =>
      index('/inventory/stock-damage-entries', filters: filters);
  Future stockDamageEntry(int id) =>
      show('/inventory/stock-damage-entries/$id');
  Future createStockDamageEntry(Map<String, dynamic> body) =>
      store('/inventory/stock-damage-entries', body);
  Future updateStockDamageEntry(int id, Map<String, dynamic> body) =>
      update('/inventory/stock-damage-entries/$id', body);
  Future postStockDamageEntry(int id, Map<String, dynamic> body) =>
      action('/inventory/stock-damage-entries/$id/post', body: body);
  Future cancelStockDamageEntry(int id, Map<String, dynamic> body) =>
      action('/inventory/stock-damage-entries/$id/cancel', body: body);
  Future deleteStockDamageEntry(int id) =>
      destroy('/inventory/stock-damage-entries/$id');

  Future physicalStockCounts({Map<String, dynamic>? filters}) =>
      index('/inventory/physical-stock-counts', filters: filters);
  Future physicalStockCount(int id) =>
      show('/inventory/physical-stock-counts/$id');
  Future createPhysicalStockCount(Map<String, dynamic> body) =>
      store('/inventory/physical-stock-counts', body);
  Future updatePhysicalStockCount(int id, Map<String, dynamic> body) =>
      update('/inventory/physical-stock-counts/$id', body);
  Future markPhysicalCounted(int id, Map<String, dynamic> body) =>
      action('/inventory/physical-stock-counts/$id/counted', body: body);
  Future reconcilePhysicalStockCount(int id, Map<String, dynamic> body) =>
      action('/inventory/physical-stock-counts/$id/reconcile', body: body);
  Future cancelPhysicalStockCount(int id, Map<String, dynamic> body) =>
      action('/inventory/physical-stock-counts/$id/cancel', body: body);
  Future deletePhysicalStockCount(int id) =>
      destroy('/inventory/physical-stock-counts/$id');

  Future stockSummary({Map<String, dynamic>? filters}) =>
      index('/inventory/inquiry/stock-summary', filters: filters);
  Future warehouseWiseStock({Map<String, dynamic>? filters}) =>
      index('/inventory/inquiry/warehouse-wise-stock', filters: filters);
  Future batchWiseStock({Map<String, dynamic>? filters}) =>
      index('/inventory/inquiry/batch-wise-stock', filters: filters);
  Future availableSerials({Map<String, dynamic>? filters}) =>
      index('/inventory/inquiry/available-serials', filters: filters);
  Future stockCard({Map<String, dynamic>? filters}) =>
      index('/inventory/inquiry/stock-card', filters: filters);
  Future reorderStatus({Map<String, dynamic>? filters}) =>
      index('/inventory/inquiry/reorder-status', filters: filters);
}
