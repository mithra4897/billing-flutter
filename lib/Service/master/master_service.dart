import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/masters/branch_model.dart';
import '../../model/masters/brand_model.dart';
import '../../model/masters/business_location_model.dart';
import '../../model/masters/company_model.dart';
import '../../model/masters/document_series_model.dart';
import '../../model/masters/financial_year_model.dart';
import '../../model/masters/item_category_model.dart';
import '../../model/masters/item_model.dart';
import '../../model/masters/party_model.dart';
import '../../model/masters/tax_code_model.dart';
import '../../model/masters/uom_model.dart';
import '../../model/masters/warehouse_model.dart';
import '../../model/common/erp_record_model.dart';
import '../base/erp_module_service.dart';

class MasterService extends ErpModuleService {
  MasterService({super.apiClient});

  Future<PaginatedResponse<CompanyModel>> companies({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<CompanyModel>(
      ApiEndpoints.companies,
      queryParameters: filters,
      itemFromJson: CompanyModel.fromJson,
    );
  }

  Future<ApiResponse<CompanyModel>> company(int id) {
    return client.get<CompanyModel>(
      '${ApiEndpoints.companies}/$id',
      fromData: (json) => CompanyModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<ErpRecordModel>> createCompany(ErpRecordModel body) =>
      store('/masters/companies', body);
  Future<ApiResponse<ErpRecordModel>> updateCompany(
    int id,
    ErpRecordModel body,
  ) => update('/masters/companies/$id', body);
  Future<ApiResponse<ErpRecordModel>> changeCompanyStatus(
    int id,
    ErpRecordModel body,
  ) => patch('/masters/companies/$id/status', body);

  Future<PaginatedResponse<BranchModel>> branches({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<BranchModel>(
      ApiEndpoints.branches,
      queryParameters: filters,
      itemFromJson: BranchModel.fromJson,
    );
  }

  Future<ApiResponse<ErpRecordModel>> branch(int id) =>
      show('/masters/branches/$id');
  Future<ApiResponse<ErpRecordModel>> createBranch(ErpRecordModel body) =>
      store('/masters/branches', body);
  Future<ApiResponse<ErpRecordModel>> updateBranch(
    int id,
    ErpRecordModel body,
  ) => update('/masters/branches/$id', body);

  Future<PaginatedResponse<BusinessLocationModel>> businessLocations({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<BusinessLocationModel>(
      ApiEndpoints.businessLocations,
      queryParameters: filters,
      itemFromJson: BusinessLocationModel.fromJson,
    );
  }

  Future<ApiResponse<ErpRecordModel>> businessLocation(int id) =>
      show('/masters/business-locations/$id');
  Future<ApiResponse<ErpRecordModel>> createBusinessLocation(
    ErpRecordModel body,
  ) => store('/masters/business-locations', body);
  Future<ApiResponse<ErpRecordModel>> updateBusinessLocation(
    int id,
    ErpRecordModel body,
  ) => update('/masters/business-locations/$id', body);

  Future<PaginatedResponse<WarehouseModel>> warehouses({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<WarehouseModel>(
      ApiEndpoints.warehouses,
      queryParameters: filters,
      itemFromJson: WarehouseModel.fromJson,
    );
  }

  Future<ApiResponse<ErpRecordModel>> warehouse(int id) =>
      show('/masters/warehouses/$id');
  Future<ApiResponse<ErpRecordModel>> createWarehouse(ErpRecordModel body) =>
      store('/masters/warehouses', body);
  Future<ApiResponse<ErpRecordModel>> updateWarehouse(
    int id,
    ErpRecordModel body,
  ) => update('/masters/warehouses/$id', body);
  Future<ApiResponse<dynamic>> deleteWarehouse(int id) =>
      destroy('/masters/warehouses/$id');

  Future<PaginatedResponse<FinancialYearModel>> financialYears({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<FinancialYearModel>(
      ApiEndpoints.financialYears,
      queryParameters: filters,
      itemFromJson: FinancialYearModel.fromJson,
    );
  }

  Future<ApiResponse<ErpRecordModel>> financialYear(int id) =>
      show('/masters/financial-years/$id');
  Future<ApiResponse<ErpRecordModel>> createFinancialYear(
    ErpRecordModel body,
  ) => store('/masters/financial-years', body);
  Future<ApiResponse<ErpRecordModel>> updateFinancialYear(
    int id,
    ErpRecordModel body,
  ) => update('/masters/financial-years/$id', body);
  Future<ApiResponse<ErpRecordModel>> setActiveFinancialYear(
    int id,
    ErpRecordModel body,
  ) => patch('/masters/financial-years/$id/set-active', body);

  Future<PaginatedResponse<DocumentSeriesModel>> documentSeries({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<DocumentSeriesModel>(
      ApiEndpoints.documentSeries,
      queryParameters: filters,
      itemFromJson: DocumentSeriesModel.fromJson,
    );
  }

  Future<ApiResponse<ErpRecordModel>> documentSeriesItem(int id) =>
      show('/masters/document-series/$id');
  Future<ApiResponse<ErpRecordModel>> createDocumentSeries(
    ErpRecordModel body,
  ) => store('/masters/document-series', body);
  Future<ApiResponse<ErpRecordModel>> updateDocumentSeries(
    int id,
    ErpRecordModel body,
  ) => update('/masters/document-series/$id', body);

  Future<PaginatedResponse<UomModel>> uoms({Map<String, dynamic>? filters}) {
    return client.getPaginated<UomModel>(
      ApiEndpoints.uoms,
      queryParameters: filters,
      itemFromJson: UomModel.fromJson,
    );
  }

  Future<ApiResponse<ErpRecordModel>> uom(int id) => show('/masters/uoms/$id');
  Future<ApiResponse<ErpRecordModel>> createUom(ErpRecordModel body) =>
      store('/masters/uoms', body);
  Future<ApiResponse<ErpRecordModel>> updateUom(int id, ErpRecordModel body) =>
      update('/masters/uoms/$id', body);

  Future<PaginatedResponse<TaxCodeModel>> taxCodes({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<TaxCodeModel>(
      ApiEndpoints.taxCodes,
      queryParameters: filters,
      itemFromJson: TaxCodeModel.fromJson,
    );
  }

  Future<ApiResponse<ErpRecordModel>> taxCode(int id) =>
      show('/masters/tax-codes/$id');
  Future<ApiResponse<ErpRecordModel>> createTaxCode(ErpRecordModel body) =>
      store('/masters/tax-codes', body);
  Future<ApiResponse<ErpRecordModel>> updateTaxCode(
    int id,
    ErpRecordModel body,
  ) => update('/masters/tax-codes/$id', body);

  Future<PaginatedResponse<ItemCategoryModel>> itemCategories({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<ItemCategoryModel>(
      ApiEndpoints.itemCategories,
      queryParameters: filters,
      itemFromJson: ItemCategoryModel.fromJson,
    );
  }

  Future<ApiResponse<ErpRecordModel>> itemCategory(int id) =>
      show('/masters/item-categories/$id');
  Future<ApiResponse<ErpRecordModel>> createItemCategory(ErpRecordModel body) =>
      store('/masters/item-categories', body);
  Future<ApiResponse<ErpRecordModel>> updateItemCategory(
    int id,
    ErpRecordModel body,
  ) => update('/masters/item-categories/$id', body);

  Future<PaginatedResponse<ItemModel>> items({Map<String, dynamic>? filters}) {
    return client.getPaginated<ItemModel>(
      ApiEndpoints.items,
      queryParameters: filters,
      itemFromJson: ItemModel.fromJson,
    );
  }

  Future<ApiResponse<ErpRecordModel>> item(int id) =>
      show('/masters/items/$id');
  Future<ApiResponse<ErpRecordModel>> createItem(ErpRecordModel body) =>
      store('/masters/items', body);
  Future<ApiResponse<ErpRecordModel>> updateItem(int id, ErpRecordModel body) =>
      update('/masters/items/$id', body);
  Future<ApiResponse<ErpRecordModel>> toggleItemStatus(
    int id,
    ErpRecordModel body,
  ) => patch('/masters/items/$id/toggle-status', body);

  Future<PaginatedResponse<PartyModel>> parties({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<PartyModel>(
      ApiEndpoints.parties,
      queryParameters: filters,
      itemFromJson: PartyModel.fromJson,
    );
  }

  Future<PaginatedResponse<BrandModel>> brands({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<BrandModel>(
      ApiEndpoints.brands,
      queryParameters: filters,
      itemFromJson: BrandModel.fromJson,
    );
  }
}
