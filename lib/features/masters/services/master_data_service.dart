import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/paginated_response.dart';
import '../models/branch_model.dart';
import '../models/brand_model.dart';
import '../models/business_location_model.dart';
import '../models/company_model.dart';
import '../models/document_series_model.dart';
import '../models/financial_year_model.dart';
import '../models/item_category_model.dart';
import '../models/item_model.dart';
import '../models/party_model.dart';
import '../models/tax_code_model.dart';
import '../models/uom_model.dart';
import '../models/warehouse_model.dart';

class MasterDataService {
  MasterDataService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PaginatedResponse<CompanyModel>> getCompanies({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<CompanyModel>(
      ApiEndpoints.companies,
      queryParameters: filters,
      itemFromJson: CompanyModel.fromJson,
    );
  }

  Future<ApiResponse<CompanyModel>> getCompany(int id) {
    return _apiClient.get<CompanyModel>(
      '${ApiEndpoints.companies}/$id',
      fromData: (json) => CompanyModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<PaginatedResponse<BranchModel>> getBranches({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<BranchModel>(
      ApiEndpoints.branches,
      queryParameters: filters,
      itemFromJson: BranchModel.fromJson,
    );
  }

  Future<PaginatedResponse<BusinessLocationModel>> getBusinessLocations({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<BusinessLocationModel>(
      ApiEndpoints.businessLocations,
      queryParameters: filters,
      itemFromJson: BusinessLocationModel.fromJson,
    );
  }

  Future<PaginatedResponse<WarehouseModel>> getWarehouses({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<WarehouseModel>(
      ApiEndpoints.warehouses,
      queryParameters: filters,
      itemFromJson: WarehouseModel.fromJson,
    );
  }

  Future<PaginatedResponse<FinancialYearModel>> getFinancialYears({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<FinancialYearModel>(
      ApiEndpoints.financialYears,
      queryParameters: filters,
      itemFromJson: FinancialYearModel.fromJson,
    );
  }

  Future<PaginatedResponse<DocumentSeriesModel>> getDocumentSeries({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<DocumentSeriesModel>(
      ApiEndpoints.documentSeries,
      queryParameters: filters,
      itemFromJson: DocumentSeriesModel.fromJson,
    );
  }

  Future<PaginatedResponse<PartyModel>> getParties({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<PartyModel>(
      ApiEndpoints.parties,
      queryParameters: filters,
      itemFromJson: PartyModel.fromJson,
    );
  }

  Future<PaginatedResponse<ItemCategoryModel>> getItemCategories({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<ItemCategoryModel>(
      ApiEndpoints.itemCategories,
      queryParameters: filters,
      itemFromJson: ItemCategoryModel.fromJson,
    );
  }

  Future<PaginatedResponse<ItemModel>> getItems({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<ItemModel>(
      ApiEndpoints.items,
      queryParameters: filters,
      itemFromJson: ItemModel.fromJson,
    );
  }

  Future<PaginatedResponse<TaxCodeModel>> getTaxCodes({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<TaxCodeModel>(
      ApiEndpoints.taxCodes,
      queryParameters: filters,
      itemFromJson: TaxCodeModel.fromJson,
    );
  }

  Future<PaginatedResponse<UomModel>> getUoms({Map<String, dynamic>? filters}) {
    return _apiClient.getPaginated<UomModel>(
      ApiEndpoints.uoms,
      queryParameters: filters,
      itemFromJson: UomModel.fromJson,
    );
  }

  Future<PaginatedResponse<BrandModel>> getBrands({
    Map<String, dynamic>? filters,
  }) {
    return _apiClient.getPaginated<BrandModel>(
      ApiEndpoints.brands,
      queryParameters: filters,
      itemFromJson: BrandModel.fromJson,
    );
  }
}
