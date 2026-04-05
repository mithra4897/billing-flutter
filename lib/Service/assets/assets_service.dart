import '../base/erp_module_service.dart';

class AssetsService extends ErpModuleService {
  AssetsService({super.apiClient});

  Future categories({Map<String, dynamic>? filters}) =>
      index('/assets/categories', filters: filters);
  Future category(int id) => show('/assets/categories/$id');
  Future createCategory(Map<String, dynamic> body) =>
      store('/assets/categories', body);
  Future updateCategory(int id, Map<String, dynamic> body) =>
      update('/assets/categories/$id', body);
  Future deleteCategory(int id) => destroy('/assets/categories/$id');

  Future costCenters({Map<String, dynamic>? filters}) =>
      index('/assets/cost-centers', filters: filters);
  Future costCenter(int id) => show('/assets/cost-centers/$id');
  Future createCostCenter(Map<String, dynamic> body) =>
      store('/assets/cost-centers', body);
  Future updateCostCenter(int id, Map<String, dynamic> body) =>
      update('/assets/cost-centers/$id', body);
  Future deleteCostCenter(int id) => destroy('/assets/cost-centers/$id');

  Future assets({Map<String, dynamic>? filters}) =>
      index('/assets', filters: filters);
  Future asset(int id) => show('/assets/$id');
  Future createAsset(Map<String, dynamic> body) => store('/assets', body);
  Future updateAsset(int id, Map<String, dynamic> body) =>
      update('/assets/$id', body);
  Future activateAsset(int id, Map<String, dynamic> body) =>
      action('/assets/$id/activate', body: body);
  Future deleteAsset(int id) => destroy('/assets/$id');

  Future assetBooks(int assetId, {Map<String, dynamic>? filters}) =>
      index('/assets/$assetId/books', filters: filters);
  Future assetBook(int assetId, int id) => show('/assets/$assetId/books/$id');
  Future createAssetBook(int assetId, Map<String, dynamic> body) =>
      store('/assets/$assetId/books', body);
  Future updateAssetBook(int assetId, int id, Map<String, dynamic> body) =>
      update('/assets/$assetId/books/$id', body);
  Future deleteAssetBook(int assetId, int id) =>
      destroy('/assets/$assetId/books/$id');

  Future depreciationRuns({Map<String, dynamic>? filters}) =>
      index('/assets/depreciation-runs', filters: filters);
  Future depreciationRun(int id) => show('/assets/depreciation-runs/$id');
  Future createDepreciationRun(Map<String, dynamic> body) =>
      store('/assets/depreciation-runs', body);
  Future updateDepreciationRun(int id, Map<String, dynamic> body) =>
      update('/assets/depreciation-runs/$id', body);
  Future processDepreciationRun(int id, Map<String, dynamic> body) =>
      action('/assets/depreciation-runs/$id/process', body: body);
  Future postDepreciationRun(int id, Map<String, dynamic> body) =>
      action('/assets/depreciation-runs/$id/post', body: body);
  Future cancelDepreciationRun(int id, Map<String, dynamic> body) =>
      action('/assets/depreciation-runs/$id/cancel', body: body);
  Future deleteDepreciationRun(int id) =>
      destroy('/assets/depreciation-runs/$id');

  Future transfers({Map<String, dynamic>? filters}) =>
      index('/assets/transfers', filters: filters);
  Future transfer(int id) => show('/assets/transfers/$id');
  Future createTransfer(Map<String, dynamic> body) =>
      store('/assets/transfers', body);
  Future updateTransfer(int id, Map<String, dynamic> body) =>
      update('/assets/transfers/$id', body);
  Future approveTransfer(int id, Map<String, dynamic> body) =>
      action('/assets/transfers/$id/approve', body: body);
  Future completeTransfer(int id, Map<String, dynamic> body) =>
      action('/assets/transfers/$id/complete', body: body);
  Future cancelTransfer(int id, Map<String, dynamic> body) =>
      action('/assets/transfers/$id/cancel', body: body);
  Future deleteTransfer(int id) => destroy('/assets/transfers/$id');

  Future disposals({Map<String, dynamic>? filters}) =>
      index('/assets/disposals', filters: filters);
  Future disposal(int id) => show('/assets/disposals/$id');
  Future createDisposal(Map<String, dynamic> body) =>
      store('/assets/disposals', body);
  Future updateDisposal(int id, Map<String, dynamic> body) =>
      update('/assets/disposals/$id', body);
  Future approveDisposal(int id, Map<String, dynamic> body) =>
      action('/assets/disposals/$id/approve', body: body);
  Future postDisposal(int id, Map<String, dynamic> body) =>
      action('/assets/disposals/$id/post', body: body);
  Future cancelDisposal(int id, Map<String, dynamic> body) =>
      action('/assets/disposals/$id/cancel', body: body);
  Future deleteDisposal(int id) => destroy('/assets/disposals/$id');

  Future reportRegister({Map<String, dynamic>? filters}) =>
      index('/assets/reports/register', filters: filters);
  Future reportDepreciationSummary({Map<String, dynamic>? filters}) =>
      index('/assets/reports/depreciation-summary', filters: filters);
  Future reportDisposalSummary({Map<String, dynamic>? filters}) =>
      index('/assets/reports/disposal-summary', filters: filters);
}
