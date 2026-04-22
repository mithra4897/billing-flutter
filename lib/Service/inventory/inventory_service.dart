import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
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
import '../../core/api/api_endpoints.dart';
import '../base/erp_module_service.dart';

class InventoryService extends ErpModuleService {
  InventoryService({super.apiClient});

  Future<PaginatedResponse<ItemCategoryModel>> itemCategories({
    Map<String, dynamic>? filters,
  }) => paginated(
    ApiEndpoints.itemCategories,
    filters: filters,
    fromJson: ItemCategoryModel.fromJson,
  );
  Future<ApiResponse<List<ItemCategoryModel>>> itemCategoriesDropdown({
    Map<String, dynamic>? filters,
  }) => collection(
    ApiEndpoints.itemCategoriesDropdown,
    filters: filters,
    fromJson: ItemCategoryModel.fromJson,
  );
  Future<ApiResponse<ItemCategoryModel>> itemCategory(int id) => object(
    '${ApiEndpoints.itemCategories}/$id',
    fromJson: ItemCategoryModel.fromJson,
  );
  Future<ApiResponse<ItemCategoryModel>> createItemCategory(
    ItemCategoryModel body,
  ) => createModel(
    ApiEndpoints.itemCategories,
    body,
    fromJson: ItemCategoryModel.fromJson,
  );
  Future<ApiResponse<ItemCategoryModel>> updateItemCategory(
    int id,
    ItemCategoryModel body,
  ) => updateModel(
    '${ApiEndpoints.itemCategories}/$id',
    body,
    fromJson: ItemCategoryModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteItemCategory(int id) =>
      destroy('${ApiEndpoints.itemCategories}/$id');

  Future<PaginatedResponse<BrandModel>> brands({
    Map<String, dynamic>? filters,
  }) => paginated(
    ApiEndpoints.brands,
    filters: filters,
    fromJson: BrandModel.fromJson,
  );
  Future<ApiResponse<List<BrandModel>>> brandsDropdown({
    Map<String, dynamic>? filters,
  }) => collection(
    ApiEndpoints.brandsDropdown,
    filters: filters,
    fromJson: BrandModel.fromJson,
  );
  Future<ApiResponse<BrandModel>> brand(int id) =>
      object('${ApiEndpoints.brands}/$id', fromJson: BrandModel.fromJson);
  Future<ApiResponse<BrandModel>> createBrand(BrandModel body) =>
      createModel(ApiEndpoints.brands, body, fromJson: BrandModel.fromJson);
  Future<ApiResponse<BrandModel>> updateBrand(int id, BrandModel body) =>
      updateModel('${ApiEndpoints.brands}/$id', body, fromJson: BrandModel.fromJson);
  Future<ApiResponse<dynamic>> deleteBrand(int id) =>
      destroy('${ApiEndpoints.brands}/$id');

  Future<PaginatedResponse<UomModel>> uoms({Map<String, dynamic>? filters}) =>
      paginated(
        ApiEndpoints.uoms,
        filters: filters,
        fromJson: UomModel.fromJson,
      );
  Future<ApiResponse<List<UomModel>>> uomsDropdown({
    Map<String, dynamic>? filters,
  }) => collection(
    ApiEndpoints.uomsDropdown,
    filters: filters,
    fromJson: UomModel.fromJson,
  );
  Future<ApiResponse<UomModel>> uom(int id) =>
      object('${ApiEndpoints.uoms}/$id', fromJson: UomModel.fromJson);
  Future<ApiResponse<UomModel>> createUom(UomModel body) =>
      createModel(ApiEndpoints.uoms, body, fromJson: UomModel.fromJson);
  Future<ApiResponse<UomModel>> updateUom(int id, UomModel body) =>
      updateModel('${ApiEndpoints.uoms}/$id', body, fromJson: UomModel.fromJson);
  Future<ApiResponse<dynamic>> deleteUom(int id) =>
      destroy('${ApiEndpoints.uoms}/$id');

  Future<PaginatedResponse<UomConversionModel>> uomConversions({
    Map<String, dynamic>? filters,
  }) => paginated<UomConversionModel>(
    ApiEndpoints.uomConversions,
    filters: filters,
    fromJson: UomConversionModel.fromJson,
  );
  Future<PaginatedResponse<UomConversionModel>> uomConversionsAll({
    Map<String, dynamic>? filters,
  }) => paginated<UomConversionModel>(
    ApiEndpoints.uomConversionsAll,
    filters: filters,
    fromJson: UomConversionModel.fromJson,
  );
  Future<ApiResponse<UomConversionModel>> uomConversionFactor({
    Map<String, dynamic>? filters,
  }) => object<UomConversionModel>(
    ApiEndpoints.uomConversionsFactor,
    fromJson: UomConversionModel.fromJson,
  );
  Future<ApiResponse<UomConversionModel>> uomConversion(int id) =>
      object<UomConversionModel>(
        '${ApiEndpoints.uomConversions}/$id',
        fromJson: UomConversionModel.fromJson,
      );
  Future<ApiResponse<UomConversionModel>> createUomConversion(
    UomConversionModel body,
  ) => createModel<UomConversionModel>(
    ApiEndpoints.uomConversions,
    body,
    fromJson: UomConversionModel.fromJson,
  );
  Future<ApiResponse<UomConversionModel>> updateUomConversion(
    int id,
    UomConversionModel body,
  ) => updateModel<UomConversionModel>(
    '${ApiEndpoints.uomConversions}/$id',
    body,
    fromJson: UomConversionModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteUomConversion(int id) =>
      destroy('${ApiEndpoints.uomConversions}/$id');

  Future<PaginatedResponse<TaxCodeModel>> taxCodes({
    Map<String, dynamic>? filters,
  }) => paginated(
    ApiEndpoints.taxCodes,
    filters: filters,
    fromJson: TaxCodeModel.fromJson,
  );
  Future<ApiResponse<List<TaxCodeModel>>> taxCodesDropdown({
    Map<String, dynamic>? filters,
  }) => collection(
    ApiEndpoints.taxCodesDropdown,
    filters: filters,
    fromJson: TaxCodeModel.fromJson,
  );
  Future<ApiResponse<TaxCodeModel>> taxCode(int id) =>
      object('${ApiEndpoints.taxCodes}/$id', fromJson: TaxCodeModel.fromJson);
  Future<ApiResponse<TaxCodeModel>> createTaxCode(TaxCodeModel body) =>
      createModel(
        ApiEndpoints.taxCodes,
        body,
        fromJson: TaxCodeModel.fromJson,
      );
  Future<ApiResponse<TaxCodeModel>> updateTaxCode(int id, TaxCodeModel body) =>
      updateModel(
        '${ApiEndpoints.taxCodes}/$id',
        body,
        fromJson: TaxCodeModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteTaxCode(int id) =>
      destroy('${ApiEndpoints.taxCodes}/$id');

  Future<PaginatedResponse<ItemModel>> items({Map<String, dynamic>? filters}) =>
      paginated(
        ApiEndpoints.items,
        filters: filters,
        fromJson: ItemModel.fromJson,
      );
  Future<ApiResponse<List<ItemModel>>> itemsDropdown({
    Map<String, dynamic>? filters,
  }) => collection(
    ApiEndpoints.itemsDropdown,
    filters: filters,
    fromJson: ItemModel.fromJson,
  );
  Future<ApiResponse<ItemModel>> item(int id) =>
      object('${ApiEndpoints.items}/$id', fromJson: ItemModel.fromJson);
  Future<ApiResponse<ItemModel>> createItem(ItemModel body) =>
      createModel(ApiEndpoints.items, body, fromJson: ItemModel.fromJson);
  Future<ApiResponse<ItemModel>> updateItem(int id, ItemModel body) =>
      updateModel('${ApiEndpoints.items}/$id', body, fromJson: ItemModel.fromJson);
  Future<ApiResponse<dynamic>> deleteItem(int id) =>
      destroy('${ApiEndpoints.items}/$id');

  Future<PaginatedResponse<ItemSupplierMapModel>> itemSupplierMaps({
    Map<String, dynamic>? filters,
  }) => paginated<ItemSupplierMapModel>(
    ApiEndpoints.itemSupplierMaps,
    filters: filters,
    fromJson: ItemSupplierMapModel.fromJson,
  );
  Future<ApiResponse<List<ItemSupplierMapModel>>> itemSupplierMapsDropdown({
    Map<String, dynamic>? filters,
  }) => collection<ItemSupplierMapModel>(
    ApiEndpoints.itemSupplierMapsDropdown,
    filters: filters,
    fromJson: ItemSupplierMapModel.fromJson,
  );
  Future<ApiResponse<ItemSupplierMapModel>> itemSupplierMap(int id) =>
      object<ItemSupplierMapModel>(
        '${ApiEndpoints.itemSupplierMaps}/$id',
        fromJson: ItemSupplierMapModel.fromJson,
      );
  Future<ApiResponse<ItemSupplierMapModel>> createItemSupplierMap(
    ItemSupplierMapModel body,
  ) => createModel<ItemSupplierMapModel>(
    ApiEndpoints.itemSupplierMaps,
    body,
    fromJson: ItemSupplierMapModel.fromJson,
  );
  Future<ApiResponse<ItemSupplierMapModel>> updateItemSupplierMap(
    int id,
    ItemSupplierMapModel body,
  ) => updateModel<ItemSupplierMapModel>(
    '${ApiEndpoints.itemSupplierMaps}/$id',
    body,
    fromJson: ItemSupplierMapModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteItemSupplierMap(int id) =>
      destroy('${ApiEndpoints.itemSupplierMaps}/$id');

  Future<PaginatedResponse<ItemAlternateModel>> itemAlternates({
    Map<String, dynamic>? filters,
  }) => paginated<ItemAlternateModel>(
    ApiEndpoints.itemAlternates,
    filters: filters,
    fromJson: ItemAlternateModel.fromJson,
  );
  Future<ApiResponse<List<ItemAlternateModel>>> itemAlternatesDropdown({
    Map<String, dynamic>? filters,
  }) => collection<ItemAlternateModel>(
    ApiEndpoints.itemAlternatesDropdown,
    filters: filters,
    fromJson: ItemAlternateModel.fromJson,
  );
  Future<ApiResponse<ItemAlternateModel>> itemAlternate(int id) =>
      object<ItemAlternateModel>(
        '${ApiEndpoints.itemAlternates}/$id',
        fromJson: ItemAlternateModel.fromJson,
      );
  Future<ApiResponse<ItemAlternateModel>> createItemAlternate(
    ItemAlternateModel body,
  ) => createModel<ItemAlternateModel>(
    ApiEndpoints.itemAlternates,
    body,
    fromJson: ItemAlternateModel.fromJson,
  );
  Future<ApiResponse<ItemAlternateModel>> updateItemAlternate(
    int id,
    ItemAlternateModel body,
  ) => updateModel<ItemAlternateModel>(
    '${ApiEndpoints.itemAlternates}/$id',
    body,
    fromJson: ItemAlternateModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteItemAlternate(int id) =>
      destroy('${ApiEndpoints.itemAlternates}/$id');

  Future<PaginatedResponse<ItemPriceModel>> itemPrices({
    Map<String, dynamic>? filters,
  }) => paginated<ItemPriceModel>(
    ApiEndpoints.itemPrices,
    filters: filters,
    fromJson: ItemPriceModel.fromJson,
  );
  Future<ApiResponse<List<ItemPriceModel>>> itemPricesDropdown({
    Map<String, dynamic>? filters,
  }) => collection<ItemPriceModel>(
    ApiEndpoints.itemPricesDropdown,
    filters: filters,
    fromJson: ItemPriceModel.fromJson,
  );
  Future<ApiResponse<ItemPriceModel>> itemPrice(int id) =>
      object<ItemPriceModel>(
        '${ApiEndpoints.itemPrices}/$id',
        fromJson: ItemPriceModel.fromJson,
      );
  Future<ApiResponse<ItemPriceModel>> createItemPrice(ItemPriceModel body) =>
      createModel<ItemPriceModel>(
        ApiEndpoints.itemPrices,
        body,
        fromJson: ItemPriceModel.fromJson,
      );
  Future<ApiResponse<ItemPriceModel>> updateItemPrice(
    int id,
    ItemPriceModel body,
  ) => updateModel<ItemPriceModel>(
    '${ApiEndpoints.itemPrices}/$id',
    body,
    fromJson: ItemPriceModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteItemPrice(int id) =>
      destroy('${ApiEndpoints.itemPrices}/$id');

  Future<PaginatedResponse<StockBatchModel>> stockBatches({
    Map<String, dynamic>? filters,
  }) => paginated<StockBatchModel>(
    ApiEndpoints.stockBatches,
    filters: filters,
    fromJson: StockBatchModel.fromJson,
  );
  Future<ApiResponse<List<StockBatchModel>>> stockBatchesDropdown({
    Map<String, dynamic>? filters,
  }) => collection<StockBatchModel>(
    ApiEndpoints.stockBatchesDropdown,
    filters: filters,
    fromJson: StockBatchModel.fromJson,
  );
  Future<ApiResponse<StockBatchModel>> stockBatch(int id) =>
      object<StockBatchModel>(
        '${ApiEndpoints.stockBatches}/$id',
        fromJson: StockBatchModel.fromJson,
      );
  Future<ApiResponse<StockBatchModel>> createStockBatch(StockBatchModel body) =>
      createModel<StockBatchModel>(
        ApiEndpoints.stockBatches,
        body,
        fromJson: StockBatchModel.fromJson,
      );
  Future<ApiResponse<StockBatchModel>> updateStockBatch(
    int id,
    StockBatchModel body,
  ) => updateModel<StockBatchModel>(
    '${ApiEndpoints.stockBatches}/$id',
    body,
    fromJson: StockBatchModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteStockBatch(int id) =>
      destroy('${ApiEndpoints.stockBatches}/$id');

  Future<PaginatedResponse<StockSerialModel>> stockSerials({
    Map<String, dynamic>? filters,
  }) => paginated<StockSerialModel>(
    ApiEndpoints.stockSerials,
    filters: filters,
    fromJson: StockSerialModel.fromJson,
  );
  Future<ApiResponse<List<StockSerialModel>>> stockSerialsDropdown({
    Map<String, dynamic>? filters,
  }) => collection<StockSerialModel>(
    ApiEndpoints.stockSerialsDropdown,
    filters: filters,
    fromJson: StockSerialModel.fromJson,
  );
  Future<ApiResponse<StockSerialModel>> stockSerial(int id) =>
      object<StockSerialModel>(
        '${ApiEndpoints.stockSerials}/$id',
        fromJson: StockSerialModel.fromJson,
      );
  Future<ApiResponse<StockSerialModel>> createStockSerial(
    StockSerialModel body,
  ) => createModel<StockSerialModel>(
    ApiEndpoints.stockSerials,
    body,
    fromJson: StockSerialModel.fromJson,
  );
  Future<ApiResponse<StockSerialModel>> updateStockSerial(
    int id,
    StockSerialModel body,
  ) => updateModel<StockSerialModel>(
    '${ApiEndpoints.stockSerials}/$id',
    body,
    fromJson: StockSerialModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteStockSerial(int id) =>
      destroy('${ApiEndpoints.stockSerials}/$id');

  Future<PaginatedResponse<StockMovementModel>> stockMovements({
    Map<String, dynamic>? filters,
  }) => paginated<StockMovementModel>(
    ApiEndpoints.stockMovements,
    filters: filters,
    fromJson: StockMovementModel.fromJson,
  );
  Future<ApiResponse<List<StockMovementModel>>> stockMovementsDropdown({
    Map<String, dynamic>? filters,
  }) => collection<StockMovementModel>(
    ApiEndpoints.stockMovementsDropdown,
    filters: filters,
    fromJson: StockMovementModel.fromJson,
  );
  Future<ApiResponse<StockMovementModel>> stockMovement(int id) =>
      object<StockMovementModel>(
        '${ApiEndpoints.stockMovements}/$id',
        fromJson: StockMovementModel.fromJson,
      );
  Future<ApiResponse<StockMovementModel>> createStockMovement(
    StockMovementModel body,
  ) => createModel<StockMovementModel>(
    ApiEndpoints.stockMovements,
    body,
    fromJson: StockMovementModel.fromJson,
  );
  Future<ApiResponse<StockMovementModel>> updateStockMovement(
    int id,
    StockMovementModel body,
  ) => updateModel<StockMovementModel>(
    '${ApiEndpoints.stockMovements}/$id',
    body,
    fromJson: StockMovementModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteStockMovement(int id) =>
      destroy('${ApiEndpoints.stockMovements}/$id');

  Future<PaginatedResponse<StockBalanceModel>> stockBalances({
    Map<String, dynamic>? filters,
  }) => paginated<StockBalanceModel>(
    ApiEndpoints.stockBalances,
    filters: filters,
    fromJson: StockBalanceModel.fromJson,
  );
  Future<ApiResponse<List<StockBalanceModel>>> stockBalancesDropdown({
    Map<String, dynamic>? filters,
  }) => collection<StockBalanceModel>(
    ApiEndpoints.stockBalancesDropdown,
    filters: filters,
    fromJson: StockBalanceModel.fromJson,
  );
  Future<ApiResponse<StockBalanceModel>> stockBalance(int id) =>
      object<StockBalanceModel>(
        '${ApiEndpoints.stockBalances}/$id',
        fromJson: StockBalanceModel.fromJson,
      );

  Future<PaginatedResponse<InventoryAdjustmentModel>> inventoryAdjustments({
    Map<String, dynamic>? filters,
  }) => paginated<InventoryAdjustmentModel>(
    ApiEndpoints.inventoryAdjustments,
    filters: filters,
    fromJson: InventoryAdjustmentModel.fromJson,
  );
  Future<ApiResponse<InventoryAdjustmentModel>> inventoryAdjustment(int id) =>
      object<InventoryAdjustmentModel>(
        '${ApiEndpoints.inventoryAdjustments}/$id',
        fromJson: InventoryAdjustmentModel.fromJson,
      );
  Future<ApiResponse<InventoryAdjustmentModel>> createInventoryAdjustment(
    InventoryAdjustmentModel body,
  ) => createModel<InventoryAdjustmentModel>(
    ApiEndpoints.inventoryAdjustments,
    body,
    fromJson: InventoryAdjustmentModel.fromJson,
  );
  Future<ApiResponse<InventoryAdjustmentModel>> updateInventoryAdjustment(
    int id,
    InventoryAdjustmentModel body,
  ) => updateModel<InventoryAdjustmentModel>(
    '${ApiEndpoints.inventoryAdjustments}/$id',
    body,
    fromJson: InventoryAdjustmentModel.fromJson,
  );
  Future<ApiResponse<InventoryAdjustmentModel>> postInventoryAdjustment(
    int id,
    InventoryAdjustmentModel body,
  ) => actionModel<InventoryAdjustmentModel>(
    '${ApiEndpoints.inventoryAdjustments}/$id/post',
    body: body,
    fromJson: InventoryAdjustmentModel.fromJson,
  );
  Future<ApiResponse<InventoryAdjustmentModel>> cancelInventoryAdjustment(
    int id,
    InventoryAdjustmentModel body,
  ) => actionModel<InventoryAdjustmentModel>(
    '${ApiEndpoints.inventoryAdjustments}/$id/cancel',
    body: body,
    fromJson: InventoryAdjustmentModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteInventoryAdjustment(int id) =>
      destroy('${ApiEndpoints.inventoryAdjustments}/$id');

  Future<PaginatedResponse<OpeningStockModel>> openingStocks({
    Map<String, dynamic>? filters,
  }) => paginated<OpeningStockModel>(
    ApiEndpoints.openingStocks,
    filters: filters,
    fromJson: OpeningStockModel.fromJson,
  );
  Future<ApiResponse<OpeningStockModel>> openingStock(int id) =>
      object<OpeningStockModel>(
        '${ApiEndpoints.openingStocks}/$id',
        fromJson: OpeningStockModel.fromJson,
      );
  Future<ApiResponse<OpeningStockModel>> createOpeningStock(
    OpeningStockModel body,
  ) => createModel<OpeningStockModel>(
    ApiEndpoints.openingStocks,
    body,
    fromJson: OpeningStockModel.fromJson,
  );
  Future<ApiResponse<OpeningStockModel>> updateOpeningStock(
    int id,
    OpeningStockModel body,
  ) => updateModel<OpeningStockModel>(
    '${ApiEndpoints.openingStocks}/$id',
    body,
    fromJson: OpeningStockModel.fromJson,
  );
  Future<ApiResponse<OpeningStockModel>> postOpeningStock(
    int id,
    OpeningStockModel body,
  ) => actionModel<OpeningStockModel>(
    '${ApiEndpoints.openingStocks}/$id/post',
    body: body,
    fromJson: OpeningStockModel.fromJson,
  );
  Future<ApiResponse<OpeningStockModel>> cancelOpeningStock(
    int id,
    OpeningStockModel body,
  ) => actionModel<OpeningStockModel>(
    '${ApiEndpoints.openingStocks}/$id/cancel',
    body: body,
    fromJson: OpeningStockModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteOpeningStock(int id) =>
      destroy('${ApiEndpoints.openingStocks}/$id');

  Future<PaginatedResponse<StockTransferModel>> stockTransfers({
    Map<String, dynamic>? filters,
  }) => paginated<StockTransferModel>(
    ApiEndpoints.stockTransfers,
    filters: filters,
    fromJson: StockTransferModel.fromJson,
  );
  Future<ApiResponse<StockTransferModel>> stockTransfer(int id) =>
      object<StockTransferModel>(
        '${ApiEndpoints.stockTransfers}/$id',
        fromJson: StockTransferModel.fromJson,
      );
  Future<ApiResponse<StockTransferModel>> createStockTransfer(
    StockTransferModel body,
  ) => createModel<StockTransferModel>(
    ApiEndpoints.stockTransfers,
    body,
    fromJson: StockTransferModel.fromJson,
  );
  Future<ApiResponse<StockTransferModel>> updateStockTransfer(
    int id,
    StockTransferModel body,
  ) => updateModel<StockTransferModel>(
    '${ApiEndpoints.stockTransfers}/$id',
    body,
    fromJson: StockTransferModel.fromJson,
  );
  Future<ApiResponse<StockTransferModel>> postStockTransfer(
    int id,
    StockTransferModel body,
  ) => actionModel<StockTransferModel>(
    '${ApiEndpoints.stockTransfers}/$id/post',
    body: body,
    fromJson: StockTransferModel.fromJson,
  );
  Future<ApiResponse<StockTransferModel>> cancelStockTransfer(
    int id,
    StockTransferModel body,
  ) => actionModel<StockTransferModel>(
    '${ApiEndpoints.stockTransfers}/$id/cancel',
    body: body,
    fromJson: StockTransferModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteStockTransfer(int id) =>
      destroy('${ApiEndpoints.stockTransfers}/$id');

  Future<PaginatedResponse<StockIssueModel>> stockIssues({
    Map<String, dynamic>? filters,
  }) => paginated<StockIssueModel>(
    ApiEndpoints.stockIssues,
    filters: filters,
    fromJson: StockIssueModel.fromJson,
  );
  Future<ApiResponse<StockIssueModel>> stockIssue(int id) =>
      object<StockIssueModel>(
        '${ApiEndpoints.stockIssues}/$id',
        fromJson: StockIssueModel.fromJson,
      );
  Future<ApiResponse<StockIssueModel>> createStockIssue(StockIssueModel body) =>
      createModel<StockIssueModel>(
        ApiEndpoints.stockIssues,
        body,
        fromJson: StockIssueModel.fromJson,
      );
  Future<ApiResponse<StockIssueModel>> updateStockIssue(
    int id,
    StockIssueModel body,
  ) => updateModel<StockIssueModel>(
    '${ApiEndpoints.stockIssues}/$id',
    body,
    fromJson: StockIssueModel.fromJson,
  );
  Future<ApiResponse<StockIssueModel>> postStockIssue(
    int id,
    StockIssueModel body,
  ) => actionModel<StockIssueModel>(
    '${ApiEndpoints.stockIssues}/$id/post',
    body: body,
    fromJson: StockIssueModel.fromJson,
  );
  Future<ApiResponse<StockIssueModel>> cancelStockIssue(
    int id,
    StockIssueModel body,
  ) => actionModel<StockIssueModel>(
    '${ApiEndpoints.stockIssues}/$id/cancel',
    body: body,
    fromJson: StockIssueModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteStockIssue(int id) =>
      destroy('${ApiEndpoints.stockIssues}/$id');

  Future<PaginatedResponse<InternalStockReceiptModel>> internalStockReceipts({
    Map<String, dynamic>? filters,
  }) => paginated<InternalStockReceiptModel>(
    ApiEndpoints.internalStockReceipts,
    filters: filters,
    fromJson: InternalStockReceiptModel.fromJson,
  );
  Future<ApiResponse<InternalStockReceiptModel>> internalStockReceipt(int id) =>
      object<InternalStockReceiptModel>(
        '${ApiEndpoints.internalStockReceipts}/$id',
        fromJson: InternalStockReceiptModel.fromJson,
      );
  Future<ApiResponse<InternalStockReceiptModel>> createInternalStockReceipt(
    InternalStockReceiptModel body,
  ) => createModel<InternalStockReceiptModel>(
    ApiEndpoints.internalStockReceipts,
    body,
    fromJson: InternalStockReceiptModel.fromJson,
  );
  Future<ApiResponse<InternalStockReceiptModel>> updateInternalStockReceipt(
    int id,
    InternalStockReceiptModel body,
  ) => updateModel<InternalStockReceiptModel>(
    '${ApiEndpoints.internalStockReceipts}/$id',
    body,
    fromJson: InternalStockReceiptModel.fromJson,
  );
  Future<ApiResponse<InternalStockReceiptModel>> postInternalStockReceipt(
    int id,
    InternalStockReceiptModel body,
  ) => actionModel<InternalStockReceiptModel>(
    '${ApiEndpoints.internalStockReceipts}/$id/post',
    body: body,
    fromJson: InternalStockReceiptModel.fromJson,
  );
  Future<ApiResponse<InternalStockReceiptModel>> cancelInternalStockReceipt(
    int id,
    InternalStockReceiptModel body,
  ) => actionModel<InternalStockReceiptModel>(
    '${ApiEndpoints.internalStockReceipts}/$id/cancel',
    body: body,
    fromJson: InternalStockReceiptModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteInternalStockReceipt(int id) =>
      destroy('${ApiEndpoints.internalStockReceipts}/$id');

  Future<PaginatedResponse<StockDamageEntryModel>> stockDamageEntries({
    Map<String, dynamic>? filters,
  }) => paginated<StockDamageEntryModel>(
    ApiEndpoints.stockDamageEntries,
    filters: filters,
    fromJson: StockDamageEntryModel.fromJson,
  );
  Future<ApiResponse<StockDamageEntryModel>> stockDamageEntry(int id) =>
      object<StockDamageEntryModel>(
        '${ApiEndpoints.stockDamageEntries}/$id',
        fromJson: StockDamageEntryModel.fromJson,
      );
  Future<ApiResponse<StockDamageEntryModel>> createStockDamageEntry(
    StockDamageEntryModel body,
  ) => createModel<StockDamageEntryModel>(
    ApiEndpoints.stockDamageEntries,
    body,
    fromJson: StockDamageEntryModel.fromJson,
  );
  Future<ApiResponse<StockDamageEntryModel>> updateStockDamageEntry(
    int id,
    StockDamageEntryModel body,
  ) => updateModel<StockDamageEntryModel>(
    '${ApiEndpoints.stockDamageEntries}/$id',
    body,
    fromJson: StockDamageEntryModel.fromJson,
  );
  Future<ApiResponse<StockDamageEntryModel>> postStockDamageEntry(
    int id,
    StockDamageEntryModel body,
  ) => actionModel<StockDamageEntryModel>(
    '${ApiEndpoints.stockDamageEntries}/$id/post',
    body: body,
    fromJson: StockDamageEntryModel.fromJson,
  );
  Future<ApiResponse<StockDamageEntryModel>> cancelStockDamageEntry(
    int id,
    StockDamageEntryModel body,
  ) => actionModel<StockDamageEntryModel>(
    '${ApiEndpoints.stockDamageEntries}/$id/cancel',
    body: body,
    fromJson: StockDamageEntryModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteStockDamageEntry(int id) =>
      destroy('${ApiEndpoints.stockDamageEntries}/$id');

  Future<PaginatedResponse<PhysicalStockCountModel>> physicalStockCounts({
    Map<String, dynamic>? filters,
  }) => paginated<PhysicalStockCountModel>(
    ApiEndpoints.physicalStockCounts,
    filters: filters,
    fromJson: PhysicalStockCountModel.fromJson,
  );
  Future<ApiResponse<PhysicalStockCountModel>> physicalStockCount(int id) =>
      object<PhysicalStockCountModel>(
        '${ApiEndpoints.physicalStockCounts}/$id',
        fromJson: PhysicalStockCountModel.fromJson,
      );
  Future<ApiResponse<PhysicalStockCountModel>> createPhysicalStockCount(
    PhysicalStockCountModel body,
  ) => createModel<PhysicalStockCountModel>(
    ApiEndpoints.physicalStockCounts,
    body,
    fromJson: PhysicalStockCountModel.fromJson,
  );
  Future<ApiResponse<PhysicalStockCountModel>> updatePhysicalStockCount(
    int id,
    PhysicalStockCountModel body,
  ) => updateModel<PhysicalStockCountModel>(
    '${ApiEndpoints.physicalStockCounts}/$id',
    body,
    fromJson: PhysicalStockCountModel.fromJson,
  );
  Future<ApiResponse<PhysicalStockCountModel>> markPhysicalCounted(
    int id,
    PhysicalStockCountModel body,
  ) => actionModel<PhysicalStockCountModel>(
    '${ApiEndpoints.physicalStockCounts}/$id/counted',
    body: body,
    fromJson: PhysicalStockCountModel.fromJson,
  );
  Future<ApiResponse<PhysicalStockCountModel>> reconcilePhysicalStockCount(
    int id,
    PhysicalStockCountModel body,
  ) => actionModel<PhysicalStockCountModel>(
    '${ApiEndpoints.physicalStockCounts}/$id/reconcile',
    body: body,
    fromJson: PhysicalStockCountModel.fromJson,
  );
  Future<ApiResponse<PhysicalStockCountModel>> cancelPhysicalStockCount(
    int id,
    PhysicalStockCountModel body,
  ) => actionModel<PhysicalStockCountModel>(
    '${ApiEndpoints.physicalStockCounts}/$id/cancel',
    body: body,
    fromJson: PhysicalStockCountModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deletePhysicalStockCount(int id) =>
      destroy('${ApiEndpoints.physicalStockCounts}/$id');

  Future<ApiResponse<dynamic>> inquiryItemStockSummary({
    required int itemId,
    int? companyId,
  }) => client.get<dynamic>(
    ApiEndpoints.inquiryStockSummary,
    queryParameters: <String, dynamic>{
      'item_id': itemId,
      if (companyId != null) 'company_id': companyId,
    },
    fromData: (dynamic json) => json,
  );

  Future<ApiResponse<dynamic>> inquiryWarehouseWiseStock({
    required int itemId,
    int? companyId,
  }) => client.get<dynamic>(
    ApiEndpoints.inquiryWarehouseWiseStock,
    queryParameters: <String, dynamic>{
      'item_id': itemId,
      if (companyId != null) 'company_id': companyId,
    },
    fromData: (dynamic json) => json,
  );

  Future<ApiResponse<dynamic>> inquiryBatchWiseStock({
    required int itemId,
    int? companyId,
    int? warehouseId,
  }) => client.get<dynamic>(
    ApiEndpoints.inquiryBatchWiseStock,
    queryParameters: <String, dynamic>{
      'item_id': itemId,
      if (companyId != null) 'company_id': companyId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
    },
    fromData: (dynamic json) => json,
  );

  Future<ApiResponse<dynamic>> inquiryAvailableSerials({
    required int itemId,
    int? warehouseId,
    int? batchId,
  }) => client.get<dynamic>(
    ApiEndpoints.inquiryAvailableSerials,
    queryParameters: <String, dynamic>{
      'item_id': itemId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (batchId != null) 'batch_id': batchId,
    },
    fromData: (dynamic json) => json,
  );

  Future<ApiResponse<dynamic>> inquiryStockCard({
    required int itemId,
    int? companyId,
  }) => client.get<dynamic>(
    ApiEndpoints.inquiryStockCard,
    queryParameters: <String, dynamic>{
      'item_id': itemId,
      if (companyId != null) 'company_id': companyId,
    },
    fromData: (dynamic json) => json,
  );

  Future<ApiResponse<dynamic>> inquiryReorderStatus({
    required int itemId,
    int? companyId,
  }) => client.get<dynamic>(
    ApiEndpoints.inquiryReorderStatus,
    queryParameters: <String, dynamic>{
      'item_id': itemId,
      if (companyId != null) 'company_id': companyId,
    },
    fromData: (dynamic json) => json,
  );
}
