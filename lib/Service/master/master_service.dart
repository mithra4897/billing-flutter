import '../../features/masters/services/master_data_service.dart';
import '../base/erp_module_service.dart';

class MasterService extends ErpModuleService {
  MasterService({super.apiClient})
    : _typed = MasterDataService(apiClient: apiClient);

  final MasterDataService _typed;

  Future companies({Map<String, dynamic>? filters}) =>
      _typed.getCompanies(filters: filters);
  Future company(int id) => _typed.getCompany(id);
  Future createCompany(Map<String, dynamic> body) =>
      store('/masters/companies', body);
  Future updateCompany(int id, Map<String, dynamic> body) =>
      update('/masters/companies/$id', body);
  Future changeCompanyStatus(int id, Map<String, dynamic> body) =>
      patch('/masters/companies/$id/status', body);

  Future branches({Map<String, dynamic>? filters}) =>
      _typed.getBranches(filters: filters);
  Future branch(int id) => show('/masters/branches/$id');
  Future createBranch(Map<String, dynamic> body) =>
      store('/masters/branches', body);
  Future updateBranch(int id, Map<String, dynamic> body) =>
      update('/masters/branches/$id', body);

  Future businessLocations({Map<String, dynamic>? filters}) =>
      _typed.getBusinessLocations(filters: filters);
  Future businessLocation(int id) => show('/masters/business-locations/$id');
  Future createBusinessLocation(Map<String, dynamic> body) =>
      store('/masters/business-locations', body);
  Future updateBusinessLocation(int id, Map<String, dynamic> body) =>
      update('/masters/business-locations/$id', body);

  Future warehouses({Map<String, dynamic>? filters}) =>
      _typed.getWarehouses(filters: filters);
  Future warehouse(int id) => show('/masters/warehouses/$id');
  Future createWarehouse(Map<String, dynamic> body) =>
      store('/masters/warehouses', body);
  Future updateWarehouse(int id, Map<String, dynamic> body) =>
      update('/masters/warehouses/$id', body);
  Future deleteWarehouse(int id) => destroy('/masters/warehouses/$id');

  Future financialYears({Map<String, dynamic>? filters}) =>
      _typed.getFinancialYears(filters: filters);
  Future financialYear(int id) => show('/masters/financial-years/$id');
  Future createFinancialYear(Map<String, dynamic> body) =>
      store('/masters/financial-years', body);
  Future updateFinancialYear(int id, Map<String, dynamic> body) =>
      update('/masters/financial-years/$id', body);
  Future setActiveFinancialYear(int id, Map<String, dynamic> body) =>
      patch('/masters/financial-years/$id/set-active', body);

  Future documentSeries({Map<String, dynamic>? filters}) =>
      _typed.getDocumentSeries(filters: filters);
  Future documentSeriesItem(int id) => show('/masters/document-series/$id');
  Future createDocumentSeries(Map<String, dynamic> body) =>
      store('/masters/document-series', body);
  Future updateDocumentSeries(int id, Map<String, dynamic> body) =>
      update('/masters/document-series/$id', body);

  Future uoms({Map<String, dynamic>? filters}) =>
      _typed.getUoms(filters: filters);
  Future uom(int id) => show('/masters/uoms/$id');
  Future createUom(Map<String, dynamic> body) => store('/masters/uoms', body);
  Future updateUom(int id, Map<String, dynamic> body) =>
      update('/masters/uoms/$id', body);

  Future taxCodes({Map<String, dynamic>? filters}) =>
      _typed.getTaxCodes(filters: filters);
  Future taxCode(int id) => show('/masters/tax-codes/$id');
  Future createTaxCode(Map<String, dynamic> body) =>
      store('/masters/tax-codes', body);
  Future updateTaxCode(int id, Map<String, dynamic> body) =>
      update('/masters/tax-codes/$id', body);

  Future itemCategories({Map<String, dynamic>? filters}) =>
      _typed.getItemCategories(filters: filters);
  Future itemCategory(int id) => show('/masters/item-categories/$id');
  Future createItemCategory(Map<String, dynamic> body) =>
      store('/masters/item-categories', body);
  Future updateItemCategory(int id, Map<String, dynamic> body) =>
      update('/masters/item-categories/$id', body);

  Future items({Map<String, dynamic>? filters}) =>
      _typed.getItems(filters: filters);
  Future item(int id) => show('/masters/items/$id');
  Future createItem(Map<String, dynamic> body) => store('/masters/items', body);
  Future updateItem(int id, Map<String, dynamic> body) =>
      update('/masters/items/$id', body);
  Future toggleItemStatus(int id, Map<String, dynamic> body) =>
      patch('/masters/items/$id/toggle-status', body);
}
