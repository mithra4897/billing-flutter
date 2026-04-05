import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/common/erp_report_row_model.dart';
import '../../model/inventory/internal_stock_receipt_model.dart';
import '../../model/inventory/inventory_adjustment_model.dart';
import '../../model/inventory/item_alternate_model.dart';
import '../../model/inventory/item_price_model.dart';
import '../../model/inventory/item_supplier_map_model.dart';
import '../../model/inventory/opening_stock_model.dart';
import '../../model/inventory/physical_stock_count_model.dart';
import '../../model/inventory/stock_balance_model.dart';
import '../../model/inventory/stock_batch_model.dart';
import '../../model/inventory/stock_damage_entry_model.dart';
import '../../model/inventory/stock_issue_model.dart';
import '../../model/inventory/stock_movement_model.dart';
import '../../model/inventory/stock_serial_model.dart';
import '../../model/inventory/stock_transfer_model.dart';
import '../../model/inventory/uom_conversion_model.dart';
import '../../model/masters/brand_model.dart';
import '../../model/masters/item_category_model.dart';
import '../../model/masters/item_model.dart';
import '../../model/masters/tax_code_model.dart';
import '../../model/masters/uom_model.dart';
import '../base/erp_module_service.dart';

class InventoryService extends ErpModuleService {
  InventoryService({super.apiClient});

  Future<PaginatedResponse<ItemCategoryModel>> itemCategories({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/inventory/item-categories',
    filters: filters,
    fromJson: ItemCategoryModel.fromJson,
  );
  Future<ApiResponse<List<ItemCategoryModel>>> itemCategoriesDropdown({
    Map<String, dynamic>? filters,
  }) => collection(
    '/inventory/item-categories/dropdown',
    filters: filters,
    fromJson: ItemCategoryModel.fromJson,
  );
  Future<ApiResponse<ItemCategoryModel>> itemCategory(int id) => object(
    '/inventory/item-categories/$id',
    fromJson: ItemCategoryModel.fromJson,
  );
  Future<ApiResponse<ItemCategoryModel>> createItemCategory(
    ItemCategoryModel body,
  ) => createModel(
    '/inventory/item-categories',
    body,
    fromJson: ItemCategoryModel.fromJson,
  );
  Future<ApiResponse<ItemCategoryModel>> updateItemCategory(
    int id,
    ItemCategoryModel body,
  ) => updateModel(
    '/inventory/item-categories/$id',
    body,
    fromJson: ItemCategoryModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteItemCategory(int id) =>
      destroy('/inventory/item-categories/$id');

  Future<PaginatedResponse<BrandModel>> brands({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/inventory/brands',
    filters: filters,
    fromJson: BrandModel.fromJson,
  );
  Future<ApiResponse<List<BrandModel>>> brandsDropdown({
    Map<String, dynamic>? filters,
  }) => collection(
    '/inventory/brands/dropdown',
    filters: filters,
    fromJson: BrandModel.fromJson,
  );
  Future<ApiResponse<BrandModel>> brand(int id) =>
      object('/inventory/brands/$id', fromJson: BrandModel.fromJson);
  Future<ApiResponse<BrandModel>> createBrand(BrandModel body) =>
      createModel('/inventory/brands', body, fromJson: BrandModel.fromJson);
  Future<ApiResponse<BrandModel>> updateBrand(int id, BrandModel body) =>
      updateModel('/inventory/brands/$id', body, fromJson: BrandModel.fromJson);
  Future<ApiResponse<dynamic>> deleteBrand(int id) =>
      destroy('/inventory/brands/$id');

  Future<PaginatedResponse<UomModel>> uoms({Map<String, dynamic>? filters}) =>
      paginated(
        '/inventory/uoms',
        filters: filters,
        fromJson: UomModel.fromJson,
      );
  Future<ApiResponse<List<UomModel>>> uomsDropdown({
    Map<String, dynamic>? filters,
  }) => collection(
    '/inventory/uoms/dropdown',
    filters: filters,
    fromJson: UomModel.fromJson,
  );
  Future<ApiResponse<UomModel>> uom(int id) =>
      object('/inventory/uoms/$id', fromJson: UomModel.fromJson);
  Future<ApiResponse<UomModel>> createUom(UomModel body) =>
      createModel('/inventory/uoms', body, fromJson: UomModel.fromJson);
  Future<ApiResponse<UomModel>> updateUom(int id, UomModel body) =>
      updateModel('/inventory/uoms/$id', body, fromJson: UomModel.fromJson);
  Future<ApiResponse<dynamic>> deleteUom(int id) =>
      destroy('/inventory/uoms/$id');

  Future<PaginatedResponse<UomConversionModel>> uomConversions({
    Map<String, dynamic>? filters,
  }) => paginated<UomConversionModel>(
    '/inventory/uom-conversions',
    filters: filters,
    fromJson: UomConversionModel.fromJson,
  );
  Future<ApiResponse<List<UomConversionModel>>> uomConversionsAll({
    Map<String, dynamic>? filters,
  }) => collection<UomConversionModel>(
    '/inventory/uom-conversions/all',
    filters: filters,
    fromJson: UomConversionModel.fromJson,
  );
  Future<ApiResponse<UomConversionModel>> uomConversionFactor({
    Map<String, dynamic>? filters,
  }) => object<UomConversionModel>(
    '/inventory/uom-conversions/factor',
    fromJson: UomConversionModel.fromJson,
  );
  Future<ApiResponse<UomConversionModel>> uomConversion(int id) =>
      object<UomConversionModel>(
        '/inventory/uom-conversions/$id',
        fromJson: UomConversionModel.fromJson,
      );
  Future<ApiResponse<UomConversionModel>> createUomConversion(
    UomConversionModel body,
  ) => createModel<UomConversionModel>(
    '/inventory/uom-conversions',
    body,
    fromJson: UomConversionModel.fromJson,
  );
  Future<ApiResponse<UomConversionModel>> updateUomConversion(
    int id,
    UomConversionModel body,
  ) => updateModel<UomConversionModel>(
    '/inventory/uom-conversions/$id',
    body,
    fromJson: UomConversionModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteUomConversion(int id) =>
      destroy('/inventory/uom-conversions/$id');

  Future<PaginatedResponse<TaxCodeModel>> taxCodes({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/inventory/tax-codes',
    filters: filters,
    fromJson: TaxCodeModel.fromJson,
  );
  Future<ApiResponse<List<TaxCodeModel>>> taxCodesDropdown({
    Map<String, dynamic>? filters,
  }) => collection(
    '/inventory/tax-codes/dropdown',
    filters: filters,
    fromJson: TaxCodeModel.fromJson,
  );
  Future<ApiResponse<TaxCodeModel>> taxCode(int id) =>
      object('/inventory/tax-codes/$id', fromJson: TaxCodeModel.fromJson);
  Future<ApiResponse<TaxCodeModel>> createTaxCode(TaxCodeModel body) =>
      createModel(
        '/inventory/tax-codes',
        body,
        fromJson: TaxCodeModel.fromJson,
      );
  Future<ApiResponse<TaxCodeModel>> updateTaxCode(int id, TaxCodeModel body) =>
      updateModel(
        '/inventory/tax-codes/$id',
        body,
        fromJson: TaxCodeModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteTaxCode(int id) =>
      destroy('/inventory/tax-codes/$id');

  Future<PaginatedResponse<ItemModel>> items({Map<String, dynamic>? filters}) =>
      paginated(
        '/inventory/items',
        filters: filters,
        fromJson: ItemModel.fromJson,
      );
  Future<ApiResponse<List<ItemModel>>> itemsDropdown({
    Map<String, dynamic>? filters,
  }) => collection(
    '/inventory/items/dropdown',
    filters: filters,
    fromJson: ItemModel.fromJson,
  );
  Future<ApiResponse<ItemModel>> item(int id) =>
      object('/inventory/items/$id', fromJson: ItemModel.fromJson);
  Future<ApiResponse<ItemModel>> createItem(ItemModel body) =>
      createModel('/inventory/items', body, fromJson: ItemModel.fromJson);
  Future<ApiResponse<ItemModel>> updateItem(int id, ItemModel body) =>
      updateModel('/inventory/items/$id', body, fromJson: ItemModel.fromJson);
  Future<ApiResponse<dynamic>> deleteItem(int id) =>
      destroy('/inventory/items/$id');

  Future<PaginatedResponse<ItemSupplierMapModel>> itemSupplierMaps({
    Map<String, dynamic>? filters,
  }) => paginated<ItemSupplierMapModel>(
    '/inventory/item-supplier-maps',
    filters: filters,
    fromJson: ItemSupplierMapModel.fromJson,
  );
  Future<ApiResponse<List<ItemSupplierMapModel>>> itemSupplierMapsDropdown({
    Map<String, dynamic>? filters,
  }) => collection<ItemSupplierMapModel>(
    '/inventory/item-supplier-maps/dropdown',
    filters: filters,
    fromJson: ItemSupplierMapModel.fromJson,
  );
  Future<ApiResponse<ItemSupplierMapModel>> itemSupplierMap(int id) =>
      object<ItemSupplierMapModel>(
        '/inventory/item-supplier-maps/$id',
        fromJson: ItemSupplierMapModel.fromJson,
      );
  Future<ApiResponse<ItemSupplierMapModel>> createItemSupplierMap(
    ItemSupplierMapModel body,
  ) => createModel<ItemSupplierMapModel>(
    '/inventory/item-supplier-maps',
    body,
    fromJson: ItemSupplierMapModel.fromJson,
  );
  Future<ApiResponse<ItemSupplierMapModel>> updateItemSupplierMap(
    int id,
    ItemSupplierMapModel body,
  ) => updateModel<ItemSupplierMapModel>(
    '/inventory/item-supplier-maps/$id',
    body,
    fromJson: ItemSupplierMapModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteItemSupplierMap(int id) =>
      destroy('/inventory/item-supplier-maps/$id');

  Future<PaginatedResponse<ItemAlternateModel>> itemAlternates({
    Map<String, dynamic>? filters,
  }) => paginated<ItemAlternateModel>(
    '/inventory/item-alternates',
    filters: filters,
    fromJson: ItemAlternateModel.fromJson,
  );
  Future<ApiResponse<List<ItemAlternateModel>>> itemAlternatesDropdown({
    Map<String, dynamic>? filters,
  }) => collection<ItemAlternateModel>(
    '/inventory/item-alternates/dropdown',
    filters: filters,
    fromJson: ItemAlternateModel.fromJson,
  );
  Future<ApiResponse<ItemAlternateModel>> itemAlternate(int id) =>
      object<ItemAlternateModel>(
        '/inventory/item-alternates/$id',
        fromJson: ItemAlternateModel.fromJson,
      );
  Future<ApiResponse<ItemAlternateModel>> createItemAlternate(
    ItemAlternateModel body,
  ) => createModel<ItemAlternateModel>(
    '/inventory/item-alternates',
    body,
    fromJson: ItemAlternateModel.fromJson,
  );
  Future<ApiResponse<ItemAlternateModel>> updateItemAlternate(
    int id,
    ItemAlternateModel body,
  ) => updateModel<ItemAlternateModel>(
    '/inventory/item-alternates/$id',
    body,
    fromJson: ItemAlternateModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteItemAlternate(int id) =>
      destroy('/inventory/item-alternates/$id');

  Future<PaginatedResponse<ItemPriceModel>> itemPrices({
    Map<String, dynamic>? filters,
  }) => paginated<ItemPriceModel>(
    '/inventory/item-prices',
    filters: filters,
    fromJson: ItemPriceModel.fromJson,
  );
  Future<ApiResponse<List<ItemPriceModel>>> itemPricesDropdown({
    Map<String, dynamic>? filters,
  }) => collection<ItemPriceModel>(
    '/inventory/item-prices/dropdown',
    filters: filters,
    fromJson: ItemPriceModel.fromJson,
  );
  Future<ApiResponse<ItemPriceModel>> itemPrice(int id) =>
      object<ItemPriceModel>(
        '/inventory/item-prices/$id',
        fromJson: ItemPriceModel.fromJson,
      );
  Future<ApiResponse<ItemPriceModel>> createItemPrice(ItemPriceModel body) =>
      createModel<ItemPriceModel>(
        '/inventory/item-prices',
        body,
        fromJson: ItemPriceModel.fromJson,
      );
  Future<ApiResponse<ItemPriceModel>> updateItemPrice(
    int id,
    ItemPriceModel body,
  ) => updateModel<ItemPriceModel>(
    '/inventory/item-prices/$id',
    body,
    fromJson: ItemPriceModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteItemPrice(int id) =>
      destroy('/inventory/item-prices/$id');

  Future<PaginatedResponse<StockBatchModel>> stockBatches({
    Map<String, dynamic>? filters,
  }) => paginated<StockBatchModel>(
    '/inventory/stock-batches',
    filters: filters,
    fromJson: StockBatchModel.fromJson,
  );
  Future<ApiResponse<List<StockBatchModel>>> stockBatchesDropdown({
    Map<String, dynamic>? filters,
  }) => collection<StockBatchModel>(
    '/inventory/stock-batches/dropdown',
    filters: filters,
    fromJson: StockBatchModel.fromJson,
  );
  Future<ApiResponse<StockBatchModel>> stockBatch(int id) =>
      object<StockBatchModel>(
        '/inventory/stock-batches/$id',
        fromJson: StockBatchModel.fromJson,
      );
  Future<ApiResponse<StockBatchModel>> createStockBatch(StockBatchModel body) =>
      createModel<StockBatchModel>(
        '/inventory/stock-batches',
        body,
        fromJson: StockBatchModel.fromJson,
      );
  Future<ApiResponse<StockBatchModel>> updateStockBatch(
    int id,
    StockBatchModel body,
  ) => updateModel<StockBatchModel>(
    '/inventory/stock-batches/$id',
    body,
    fromJson: StockBatchModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteStockBatch(int id) =>
      destroy('/inventory/stock-batches/$id');

  Future<PaginatedResponse<StockSerialModel>> stockSerials({
    Map<String, dynamic>? filters,
  }) => paginated<StockSerialModel>(
    '/inventory/stock-serials',
    filters: filters,
    fromJson: StockSerialModel.fromJson,
  );
  Future<ApiResponse<List<StockSerialModel>>> stockSerialsDropdown({
    Map<String, dynamic>? filters,
  }) => collection<StockSerialModel>(
    '/inventory/stock-serials/dropdown',
    filters: filters,
    fromJson: StockSerialModel.fromJson,
  );
  Future<ApiResponse<StockSerialModel>> stockSerial(int id) =>
      object<StockSerialModel>(
        '/inventory/stock-serials/$id',
        fromJson: StockSerialModel.fromJson,
      );
  Future<ApiResponse<StockSerialModel>> createStockSerial(
    StockSerialModel body,
  ) => createModel<StockSerialModel>(
    '/inventory/stock-serials',
    body,
    fromJson: StockSerialModel.fromJson,
  );
  Future<ApiResponse<StockSerialModel>> updateStockSerial(
    int id,
    StockSerialModel body,
  ) => updateModel<StockSerialModel>(
    '/inventory/stock-serials/$id',
    body,
    fromJson: StockSerialModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteStockSerial(int id) =>
      destroy('/inventory/stock-serials/$id');

  Future<PaginatedResponse<StockMovementModel>> stockMovements({
    Map<String, dynamic>? filters,
  }) => paginated<StockMovementModel>(
    '/inventory/stock-movements',
    filters: filters,
    fromJson: StockMovementModel.fromJson,
  );
  Future<ApiResponse<List<StockMovementModel>>> stockMovementsDropdown({
    Map<String, dynamic>? filters,
  }) => collection<StockMovementModel>(
    '/inventory/stock-movements/dropdown',
    filters: filters,
    fromJson: StockMovementModel.fromJson,
  );
  Future<ApiResponse<StockMovementModel>> stockMovement(int id) =>
      object<StockMovementModel>(
        '/inventory/stock-movements/$id',
        fromJson: StockMovementModel.fromJson,
      );
  Future<ApiResponse<StockMovementModel>> createStockMovement(
    StockMovementModel body,
  ) => createModel<StockMovementModel>(
    '/inventory/stock-movements',
    body,
    fromJson: StockMovementModel.fromJson,
  );
  Future<ApiResponse<StockMovementModel>> updateStockMovement(
    int id,
    StockMovementModel body,
  ) => updateModel<StockMovementModel>(
    '/inventory/stock-movements/$id',
    body,
    fromJson: StockMovementModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteStockMovement(int id) =>
      destroy('/inventory/stock-movements/$id');

  Future<PaginatedResponse<StockBalanceModel>> stockBalances({
    Map<String, dynamic>? filters,
  }) => paginated<StockBalanceModel>(
    '/inventory/stock-balances',
    filters: filters,
    fromJson: StockBalanceModel.fromJson,
  );
  Future<ApiResponse<List<StockBalanceModel>>> stockBalancesDropdown({
    Map<String, dynamic>? filters,
  }) => collection<StockBalanceModel>(
    '/inventory/stock-balances/dropdown',
    filters: filters,
    fromJson: StockBalanceModel.fromJson,
  );
  Future<ApiResponse<StockBalanceModel>> stockBalance(int id) =>
      object<StockBalanceModel>(
        '/inventory/stock-balances/$id',
        fromJson: StockBalanceModel.fromJson,
      );
  Future<ApiResponse<StockBalanceModel>> createStockBalance(
    StockBalanceModel body,
  ) => createModel<StockBalanceModel>(
    '/inventory/stock-balances',
    body,
    fromJson: StockBalanceModel.fromJson,
  );
  Future<ApiResponse<StockBalanceModel>> updateStockBalance(
    int id,
    StockBalanceModel body,
  ) => updateModel<StockBalanceModel>(
    '/inventory/stock-balances/$id',
    body,
    fromJson: StockBalanceModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteStockBalance(int id) =>
      destroy('/inventory/stock-balances/$id');

  Future<PaginatedResponse<InventoryAdjustmentModel>> inventoryAdjustments({
    Map<String, dynamic>? filters,
  }) => paginated<InventoryAdjustmentModel>(
    '/inventory/inventory-adjustments',
    filters: filters,
    fromJson: InventoryAdjustmentModel.fromJson,
  );
  Future<ApiResponse<InventoryAdjustmentModel>> inventoryAdjustment(int id) =>
      object<InventoryAdjustmentModel>(
        '/inventory/inventory-adjustments/$id',
        fromJson: InventoryAdjustmentModel.fromJson,
      );
  Future<ApiResponse<InventoryAdjustmentModel>> createInventoryAdjustment(
    InventoryAdjustmentModel body,
  ) => createModel<InventoryAdjustmentModel>(
    '/inventory/inventory-adjustments',
    body,
    fromJson: InventoryAdjustmentModel.fromJson,
  );
  Future<ApiResponse<InventoryAdjustmentModel>> updateInventoryAdjustment(
    int id,
    InventoryAdjustmentModel body,
  ) => updateModel<InventoryAdjustmentModel>(
    '/inventory/inventory-adjustments/$id',
    body,
    fromJson: InventoryAdjustmentModel.fromJson,
  );
  Future<ApiResponse<InventoryAdjustmentModel>> postInventoryAdjustment(
    int id,
    InventoryAdjustmentModel body,
  ) => actionModel<InventoryAdjustmentModel>(
    '/inventory/inventory-adjustments/$id/post',
    body: body,
    fromJson: InventoryAdjustmentModel.fromJson,
  );
  Future<ApiResponse<InventoryAdjustmentModel>> cancelInventoryAdjustment(
    int id,
    InventoryAdjustmentModel body,
  ) => actionModel<InventoryAdjustmentModel>(
    '/inventory/inventory-adjustments/$id/cancel',
    body: body,
    fromJson: InventoryAdjustmentModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteInventoryAdjustment(int id) =>
      destroy('/inventory/inventory-adjustments/$id');

  Future<PaginatedResponse<OpeningStockModel>> openingStocks({
    Map<String, dynamic>? filters,
  }) => paginated<OpeningStockModel>(
    '/inventory/opening-stocks',
    filters: filters,
    fromJson: OpeningStockModel.fromJson,
  );
  Future<ApiResponse<OpeningStockModel>> openingStock(int id) =>
      object<OpeningStockModel>(
        '/inventory/opening-stocks/$id',
        fromJson: OpeningStockModel.fromJson,
      );
  Future<ApiResponse<OpeningStockModel>> createOpeningStock(
    OpeningStockModel body,
  ) => createModel<OpeningStockModel>(
    '/inventory/opening-stocks',
    body,
    fromJson: OpeningStockModel.fromJson,
  );
  Future<ApiResponse<OpeningStockModel>> updateOpeningStock(
    int id,
    OpeningStockModel body,
  ) => updateModel<OpeningStockModel>(
    '/inventory/opening-stocks/$id',
    body,
    fromJson: OpeningStockModel.fromJson,
  );
  Future<ApiResponse<OpeningStockModel>> postOpeningStock(
    int id,
    OpeningStockModel body,
  ) => actionModel<OpeningStockModel>(
    '/inventory/opening-stocks/$id/post',
    body: body,
    fromJson: OpeningStockModel.fromJson,
  );
  Future<ApiResponse<OpeningStockModel>> cancelOpeningStock(
    int id,
    OpeningStockModel body,
  ) => actionModel<OpeningStockModel>(
    '/inventory/opening-stocks/$id/cancel',
    body: body,
    fromJson: OpeningStockModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteOpeningStock(int id) =>
      destroy('/inventory/opening-stocks/$id');

  Future<PaginatedResponse<StockTransferModel>> stockTransfers({
    Map<String, dynamic>? filters,
  }) => paginated<StockTransferModel>(
    '/inventory/stock-transfers',
    filters: filters,
    fromJson: StockTransferModel.fromJson,
  );
  Future<ApiResponse<StockTransferModel>> stockTransfer(int id) =>
      object<StockTransferModel>(
        '/inventory/stock-transfers/$id',
        fromJson: StockTransferModel.fromJson,
      );
  Future<ApiResponse<StockTransferModel>> createStockTransfer(
    StockTransferModel body,
  ) => createModel<StockTransferModel>(
    '/inventory/stock-transfers',
    body,
    fromJson: StockTransferModel.fromJson,
  );
  Future<ApiResponse<StockTransferModel>> updateStockTransfer(
    int id,
    StockTransferModel body,
  ) => updateModel<StockTransferModel>(
    '/inventory/stock-transfers/$id',
    body,
    fromJson: StockTransferModel.fromJson,
  );
  Future<ApiResponse<StockTransferModel>> postStockTransfer(
    int id,
    StockTransferModel body,
  ) => actionModel<StockTransferModel>(
    '/inventory/stock-transfers/$id/post',
    body: body,
    fromJson: StockTransferModel.fromJson,
  );
  Future<ApiResponse<StockTransferModel>> cancelStockTransfer(
    int id,
    StockTransferModel body,
  ) => actionModel<StockTransferModel>(
    '/inventory/stock-transfers/$id/cancel',
    body: body,
    fromJson: StockTransferModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteStockTransfer(int id) =>
      destroy('/inventory/stock-transfers/$id');

  Future<PaginatedResponse<StockIssueModel>> stockIssues({
    Map<String, dynamic>? filters,
  }) => paginated<StockIssueModel>(
    '/inventory/stock-issues',
    filters: filters,
    fromJson: StockIssueModel.fromJson,
  );
  Future<ApiResponse<StockIssueModel>> stockIssue(int id) =>
      object<StockIssueModel>(
        '/inventory/stock-issues/$id',
        fromJson: StockIssueModel.fromJson,
      );
  Future<ApiResponse<StockIssueModel>> createStockIssue(StockIssueModel body) =>
      createModel<StockIssueModel>(
        '/inventory/stock-issues',
        body,
        fromJson: StockIssueModel.fromJson,
      );
  Future<ApiResponse<StockIssueModel>> updateStockIssue(
    int id,
    StockIssueModel body,
  ) => updateModel<StockIssueModel>(
    '/inventory/stock-issues/$id',
    body,
    fromJson: StockIssueModel.fromJson,
  );
  Future<ApiResponse<StockIssueModel>> postStockIssue(
    int id,
    StockIssueModel body,
  ) => actionModel<StockIssueModel>(
    '/inventory/stock-issues/$id/post',
    body: body,
    fromJson: StockIssueModel.fromJson,
  );
  Future<ApiResponse<StockIssueModel>> cancelStockIssue(
    int id,
    StockIssueModel body,
  ) => actionModel<StockIssueModel>(
    '/inventory/stock-issues/$id/cancel',
    body: body,
    fromJson: StockIssueModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteStockIssue(int id) =>
      destroy('/inventory/stock-issues/$id');

  Future<PaginatedResponse<InternalStockReceiptModel>> internalStockReceipts({
    Map<String, dynamic>? filters,
  }) => paginated<InternalStockReceiptModel>(
    '/inventory/internal-stock-receipts',
    filters: filters,
    fromJson: InternalStockReceiptModel.fromJson,
  );
  Future<ApiResponse<InternalStockReceiptModel>> internalStockReceipt(int id) =>
      object<InternalStockReceiptModel>(
        '/inventory/internal-stock-receipts/$id',
        fromJson: InternalStockReceiptModel.fromJson,
      );
  Future<ApiResponse<InternalStockReceiptModel>> createInternalStockReceipt(
    InternalStockReceiptModel body,
  ) => createModel<InternalStockReceiptModel>(
    '/inventory/internal-stock-receipts',
    body,
    fromJson: InternalStockReceiptModel.fromJson,
  );
  Future<ApiResponse<InternalStockReceiptModel>> updateInternalStockReceipt(
    int id,
    InternalStockReceiptModel body,
  ) => updateModel<InternalStockReceiptModel>(
    '/inventory/internal-stock-receipts/$id',
    body,
    fromJson: InternalStockReceiptModel.fromJson,
  );
  Future<ApiResponse<InternalStockReceiptModel>> postInternalStockReceipt(
    int id,
    InternalStockReceiptModel body,
  ) => actionModel<InternalStockReceiptModel>(
    '/inventory/internal-stock-receipts/$id/post',
    body: body,
    fromJson: InternalStockReceiptModel.fromJson,
  );
  Future<ApiResponse<InternalStockReceiptModel>> cancelInternalStockReceipt(
    int id,
    InternalStockReceiptModel body,
  ) => actionModel<InternalStockReceiptModel>(
    '/inventory/internal-stock-receipts/$id/cancel',
    body: body,
    fromJson: InternalStockReceiptModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteInternalStockReceipt(int id) =>
      destroy('/inventory/internal-stock-receipts/$id');

  Future<PaginatedResponse<StockDamageEntryModel>> stockDamageEntries({
    Map<String, dynamic>? filters,
  }) => paginated<StockDamageEntryModel>(
    '/inventory/stock-damage-entries',
    filters: filters,
    fromJson: StockDamageEntryModel.fromJson,
  );
  Future<ApiResponse<StockDamageEntryModel>> stockDamageEntry(int id) =>
      object<StockDamageEntryModel>(
        '/inventory/stock-damage-entries/$id',
        fromJson: StockDamageEntryModel.fromJson,
      );
  Future<ApiResponse<StockDamageEntryModel>> createStockDamageEntry(
    StockDamageEntryModel body,
  ) => createModel<StockDamageEntryModel>(
    '/inventory/stock-damage-entries',
    body,
    fromJson: StockDamageEntryModel.fromJson,
  );
  Future<ApiResponse<StockDamageEntryModel>> updateStockDamageEntry(
    int id,
    StockDamageEntryModel body,
  ) => updateModel<StockDamageEntryModel>(
    '/inventory/stock-damage-entries/$id',
    body,
    fromJson: StockDamageEntryModel.fromJson,
  );
  Future<ApiResponse<StockDamageEntryModel>> postStockDamageEntry(
    int id,
    StockDamageEntryModel body,
  ) => actionModel<StockDamageEntryModel>(
    '/inventory/stock-damage-entries/$id/post',
    body: body,
    fromJson: StockDamageEntryModel.fromJson,
  );
  Future<ApiResponse<StockDamageEntryModel>> cancelStockDamageEntry(
    int id,
    StockDamageEntryModel body,
  ) => actionModel<StockDamageEntryModel>(
    '/inventory/stock-damage-entries/$id/cancel',
    body: body,
    fromJson: StockDamageEntryModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteStockDamageEntry(int id) =>
      destroy('/inventory/stock-damage-entries/$id');

  Future<PaginatedResponse<PhysicalStockCountModel>> physicalStockCounts({
    Map<String, dynamic>? filters,
  }) => paginated<PhysicalStockCountModel>(
    '/inventory/physical-stock-counts',
    filters: filters,
    fromJson: PhysicalStockCountModel.fromJson,
  );
  Future<ApiResponse<PhysicalStockCountModel>> physicalStockCount(int id) =>
      object<PhysicalStockCountModel>(
        '/inventory/physical-stock-counts/$id',
        fromJson: PhysicalStockCountModel.fromJson,
      );
  Future<ApiResponse<PhysicalStockCountModel>> createPhysicalStockCount(
    PhysicalStockCountModel body,
  ) => createModel<PhysicalStockCountModel>(
    '/inventory/physical-stock-counts',
    body,
    fromJson: PhysicalStockCountModel.fromJson,
  );
  Future<ApiResponse<PhysicalStockCountModel>> updatePhysicalStockCount(
    int id,
    PhysicalStockCountModel body,
  ) => updateModel<PhysicalStockCountModel>(
    '/inventory/physical-stock-counts/$id',
    body,
    fromJson: PhysicalStockCountModel.fromJson,
  );
  Future<ApiResponse<PhysicalStockCountModel>> markPhysicalCounted(
    int id,
    PhysicalStockCountModel body,
  ) => actionModel<PhysicalStockCountModel>(
    '/inventory/physical-stock-counts/$id/counted',
    body: body,
    fromJson: PhysicalStockCountModel.fromJson,
  );
  Future<ApiResponse<PhysicalStockCountModel>> reconcilePhysicalStockCount(
    int id,
    PhysicalStockCountModel body,
  ) => actionModel<PhysicalStockCountModel>(
    '/inventory/physical-stock-counts/$id/reconcile',
    body: body,
    fromJson: PhysicalStockCountModel.fromJson,
  );
  Future<ApiResponse<PhysicalStockCountModel>> cancelPhysicalStockCount(
    int id,
    PhysicalStockCountModel body,
  ) => actionModel<PhysicalStockCountModel>(
    '/inventory/physical-stock-counts/$id/cancel',
    body: body,
    fromJson: PhysicalStockCountModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deletePhysicalStockCount(int id) =>
      destroy('/inventory/physical-stock-counts/$id');

  Future<PaginatedResponse<ErpReportRowModel>> stockSummary({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/inventory/inquiry/stock-summary',
    filters: filters,
    fromJson: ErpReportRowModel.fromJson,
  );
  Future<PaginatedResponse<ErpReportRowModel>> warehouseWiseStock({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/inventory/inquiry/warehouse-wise-stock',
    filters: filters,
    fromJson: ErpReportRowModel.fromJson,
  );
  Future<PaginatedResponse<ErpReportRowModel>> batchWiseStock({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/inventory/inquiry/batch-wise-stock',
    filters: filters,
    fromJson: ErpReportRowModel.fromJson,
  );
  Future<PaginatedResponse<ErpReportRowModel>> availableSerials({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/inventory/inquiry/available-serials',
    filters: filters,
    fromJson: ErpReportRowModel.fromJson,
  );
  Future<PaginatedResponse<ErpReportRowModel>> stockCard({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/inventory/inquiry/stock-card',
    filters: filters,
    fromJson: ErpReportRowModel.fromJson,
  );
  Future<PaginatedResponse<ErpReportRowModel>> reorderStatus({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/inventory/inquiry/reorder-status',
    filters: filters,
    fromJson: ErpReportRowModel.fromJson,
  );
}
