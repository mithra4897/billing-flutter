import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/assets/asset_book_model.dart';
import '../../model/assets/asset_category_model.dart';
import '../../model/assets/asset_depreciation_run_model.dart';
import '../../model/assets/asset_disposal_model.dart';
import '../../model/assets/asset_model.dart';
import '../../model/assets/asset_transfer_model.dart';
import '../../model/assets/cost_center_model.dart';
import '../base/erp_module_service.dart';

class AssetsService extends ErpModuleService {
  AssetsService({super.apiClient});

  Future<PaginatedResponse<AssetCategoryModel>> categories({
    Map<String, dynamic>? filters,
  }) => paginated<AssetCategoryModel>(
    '/assets/categories',
    filters: filters,
    fromJson: AssetCategoryModel.fromJson,
  );
  Future<ApiResponse<AssetCategoryModel>> category(int id) =>
      object<AssetCategoryModel>(
        '/assets/categories/$id',
        fromJson: AssetCategoryModel.fromJson,
      );
  Future<ApiResponse<AssetCategoryModel>> createCategory(
    AssetCategoryModel body,
  ) => createModel<AssetCategoryModel>(
    '/assets/categories',
    body,
    fromJson: AssetCategoryModel.fromJson,
  );
  Future<ApiResponse<AssetCategoryModel>> updateCategory(
    int id,
    AssetCategoryModel body,
  ) => updateModel<AssetCategoryModel>(
    '/assets/categories/$id',
    body,
    fromJson: AssetCategoryModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteCategory(int id) =>
      destroy('/assets/categories/$id');

  Future<PaginatedResponse<CostCenterModel>> costCenters({
    Map<String, dynamic>? filters,
  }) => paginated<CostCenterModel>(
    '/assets/cost-centers',
    filters: filters,
    fromJson: CostCenterModel.fromJson,
  );
  Future<ApiResponse<CostCenterModel>> costCenter(int id) =>
      object<CostCenterModel>(
        '/assets/cost-centers/$id',
        fromJson: CostCenterModel.fromJson,
      );
  Future<ApiResponse<CostCenterModel>> createCostCenter(CostCenterModel body) =>
      createModel<CostCenterModel>(
        '/assets/cost-centers',
        body,
        fromJson: CostCenterModel.fromJson,
      );
  Future<ApiResponse<CostCenterModel>> updateCostCenter(
    int id,
    CostCenterModel body,
  ) => updateModel<CostCenterModel>(
    '/assets/cost-centers/$id',
    body,
    fromJson: CostCenterModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteCostCenter(int id) =>
      destroy('/assets/cost-centers/$id');

  Future<PaginatedResponse<AssetModel>> assets({
    Map<String, dynamic>? filters,
  }) => paginated<AssetModel>(
    '/assets/register',
    filters: filters,
    fromJson: AssetModel.fromJson,
  );
  Future<ApiResponse<AssetModel>> asset(int id) =>
      object<AssetModel>('/assets/register/$id', fromJson: AssetModel.fromJson);
  Future<ApiResponse<AssetModel>> createAsset(AssetModel body) =>
      createModel<AssetModel>(
        '/assets/register',
        body,
        fromJson: AssetModel.fromJson,
      );
  Future<ApiResponse<AssetModel>> updateAsset(int id, AssetModel body) =>
      updateModel<AssetModel>(
        '/assets/register/$id',
        body,
        fromJson: AssetModel.fromJson,
      );
  Future<ApiResponse<AssetModel>> activateAsset(int id, AssetModel body) =>
      actionModel<AssetModel>(
        '/assets/register/$id/activate',
        body: body,
        fromJson: AssetModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteAsset(int id) =>
      destroy('/assets/register/$id');

  Future<PaginatedResponse<AssetBookModel>> assetBooks(
    int assetId, {
    Map<String, dynamic>? filters,
  }) => paginated<AssetBookModel>(
    '/assets/register/$assetId/books',
    filters: filters,
    fromJson: AssetBookModel.fromJson,
  );
  Future<ApiResponse<AssetBookModel>> assetBook(int assetId, int id) =>
      object<AssetBookModel>(
        '/assets/register/$assetId/books/$id',
        fromJson: AssetBookModel.fromJson,
      );
  Future<ApiResponse<AssetBookModel>> createAssetBook(
    int assetId,
    AssetBookModel body,
  ) => createModel<AssetBookModel>(
    '/assets/register/$assetId/books',
    body,
    fromJson: AssetBookModel.fromJson,
  );
  Future<ApiResponse<AssetBookModel>> updateAssetBook(
    int assetId,
    int id,
    AssetBookModel body,
  ) => updateModel<AssetBookModel>(
    '/assets/register/$assetId/books/$id',
    body,
    fromJson: AssetBookModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteAssetBook(int assetId, int id) =>
      destroy('/assets/register/$assetId/books/$id');

  Future<PaginatedResponse<AssetDepreciationRunModel>> depreciationRuns({
    Map<String, dynamic>? filters,
  }) => paginated<AssetDepreciationRunModel>(
    '/assets/depreciation-runs',
    filters: filters,
    fromJson: AssetDepreciationRunModel.fromJson,
  );
  Future<ApiResponse<AssetDepreciationRunModel>> depreciationRun(int id) =>
      object<AssetDepreciationRunModel>(
        '/assets/depreciation-runs/$id',
        fromJson: AssetDepreciationRunModel.fromJson,
      );
  Future<ApiResponse<AssetDepreciationRunModel>> createDepreciationRun(
    AssetDepreciationRunModel body,
  ) => createModel<AssetDepreciationRunModel>(
    '/assets/depreciation-runs',
    body,
    fromJson: AssetDepreciationRunModel.fromJson,
  );
  Future<ApiResponse<AssetDepreciationRunModel>> updateDepreciationRun(
    int id,
    AssetDepreciationRunModel body,
  ) => updateModel<AssetDepreciationRunModel>(
    '/assets/depreciation-runs/$id',
    body,
    fromJson: AssetDepreciationRunModel.fromJson,
  );
  Future<ApiResponse<AssetDepreciationRunModel>> processDepreciationRun(
    int id,
    AssetDepreciationRunModel body,
  ) => actionModel<AssetDepreciationRunModel>(
    '/assets/depreciation-runs/$id/process',
    body: body,
    fromJson: AssetDepreciationRunModel.fromJson,
  );
  Future<ApiResponse<AssetDepreciationRunModel>> postDepreciationRun(
    int id,
    AssetDepreciationRunModel body,
  ) => actionModel<AssetDepreciationRunModel>(
    '/assets/depreciation-runs/$id/post',
    body: body,
    fromJson: AssetDepreciationRunModel.fromJson,
  );
  Future<ApiResponse<AssetDepreciationRunModel>> cancelDepreciationRun(
    int id,
    AssetDepreciationRunModel body,
  ) => actionModel<AssetDepreciationRunModel>(
    '/assets/depreciation-runs/$id/cancel',
    body: body,
    fromJson: AssetDepreciationRunModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteDepreciationRun(int id) =>
      destroy('/assets/depreciation-runs/$id');

  Future<PaginatedResponse<AssetTransferModel>> transfers({
    Map<String, dynamic>? filters,
  }) => paginated<AssetTransferModel>(
    '/assets/transfers',
    filters: filters,
    fromJson: AssetTransferModel.fromJson,
  );
  Future<ApiResponse<AssetTransferModel>> transfer(int id) =>
      object<AssetTransferModel>(
        '/assets/transfers/$id',
        fromJson: AssetTransferModel.fromJson,
      );
  Future<ApiResponse<AssetTransferModel>> createTransfer(
    AssetTransferModel body,
  ) => createModel<AssetTransferModel>(
    '/assets/transfers',
    body,
    fromJson: AssetTransferModel.fromJson,
  );
  Future<ApiResponse<AssetTransferModel>> updateTransfer(
    int id,
    AssetTransferModel body,
  ) => updateModel<AssetTransferModel>(
    '/assets/transfers/$id',
    body,
    fromJson: AssetTransferModel.fromJson,
  );
  Future<ApiResponse<AssetTransferModel>> approveTransfer(
    int id,
    AssetTransferModel body,
  ) => actionModel<AssetTransferModel>(
    '/assets/transfers/$id/approve',
    body: body,
    fromJson: AssetTransferModel.fromJson,
  );
  Future<ApiResponse<AssetTransferModel>> completeTransfer(
    int id,
    AssetTransferModel body,
  ) => actionModel<AssetTransferModel>(
    '/assets/transfers/$id/complete',
    body: body,
    fromJson: AssetTransferModel.fromJson,
  );
  Future<ApiResponse<AssetTransferModel>> cancelTransfer(
    int id,
    AssetTransferModel body,
  ) => actionModel<AssetTransferModel>(
    '/assets/transfers/$id/cancel',
    body: body,
    fromJson: AssetTransferModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteTransfer(int id) =>
      destroy('/assets/transfers/$id');

  Future<PaginatedResponse<AssetDisposalModel>> disposals({
    Map<String, dynamic>? filters,
  }) => paginated<AssetDisposalModel>(
    '/assets/disposals',
    filters: filters,
    fromJson: AssetDisposalModel.fromJson,
  );
  Future<ApiResponse<AssetDisposalModel>> disposal(int id) =>
      object<AssetDisposalModel>(
        '/assets/disposals/$id',
        fromJson: AssetDisposalModel.fromJson,
      );
  Future<ApiResponse<AssetDisposalModel>> createDisposal(
    AssetDisposalModel body,
  ) => createModel<AssetDisposalModel>(
    '/assets/disposals',
    body,
    fromJson: AssetDisposalModel.fromJson,
  );
  Future<ApiResponse<AssetDisposalModel>> updateDisposal(
    int id,
    AssetDisposalModel body,
  ) => updateModel<AssetDisposalModel>(
    '/assets/disposals/$id',
    body,
    fromJson: AssetDisposalModel.fromJson,
  );
  Future<ApiResponse<AssetDisposalModel>> approveDisposal(
    int id,
    AssetDisposalModel body,
  ) => actionModel<AssetDisposalModel>(
    '/assets/disposals/$id/approve',
    body: body,
    fromJson: AssetDisposalModel.fromJson,
  );
  Future<ApiResponse<AssetDisposalModel>> postDisposal(
    int id,
    AssetDisposalModel body,
  ) => actionModel<AssetDisposalModel>(
    '/assets/disposals/$id/post',
    body: body,
    fromJson: AssetDisposalModel.fromJson,
  );
  Future<ApiResponse<AssetDisposalModel>> cancelDisposal(
    int id,
    AssetDisposalModel body,
  ) => actionModel<AssetDisposalModel>(
    '/assets/disposals/$id/cancel',
    body: body,
    fromJson: AssetDisposalModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteDisposal(int id) =>
      destroy('/assets/disposals/$id');

  /// Finance reports return `{ lines: [...], ...totals }` in `data`, not pagination.
  Future<ApiResponse<Map<String, dynamic>>> fetchAssetRegisterReport({
    Map<String, dynamic>? filters,
  }) =>
      client.get<Map<String, dynamic>>(
        '/assets/reports/register',
        queryParameters: filters,
        fromData: (dynamic json) {
          if (json is Map<String, dynamic>) {
            return json;
          }
          if (json is Map) {
            return Map<String, dynamic>.from(json);
          }
          return <String, dynamic>{};
        },
      );

  Future<ApiResponse<Map<String, dynamic>>> fetchDepreciationSummaryReport({
    Map<String, dynamic>? filters,
  }) =>
      client.get<Map<String, dynamic>>(
        '/assets/reports/depreciation-summary',
        queryParameters: filters,
        fromData: (dynamic json) {
          if (json is Map<String, dynamic>) {
            return json;
          }
          if (json is Map) {
            return Map<String, dynamic>.from(json);
          }
          return <String, dynamic>{};
        },
      );

  Future<ApiResponse<Map<String, dynamic>>> fetchDisposalSummaryReport({
    Map<String, dynamic>? filters,
  }) =>
      client.get<Map<String, dynamic>>(
        '/assets/reports/disposal-summary',
        queryParameters: filters,
        fromData: (dynamic json) {
          if (json is Map<String, dynamic>) {
            return json;
          }
          if (json is Map) {
            return Map<String, dynamic>.from(json);
          }
          return <String, dynamic>{};
        },
      );
}
