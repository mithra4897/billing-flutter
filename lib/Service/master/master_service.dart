import '../../core/api/api_endpoints.dart';
import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/masters/branch_model.dart';
import '../../model/masters/brand_model.dart';
import '../../model/masters/business_location_model.dart';
import '../../model/masters/company_model.dart';
import '../../model/masters/document_series_model.dart';
import '../../model/masters/financial_year_model.dart';
import '../../model/masters/party_model.dart';
import '../../model/masters/warehouse_model.dart';
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

  Future<ApiResponse<CompanyModel>> createCompany(CompanyModel body) =>
      createModel<CompanyModel>(
        '/masters/companies',
        body,
        fromJson: CompanyModel.fromJson,
      );

  Future<String?> nextCompanyCode({String prefix = 'CMP'}) async {
    final response = await client.get<Map<String, dynamic>>(
      '/masters/companies/next-code',
      queryParameters: <String, dynamic>{'prefix': prefix},
      fromData: (json) =>
          (json as Map<String, dynamic>?) ?? <String, dynamic>{},
    );

    return response.data?['code']?.toString();
  }

  Future<ApiResponse<CompanyModel>> updateCompany(int id, CompanyModel body) =>
      updateModel<CompanyModel>(
        '/masters/companies/$id',
        body,
        fromJson: CompanyModel.fromJson,
      );

  Future<ApiResponse<CompanyModel>> changeCompanyStatus(
    int id,
    CompanyModel body,
  ) => patchModel<CompanyModel>(
    '/masters/companies/$id/status',
    body,
    fromJson: CompanyModel.fromJson,
  );

  Future<PaginatedResponse<BranchModel>> branches({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<BranchModel>(
      ApiEndpoints.branches,
      queryParameters: filters,
      itemFromJson: BranchModel.fromJson,
    );
  }

  Future<ApiResponse<BranchModel>> branch(int id) => object<BranchModel>(
    '/masters/branches/$id',
    fromJson: BranchModel.fromJson,
  );

  Future<ApiResponse<BranchModel>> createBranch(BranchModel body) =>
      createModel<BranchModel>(
        '/masters/branches',
        body,
        fromJson: BranchModel.fromJson,
      );

  Future<String?> nextBranchCode({
    required int companyId,
    required String branchType,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/masters/branches/next-code',
      queryParameters: <String, dynamic>{
        'company_id': companyId,
        'branch_type': branchType,
      },
      fromData: (json) =>
          (json as Map<String, dynamic>?) ?? <String, dynamic>{},
    );

    return response.data?['code']?.toString();
  }

  Future<ApiResponse<BranchModel>> updateBranch(int id, BranchModel body) =>
      updateModel<BranchModel>(
        '/masters/branches/$id',
        body,
        fromJson: BranchModel.fromJson,
      );

  Future<PaginatedResponse<BusinessLocationModel>> businessLocations({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<BusinessLocationModel>(
      ApiEndpoints.businessLocations,
      queryParameters: filters,
      itemFromJson: BusinessLocationModel.fromJson,
    );
  }

  Future<ApiResponse<BusinessLocationModel>> businessLocation(int id) =>
      object<BusinessLocationModel>(
        '/masters/business-locations/$id',
        fromJson: BusinessLocationModel.fromJson,
      );

  Future<ApiResponse<BusinessLocationModel>> createBusinessLocation(
    BusinessLocationModel body,
  ) => createModel<BusinessLocationModel>(
    '/masters/business-locations',
    body,
    fromJson: BusinessLocationModel.fromJson,
  );

  Future<String?> nextBusinessLocationCode({required int branchId}) async {
    final response = await client.get<Map<String, dynamic>>(
      '/masters/business-locations/next-code',
      queryParameters: <String, dynamic>{'branch_id': branchId},
      fromData: (json) =>
          (json as Map<String, dynamic>?) ?? <String, dynamic>{},
    );

    return response.data?['code']?.toString();
  }

  Future<ApiResponse<BusinessLocationModel>> updateBusinessLocation(
    int id,
    BusinessLocationModel body,
  ) => updateModel<BusinessLocationModel>(
    '/masters/business-locations/$id',
    body,
    fromJson: BusinessLocationModel.fromJson,
  );

  Future<PaginatedResponse<WarehouseModel>> warehouses({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<WarehouseModel>(
      ApiEndpoints.warehouses,
      queryParameters: filters,
      itemFromJson: WarehouseModel.fromJson,
    );
  }

  Future<ApiResponse<WarehouseModel>> warehouse(int id) =>
      object<WarehouseModel>(
        '/masters/warehouses/$id',
        fromJson: WarehouseModel.fromJson,
      );

  Future<ApiResponse<WarehouseModel>> createWarehouse(WarehouseModel body) =>
      createModel<WarehouseModel>(
        '/masters/warehouses',
        body,
        fromJson: WarehouseModel.fromJson,
      );

  Future<String?> nextWarehouseCode({
    required int locationId,
    required String warehouseType,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/masters/warehouses/next-code',
      queryParameters: <String, dynamic>{
        'location_id': locationId,
        'warehouse_type': warehouseType,
      },
      fromData: (json) =>
          (json as Map<String, dynamic>?) ?? <String, dynamic>{},
    );

    return response.data?['code']?.toString();
  }

  Future<ApiResponse<WarehouseModel>> updateWarehouse(
    int id,
    WarehouseModel body,
  ) => updateModel<WarehouseModel>(
    '/masters/warehouses/$id',
    body,
    fromJson: WarehouseModel.fromJson,
  );

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

  Future<ApiResponse<FinancialYearModel>> financialYear(int id) =>
      object<FinancialYearModel>(
        '/masters/financial-years/$id',
        fromJson: FinancialYearModel.fromJson,
      );

  Future<ApiResponse<FinancialYearModel>> createFinancialYear(
    FinancialYearModel body,
  ) => createModel<FinancialYearModel>(
    '/masters/financial-years',
    body,
    fromJson: FinancialYearModel.fromJson,
  );

  Future<ApiResponse<FinancialYearModel>> updateFinancialYear(
    int id,
    FinancialYearModel body,
  ) => updateModel<FinancialYearModel>(
    '/masters/financial-years/$id',
    body,
    fromJson: FinancialYearModel.fromJson,
  );

  Future<ApiResponse<FinancialYearModel>> setActiveFinancialYear(
    int id,
    FinancialYearModel body,
  ) => patchModel<FinancialYearModel>(
    '/masters/financial-years/$id/set-active',
    body,
    fromJson: FinancialYearModel.fromJson,
  );

  Future<PaginatedResponse<DocumentSeriesModel>> documentSeries({
    Map<String, dynamic>? filters,
  }) {
    return client.getPaginated<DocumentSeriesModel>(
      ApiEndpoints.documentSeries,
      queryParameters: filters,
      itemFromJson: DocumentSeriesModel.fromJson,
    );
  }

  Future<ApiResponse<DocumentSeriesModel>> documentSeriesItem(int id) =>
      object<DocumentSeriesModel>(
        '/masters/document-series/$id',
        fromJson: DocumentSeriesModel.fromJson,
      );

  Future<ApiResponse<DocumentSeriesModel>> createDocumentSeries(
    DocumentSeriesModel body,
  ) => createModel<DocumentSeriesModel>(
    '/masters/document-series',
    body,
    fromJson: DocumentSeriesModel.fromJson,
  );

  Future<ApiResponse<DocumentSeriesModel>> updateDocumentSeries(
    int id,
    DocumentSeriesModel body,
  ) => updateModel<DocumentSeriesModel>(
    '/masters/document-series/$id',
    body,
    fromJson: DocumentSeriesModel.fromJson,
  );

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
